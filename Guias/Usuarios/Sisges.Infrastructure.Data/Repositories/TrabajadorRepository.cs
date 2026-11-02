using System.Data;
using System.Data.Common;
using Dapper;
using Sisges.Domain.Common;
using Sisges.Domain.Common.Interfaces;
using Sisges.Domain.Entities;

namespace Sisges.Infrastructure.Data.Repositories;

public class TrabajadorRepository : ITrabajadorRepository
{
    private const int CodigoEmpresa = 1;
    private const int CodigoEstacion = 1;

    // El original solo ofrece distritos de Lima Metropolitana (Get_Dist: departamento 15, provincia 01)
    private const string DepartamentoLima = "15";
    private const string ProvinciaLima = "01";

    private readonly ISqlConnectionFactory _connectionFactory;

    public TrabajadorRepository(ISqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    // QSP_TMTRAB_02 solo busca por apellido y no devuelve el usuario: se consulta directo (solo lectura)
    public async Task<IReadOnlyList<TrabajadorResumen>> BuscarAsync(string texto, bool incluirInactivos)
    {
        using var connection = _connectionFactory.CreateConnection();
        var filas = await connection.QueryAsync<TrabajadorResumen>(
            """
            SELECT T.CO_TRAB, LTRIM(RTRIM(ISNULL(T.DE_APEL, '') + ' ' + ISNULL(T.NO_TRAB, ''))) AS APE_NOM,
                   CASE WHEN T.ST_TRAB = 'N' THEN 'ACTIVO' ELSE 'NO ACTIVO' END AS ESTADO,
                   T.CO_USUA, T.TIPO_TRAB, P.NO_PERF
            FROM TMTRAB T WITH (NOLOCK)
            LEFT JOIN TCPERF P WITH (NOLOCK) ON P.CO_PERF = T.CO_PERF
            WHERE (@TEXTO = '' OR ISNULL(T.DE_APEL, '') + ' ' + ISNULL(T.NO_TRAB, '') LIKE '%' + @TEXTO + '%'
                   OR T.CO_USUA LIKE '%' + @TEXTO + '%' OR T.NU_DNI LIKE '%' + @TEXTO + '%')
              AND (@INACTIVOS = 1 OR T.ST_TRAB = 'N')
            ORDER BY CASE WHEN T.ST_TRAB = 'N' THEN 0 ELSE 1 END, APE_NOM
            """,
            new { TEXTO = texto.Trim(), INACTIVOS = incluirInactivos ? 1 : 0 });
        return filas.AsList();
    }

    // MstTrabajador.BusquedaPorCod (QSP_TMTRAB_10). La clave cifrada (CO_PASS) no se carga.
    public async Task<Trabajador?> ObtenerAsync(int codigo)
    {
        using var connection = _connectionFactory.CreateConnection();
        var f = await connection.QueryFirstOrDefaultAsync("dbo.QSP_TMTRAB_10", new { CO_TRAB = codigo },
            commandType: CommandType.StoredProcedure);
        if (f is null) return null;

        DateTime nacimiento = f.FE_NACI is DateTime d && d.Year > 1900 ? d : DateTime.Today.AddYears(-18);
        string dni = ((string)f.NU_DNI).Trim();
        return new Trabajador
        {
            DniCargado = dni,
            NacimientoCargado = nacimiento,
            CO_TRAB = (int)f.CO_TRAB,
            DE_APEL = ((string)f.DE_APEL).Trim(),
            NO_TRAB = ((string)f.NO_TRAB).Trim(),
            NU_DNI = dni,
            FE_NACI = nacimiento,
            DE_DIRE = ((string)f.DE_DIRE).Trim(),
            NU_TEL1 = ((string)f.NU_TEL1).Trim(),
            NU_TEL2 = ((string)f.NU_TEL2).Trim(),
            CO_GEOG = ((string)f.CO_GEOG).Trim(),
            // El SP devuelve el tipo como texto: GRIFERO / EMPLEADO
            TIPO_TRAB = (string?)f.TIPO_TRAB == "EMPLEADO" ? Trabajador.TipoEmpleado : Trabajador.TipoGrifero,
            CO_USUA = ((string)f.CO_USUA).Trim().ToUpperInvariant(),
            CO_PERF = Convert.ToInt32(f.CO_PERF),
            ST_TRAB = ((string)f.ST_TRAB).Trim(),
            PermisoModificar = EsVerdadero(f.ST_MODI),
            PermisoAnular = EsVerdadero(f.ST_ANUL),
            PermisoDuplicado = EsVerdadero(f.ST_DOCU_DUPL),
            PermisoVentaCredito = EsVerdadero(f.ST_VENT_CRED),
            PermisoAdministrador = EsVerdadero(f.ST_PERM_ADMI)
        };
    }

    // MstPerfiles.PerfilesAlls
    public async Task<IReadOnlyList<OpcionCatalogo>> GetPerfilesAsync()
    {
        using var connection = _connectionFactory.CreateConnection();
        var filas = await connection.QueryAsync("dbo.QSP_TCPERF_01", commandType: CommandType.StoredProcedure);
        return filas
            .Select(f => new OpcionCatalogo((string)Convert.ToString(f.CO_PERF), ((string?)f.NO_PERF)?.Trim() ?? string.Empty))
            .ToList();
    }

    // SP_TTUBIC_GEOG_G07 busca un distrito por código; para el combo se lista Lima Metropolitana completa
    public async Task<IReadOnlyList<Distrito>> GetDistritosAsync()
    {
        using var connection = _connectionFactory.CreateConnection();
        var filas = await connection.QueryAsync<Distrito>(
            """
            SELECT CO_GEOG, CO_DIST, NO_GEOG FROM TTUBIC_GEOG WITH (NOLOCK)
            WHERE CO_DPTO = @DPTO AND CO_PROV = @PROV AND CO_DIST <> '00'
            ORDER BY NO_GEOG
            """,
            new { DPTO = DepartamentoLima, PROV = ProvinciaLima });
        return filas.Select(d => d with { NO_GEOG = d.NO_GEOG.Trim() }).ToList();
    }

    // El original (SP_TMTRAB_Q01 'USU') solo mira los ACTIVOS, por eso hoy hay usuarios repetidos.
    // Aquí se buscan todos; primero el activo, si lo hay.
    public async Task<TrabajadorResumen?> BuscarUsuarioDuplicadoAsync(string usuario, int excluirCodigo)
    {
        using var connection = _connectionFactory.CreateConnection();
        return await BuscarDuplicadoAsync(connection, null, usuario, excluirCodigo);
    }

    // MstTrabajador.Agregar (ISP_TMTRAB_02)
    public async Task<int> RegistrarAsync(Trabajador trabajador, string usuarioOperacion)
    {
        using var connection = (DbConnection)_connectionFactory.CreateConnection();
        await connection.OpenAsync();
        await using var transaccion = await connection.BeginTransactionAsync();

        await ValidarUsuarioLibreAsync(connection, transaccion, trabajador.CO_USUA, 0);

        // Igual que dbo.QSP_TMTRAB_99 (MAX + 1), pero bloqueando hasta el COMMIT
        var codigo = await connection.ExecuteScalarAsync<int>(
            "SELECT ISNULL(MAX(CO_TRAB), 0) + 1 FROM TMTRAB WITH (UPDLOCK, HOLDLOCK)", transaction: transaccion);

        trabajador.CO_TRAB = codigo;
        trabajador.ST_TRAB = Trabajador.Activo;
        await connection.ExecuteAsync("dbo.ISP_TMTRAB_02",
            Parametros(trabajador, ClaveSisges.Cifrar(trabajador.ClaveNueva!)), transaccion,
            commandType: CommandType.StoredProcedure);

        // El SP no llena la auditoría
        await connection.ExecuteAsync(
            "UPDATE TMTRAB SET CO_USUA_CREA = @USUARIO, FE_USUA_CREA = GETDATE() WHERE CO_TRAB = @CO_TRAB",
            new { USUARIO = usuarioOperacion, CO_TRAB = codigo }, transaccion);

        await transaccion.CommitAsync();
        return codigo;
    }

    // MstTrabajador.Actualizar (USP_TMTRAB_03). Sin clave nueva se conserva la actual.
    public async Task ActualizarAsync(Trabajador trabajador, string usuarioOperacion)
    {
        using var connection = (DbConnection)_connectionFactory.CreateConnection();
        await connection.OpenAsync();
        await using var transaccion = await connection.BeginTransactionAsync();

        if (trabajador.EstaActivo)
            await ValidarUsuarioLibreAsync(connection, transaccion, trabajador.CO_USUA, trabajador.CO_TRAB);

        string clave;
        if (string.IsNullOrWhiteSpace(trabajador.ClaveNueva))
        {
            // CO_PASS se lee como varchar (no nvarchar) para no alterar los caracteres del cifrado
            clave = await connection.ExecuteScalarAsync<string?>(
                "SELECT CO_PASS FROM TMTRAB WITH (UPDLOCK) WHERE CO_TRAB = @CO_TRAB",
                new { trabajador.CO_TRAB }, transaccion) ?? string.Empty;
        }
        else
        {
            clave = ClaveSisges.Cifrar(trabajador.ClaveNueva);
        }

        if (!trabajador.EstaActivo)
        {
            // Inactivo = sin permisos especiales, igual que DSP_TMTRAB_02
            trabajador.PermisoModificar = trabajador.PermisoAnular = trabajador.PermisoDuplicado =
                trabajador.PermisoVentaCredito = trabajador.PermisoAdministrador = false;
        }

        await connection.ExecuteAsync("dbo.USP_TMTRAB_03", Parametros(trabajador, clave), transaccion,
            commandType: CommandType.StoredProcedure);
        await connection.ExecuteAsync(
            "UPDATE TMTRAB SET CO_USUA_MODI = @USUARIO, FE_USUA_MODI = GETDATE() WHERE CO_TRAB = @CO_TRAB",
            new { USUARIO = usuarioOperacion, trabajador.CO_TRAB }, transaccion);

        await transaccion.CommitAsync();
    }

    // MstTrabajador.Eliminar (DSP_TMTRAB_02 ya es baja lógica) + clave aleatoria
    public async Task DesactivarAsync(int codigo, string usuarioOperacion)
    {
        using var connection = (DbConnection)_connectionFactory.CreateConnection();
        await connection.OpenAsync();
        await using var transaccion = await connection.BeginTransactionAsync();

        await connection.ExecuteAsync("dbo.DSP_TMTRAB_02", new { CO_TRAB = codigo }, transaccion,
            commandType: CommandType.StoredProcedure);
        await connection.ExecuteAsync(
            "UPDATE TMTRAB SET CO_PASS = @CO_PASS, CO_USUA_MODI = @USUARIO, FE_USUA_MODI = GETDATE() WHERE CO_TRAB = @CO_TRAB",
            new { CO_PASS = Ansi(ClaveSisges.Cifrar(ClaveSisges.Aleatoria())), USUARIO = usuarioOperacion, CO_TRAB = codigo },
            transaccion);

        await transaccion.CommitAsync();
    }

    private static async Task ValidarUsuarioLibreAsync(DbConnection connection, DbTransaction transaccion, string usuario, int excluirCodigo)
    {
        var duplicado = await BuscarDuplicadoAsync(connection, transaccion, usuario, excluirCodigo);
        if (duplicado is null) return;
        throw new InvalidOperationException(duplicado.ESTADO == "ACTIVO"
            ? $"El usuario {usuario} ya lo usa {duplicado.APE_NOM} (código {duplicado.CO_TRAB})."
            : $"El usuario {usuario} pertenece a {duplicado.APE_NOM} (código {duplicado.CO_TRAB}, inactivo). Reactívalo en lugar de crear otro.");
    }

    private static Task<TrabajadorResumen?> BuscarDuplicadoAsync(IDbConnection connection, IDbTransaction? transaccion, string usuario, int excluirCodigo) =>
        connection.QueryFirstOrDefaultAsync<TrabajadorResumen?>(
            """
            SELECT TOP 1 CO_TRAB, LTRIM(RTRIM(ISNULL(DE_APEL, '') + ' ' + ISNULL(NO_TRAB, ''))) AS APE_NOM,
                   CASE WHEN ST_TRAB = 'N' THEN 'ACTIVO' ELSE 'NO ACTIVO' END AS ESTADO, CO_USUA
            FROM TMTRAB WITH (UPDLOCK, HOLDLOCK)
            WHERE UPPER(LTRIM(RTRIM(CO_USUA))) = @USUARIO AND CO_TRAB <> @EXCLUIR
            ORDER BY CASE WHEN ST_TRAB = 'N' THEN 0 ELSE 1 END
            """,
            new { USUARIO = usuario.Trim().ToUpperInvariant(), EXCLUIR = excluirCodigo }, transaccion);

    // Parámetros comunes de ISP_TMTRAB_02 y USP_TMTRAB_03 (misma firma)
    private static object Parametros(Trabajador t, string claveCifrada) => new
    {
        t.CO_TRAB,
        CO_EMPR = CodigoEmpresa,
        CO_ESTA = CodigoEstacion,
        NO_TRAB = t.NO_TRAB.Trim().ToUpperInvariant(),
        DE_APEL = t.DE_APEL.Trim().ToUpperInvariant(),
        DE_DIRE = Texto(t.DE_DIRE, mayusculas: true),
        NU_TEL1 = Texto(t.NU_TEL1),
        NU_TEL2 = Texto(t.NU_TEL2),
        FE_NACI = t.FE_NACI.Date,
        NU_DNI = t.NU_DNI.Trim(),
        t.TIPO_TRAB,
        t.CO_GEOG,
        CO_USUA = t.CO_USUA.Trim().ToUpperInvariant(),
        CO_PASS = Ansi(claveCifrada),
        t.CO_PERF,
        t.ST_TRAB,
        ST_MODI = t.PermisoModificar ? 1 : 0,
        ST_ANUL = t.PermisoAnular ? 1 : 0,
        ST_DOCU_DUPL = t.PermisoDuplicado ? 1 : 0,
        ST_VENT_CRED = t.PermisoVentaCredito ? 1 : 0,
        ST_PERM_ADMI = t.PermisoAdministrador ? 1 : 0
    };

    // La clave cifrada tiene caracteres > 127: se envía como varchar (página 1252), igual que el ADO del VB6
    private static DbString Ansi(string valor) => new() { Value = valor, IsAnsi = true, Length = ClaveSisges.LargoMaximo };

    private static bool EsVerdadero(object? valor) => Convert.ToString(valor)?.Trim() == "1";

    private static string? Texto(string? valor, bool mayusculas = false)
    {
        if (string.IsNullOrWhiteSpace(valor)) return null;
        var limpio = valor.Trim();
        return mayusculas ? limpio.ToUpperInvariant() : limpio;
    }
}
