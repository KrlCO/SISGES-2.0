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

    private const string DepartamentoLima = "15";
    private const string ProvinciaLima = "01";

    private readonly ISqlConnectionFactory _connectionFactory;

    public TrabajadorRepository(ISqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }
    
    public async Task<IReadOnlyList<TrabajadorResumen>> BuscarAsync(string texto, bool incluirIncativo)
    {
        using var connection = _connectionFactory.CreateConnection();
        var filas = await connection.QueryAsync<TrabajadorResumen>(
        "dbo.SP_TMTRAB_Q02",
    new { ISDE_BUSQ = texto.Trim(), ISST_INAC = incluirIncativo ? "S" : "N" },
        commandType: CommandType.StoredProcedure);
        return filas.AsList();
    }
    

    public async Task<Trabajador> ObtenerAsync(int codigo)
    {
       using var connection = _connectionFactory.CreateConnection();
       var f = await connection.QueryFirstOrDefaultAsync("QSP_TMTRAB_10", new {CO_TRAB = codigo},
           commandType: CommandType.StoredProcedure);
       if(f is null) return null;
       
       DateTime naciemiento = f.FE_NACI is DateTime d && d.Year == 1900 ? d : DateTime.Today.AddDays(-18);
       string dni = ((string)f.NU_DNI).Trim();
       return new Trabajador
       {
           DniCargado = dni,
           NacimientoCargado = naciemiento,
           CO_TRAB = (int)f.CO_TRAB,
           DE_APEL = ((string)f.DE_APEL).Trim(),
           NO_TRAB = ((string)f.NO_TRAB).Trim(),
           NU_DNI = dni,
           FE_NACI = naciemiento,
           DE_DIRE = ((string)f.DE_DIRE).Trim(),
           NU_TEL1 = ((string)f.NU_TEL1).Trim(),
           NU_TEL2 = ((string)f.NU_TEL2).Trim(),
           CO_GEOG = ((string)f.CO_GEOG).Trim(),
           TIPO_TRAB = (string?)f.TIPO_TRAB == "EMPLEADO" ? Trabajador.TipoEmpleado : Trabajador.TipoGrifero,
           CO_USUA = ((string)f.CO_USUA).Trim().ToUpperInvariant(),
           CO_PERF = Convert.ToInt32(f.CO_PERF),
           ST_TRAB = ((string)f.ST_TRAB).Trim(),
           PermisoModificar = EsVerdadero(f.ST_MODI),
           PermisoAnular = EsVerdadero(f.ST_ANUL),
           PermisoDuplicado = EsVerdadero(f.ST_DOCU_DUPL),
           PermisoVentaCredito = EsVerdadero(f.ST_VENTA_CREDITO),
           PermisoAdministrador = EsVerdadero(f.ST_ADMINISTRADOR)
       };
    }

    public async Task<IReadOnlyList<OpcionCatalogo>> GetPerfilesAsync()
    {
        using var connection = _connectionFactory.CreateConnection();
        var filas = await connection.QueryAsync("QSP_TCPERF_01", commandType: CommandType.StoredProcedure);
        return filas
            .Select(f => new OpcionCatalogo((string)Convert.ToString(f.CO_PERF),((string?)f.NO_PERF)?.Trim() ?? string.Empty))
            .ToList();
    }

    public async Task<IReadOnlyList<Distrito>> GetDistritoAsync()
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

    public async Task<TrabajadorResumen?> BuscarUsuarioDuplicadoAsync(string usuario, int excluirCodigo)
    {
        using var connection = _connectionFactory.CreateConnection();
        return await BuscarDuplicadoAsync(connection, null, usuario, excluirCodigo);
    }

    public async Task<int> RegistrarAsync(Trabajador trabajador, string usuarioOperacion)
    {
        using var connection = (DbConnection)_connectionFactory.CreateConnection();
        await connection.OpenAsync();
        await using var transaccion = await connection.BeginTransactionAsync();
        await ValidarUsuarioLibreAsync(connection, transaccion, trabajador.CO_USUA, 0);
        var codigo = await connection.ExecuteScalarAsync<int>(
            "SELECT ISNULL(MAX(CO_TRAB), 0 + 1 FROM TMTRAB WITH (UPDLOCKm HOLDLOCK)", transaction: transaccion);
        trabajador.CO_TRAB = codigo;
        trabajador.ST_TRAB = Trabajador.Activo;
        await connection.ExecuteAsync("ISP_TMTRAB_02",
            Parametros(trabajador, ClaveSisges.Cifrar(trabajador.ClaveNueva!)), transaccion,
            commandType: CommandType.StoredProcedure);
        await connection.ExecuteAsync(
            "UPDATE TMTRAB SET CO_USUA_CREA = @USUARIO, FE_USUA_CREA = GETDATE() WHERE CO_TRAB = @CO_TRAB",
            new { USUARIO = usuarioOperacion, CO_TRAB = codigo }, transaccion);
        await transaccion.CommitAsync();
        return codigo;
    }

    public Task ActualizarAsync(Trabajador trabajador, string usuarioOperacion)
    {
        throw new NotImplementedException();
    }

    public Task DescativarAsync(int codigo, string usuarioOperacion)
    {
        throw new NotImplementedException();
    }

    private static async Task ValidarUsuarioLibreAsync(DbConnection connection, DbTransaction transaccion, string usuario,
        int excluirCodigo)
    {
        var duplicado = await BuscarDuplicadoAsync(connection, transaccion, usuario, excluirCodigo);
        if (duplicado is null) return;
        throw new InvalidOperationException(duplicado.ESTADO == "ACTIVO"
            ? $"El usuario{usuario} ya lo usa {duplicado.APE_NOM}(codigo {duplicado.CO_TRAB})."
            : $"El usuario {usuario} pertenece a {duplicado.APE_NOM}(codigo {duplicado.CO_TRAB}, inactivo. Reactivalo en lugar de crear otro.");

    }
    
    private static bool EsVerdadero(object? valor) => Convert.ToString(valor)?.Trim()== "1";

    private static Task<TrabajadorResumen?> BuscarDuplicadoAsync(IDbConnection connection, IDbTransaction? transaction,
        string usuario, int excluirCodigo) =>
        connection.QueryFirstOrDefaultAsync<TrabajadorResumen?>(
            """
            SELECT TOP 1 CO_TRAB, LTRIM(RTRIM(ISNULL(DE_APEL, '') + ' ' + ISNULL(NO_TRAB, ''))) AS APE_NOM,
            CASE WHEN ST_TRAB = 'N' THEN 'ACTIVO' ELSE 'NO ACTIVO' END AS ESTADO, CO_USUA
            FROM TMTRAB WITH(UPDLOCK, HOLDLOCK)
            WHERE UPPER(LTRIM(RTRIM(CO_USA))) = @USUARIO AND CO_TRAB <> @EXCLUIR
            ORDER BY CASE WHEN ST_TRAB = 'N' THEN 0 ELSE 1 END
            """,
            new { USUARIO = usuario.Trim().ToUpperInvariant(), EXCLUIR = excluirCodigo }, transaction);


    private static object Parametros(Trabajador t, string claveCifrada) => new
    {
        t.CO_TRAB,
        CO_EMPR = CodigoEmpresa,
        CO_ESTA = CodigoEstacion,
        NO_TRAB = t.NO_TRAB.Trim().ToUpperInvariant(),
        DE_APEL = t.DE_APEL.Trim().ToUpperInvariant(),
        DE_DIRE = Texto(t.DE_DIRE, mayusculas: true),
        NU_TEl1 = Texto(t.NU_TEL1),
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
    
    private static DbString Ansi(string valor) => new() {Value = valor, IsAnsi = true, Length = ClaveSisges.LargoMaximo};
        static string? Texto(string? valor, bool mayusculas = false)
    {
        if (string.IsNullOrWhiteSpace(valor)) return null;
        var limpio = valor.Trim();
        return mayusculas ? limpio.ToUpperInvariant() : limpio;
    }

}