using System.Data;
using System.Data.Common;
using Dapper;
using Sisges.Domain.Common.Interfaces;
using Sisges.Domain.Entities;

namespace Sisges.Infrastructure.Data.Repositories;

public class ClienteRepository : IClienteRepository
{
    private const int CodigoEmpresa = 1;
    private const int CodigoEstacion = 1;

    private const byte ParametroGrupoPorDefecto = 18;
    private const byte ParametroLimiteCreditoPorDefecto = 39;

    private const int MaximoResultadosBusqueda = 200;

    private readonly ISqlConnectionFactory _connectionFactory;

    public ClienteRepository(ISqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<IReadOnlyList<TipoCliente>> GetTiposClienteAsync()
    {
        using var connection = _connectionFactory.CreateConnection();
        var tipos = await connection.QueryAsync<TipoCliente>("dbo.QSP_TTTIPO_CLIE_01", commandType: CommandType.StoredProcedure);
        return tipos.AsList();
    }

    public async Task<IReadOnlyList<TipoEmision>> GetTiposEmisionAsync()
    {
       using var connection = _connectionFactory.CreateConnection();
       var tiposEmision = await connection.QueryAsync<TipoEmision>("dbo.QSP_TTTIPO_EMIS_01", commandType: CommandType.StoredProcedure);
       return tiposEmision.AsList();
    }

    public async Task<decimal> GetLimiteCreditoPorDefectoAsync()
    {
       using var connection = _connectionFactory.CreateConnection();
       var limitCred = await connection.QueryFirstOrDefaultAsync("dbo.SQP_TTPARA_FILT_01", new { COPARA_FILT = ParametroLimiteCreditoPorDefecto }, commandType: CommandType.StoredProcedure);
       return limitCred is null ? 0m : Math.Round((decimal)limitCred.IMPARA_FILT, 2);
    }

    public async Task<IReadOnlyList<ClienteResumen>> BuscarAsync(string? texto = null)
    {
        texto = texto?.Trim() ?? string.Empty;
        using var connection = _connectionFactory.CreateConnection();

        IEnumerable<ClienteResumen> clientes;
        if (string.IsNullOrEmpty(texto))
        {
            clientes = await connection.QueryAsync<ClienteResumen>("QSP_TCCLIE_03",
                new{NU_RSOC = "%", CO_EMPR = CodigoEmpresa, CO_ESTA = CodigoEstacion},
                    commandType: CommandType.StoredProcedure);
        }
        else if(texto.All(char.IsAsciiDigit))
        {
            clientes = await connection.QueryAsync<ClienteResumen>("QSP_TCCLIE_02",
                new { NU_RUC = texto, CO_EMPR = CodigoEmpresa, CO_ESTA = CodigoEstacion },
                commandType: CommandType.StoredProcedure);
        }
        else
        {
            clientes = await connection.QueryAsync<ClienteResumen>("QSP_TCCLIE_03",
                new{NU_RSOC = "%" + texto.ToUpperInvariant(), CO_EMPR = CodigoEmpresa, CO_ESTA = CodigoEstacion },
                commandType: CommandType.StoredProcedure);
        }
        return clientes.OrderBy((c => c.NU_RSOC)).Take(MaximoResultadosBusqueda).ToList();
    }

    public async Task<Cliente?> ObtenerAsync(int codigo)
    {
        using var connection = _connectionFactory.CreateConnection();
        // QSP_TCCLIE_01 solo devuelve clientes registrados y activos (RE_CLIE = 'R', ST_CLIE = 'N')
        var fila = await connection.QueryFirstOrDefaultAsync<ClienteFila>("dbo.QSP_TCCLIE_01",
            new { CO_CLIE = codigo, CO_EMPR = CodigoEmpresa, CO_ESTA = CodigoEstacion },
            commandType: CommandType.StoredProcedure);
        if (fila is null) return null;

        fila.ControlCredito = fila.CR_CRET == "S";
        fila.TipoPersona = string.IsNullOrWhiteSpace(fila.NU_RUC) ? TipoPersona.Natural : TipoPersona.Juridica;
        if (fila.FE_INGR == default) fila.FE_INGR = DateTime.Today;
        // IM_LIMI_CRED es NUMERIC(20,10): sin redondear se ve 0.0000000000 en pantalla
        fila.IM_LIMI_CRED = Math.Round(fila.IM_LIMI_CRED, 2);
        fila.IM_SOBR_GIRO = Math.Round(fila.IM_SOBR_GIRO, 2);
        fila.IM_MONT_MINI = Math.Round(fila.IM_MONT_MINI, 2);
        return fila;
    }

    public async Task<bool> EsDocumentoValidoAsync(string ruc)
    {
        using var connection = _connectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<bool>("SELECT dbo.FU_TI_VALI_CLIE_Q01(@ruc)", new { ruc });

    }

    public async Task<string> NormalizarRazonSocialAsync(string razonSocial)
    {
       using var connection = _connectionFactory.CreateConnection();
       var normaliza = await connection.ExecuteScalarAsync<string>("SELECT dbo.FU_NO_RAZO_SOCI_Q01(@razonSocial)",
           new { razonSocial = razonSocial.Trim().ToUpperInvariant() });
       return normaliza?.Trim() ?? string.Empty;

    }

    public async Task<IReadOnlyList<ClienteDuplicado>> BuscarDuplicadosAsync(Cliente cliente)
    {
        // Reemplaza a SP_TCDOCU_COMB_Q09, que solo rechaza cuando ya hay DOS clientes con la misma razón social
        // (con uno solo deja grabar otro) y además filtra por tipo de cliente. Aquí basta que coincida el RUC,
        // el DNI o la razón social con cualquier cliente registrado, activo o anulado, distinto al que se edita.
        var esJuridica = cliente.TipoPersona == TipoPersona.Juridica;
        var razonSocial = cliente.RazonSocialParaGrabar();

        using var connection = _connectionFactory.CreateConnection();
        var duplicados = await connection.QueryAsync<ClienteDuplicado>(
            """
            SELECT CO_CLIE, NU_RUC, NU_DOCU_IDEN, NU_RSOC, ST_CLIE
            FROM TCCLIE WITH (NOLOCK)
            WHERE CO_EMPR = @CO_EMPR AND CO_ESTA = @CO_ESTA AND RE_CLIE = 'R'
              AND CO_CLIE <> @CO_CLIE
              AND (   (@NU_RUC IS NOT NULL AND LTRIM(RTRIM(NU_RUC)) = @NU_RUC)
                   OR (@NU_DOCU_IDEN IS NOT NULL AND LTRIM(RTRIM(NU_DOCU_IDEN)) = @NU_DOCU_IDEN)
                   OR (@NU_RSOC IS NOT NULL AND UPPER(LTRIM(RTRIM(NU_RSOC))) = @NU_RSOC))
            ORDER BY CO_CLIE
            """,
            new
            {
                CO_EMPR = CodigoEmpresa,
                CO_ESTA = CodigoEstacion,
                cliente.CO_CLIE,
                NU_RUC = esJuridica ? Texto(cliente.NU_RUC) : null,
                NU_DOCU_IDEN = esJuridica ? null : Texto(cliente.NU_DOCU_IDEN),
                NU_RSOC = Texto(razonSocial, mayusculas: true)
            });
        return duplicados.AsList();
    }

    public async Task<int> RegistrarAsync(Cliente cliente, string usuario)
    {
        using var connection = (DbConnection)_connectionFactory.CreateConnection();
        await connection.OpenAsync();
        await using var transaccion = await connection.BeginTransactionAsync();

        var codigo = await connection.ExecuteScalarAsync<int>(
            "SELECT ISNULL(MAX(CO_CLIE), 0) + 1 FROM TCCLIE WITH(UPDLOCK, HOLDLOCK)",
            transaction: transaccion);

        // El alta guarda la misma observación en DE_OBSI y DE_OBSI_CONT (igual que frmMaeCliente)
        await connection.ExecuteAsync(
            "dbo.SP_TCCLIE_I01",
            Parametros(cliente, codigo, usuario, observacion: Texto(cliente.DE_OBSI_CONT), domicilioContacto: null),
            transaccion,
            commandType: CommandType.StoredProcedure);
        var parametroGrupo = await connection.QueryFirstOrDefaultAsync("dbo.SQP_TTPARA_FILT_01",
            new { COPARA_FILT = ParametroGrupoPorDefecto },
            transaccion,
            commandType: CommandType.StoredProcedure);
        string nombreGrupo = ((string?)parametroGrupo?.DSPARA_FILT)?.Trim() is { Length: > 0 } g
            ? g
            : "Grupo por defecto";
        await connection.ExecuteAsync(
            "dbo.SP_TTGRUP_VEMK_I01",
            new
            {
                INCO_CLIE = codigo,
                INCO_GROU = 1,
                ISNO_GRUP = nombreGrupo,
                ISST_GRUP = "N",
                ISCO_USUA = usuario
            },
            transaccion,
            commandType: CommandType.StoredProcedure);
        await transaccion.CommitAsync();
        return codigo;
    }

    public async Task ActualizarAsync(Cliente cliente, string usuario)
    {
        using var connection = _connectionFactory.CreateConnection();

        // SP_TCCLIE_U01 sobrescribe todas las columnas: DE_OBSI y DE_DOMI_CONT, que no están en pantalla,
        // se devuelven con el valor que se leyó. Graba CO_USUA_MODI y FE_USUA_MODI.
        await connection.ExecuteAsync(
            "dbo.SP_TCCLIE_U01",
            Parametros(cliente, cliente.CO_CLIE, usuario, observacion: Texto(cliente.DE_OBSI), domicilioContacto: Texto(cliente.DE_DOMI_CONT)),
            commandType: CommandType.StoredProcedure);
    }

    public async Task InactivarAsync(int codigo, string usuario)
    {
       using var connection = _connectionFactory.CreateConnection();
       await connection.ExecuteAsync(
           "dbo.SP_TCCLIE_D01",
           new {INCO_CLIE = codigo, ISCO_USUA = usuario},
           commandType: CommandType.StoredProcedure);
    }

    public async Task ReactivarAsync(int codigo, string usuario)
    {
       using var connection = _connectionFactory.CreateConnection();
       await connection.ExecuteAsync(
           """
            UPDATE TCCLIE
            SET ST_CLIE = 'N', CO_USUA_MODI = @usuario, FE_USUA_MODI = GETDATE()
            WHERE CO_CLIE = @codigo AND CO_EMPR = @CO_EMPR AND CO_ESTA = @CO_ESTA
           """,
           new { codigo, usuario, CO_EMPR = CodigoEmpresa, CO_ESTA = CodigoEstacion });
    }

    // Parámetros comunes de SP_TCCLIE_I01 y SP_TCCLIE_U01 (tienen la misma firma)
    private static object Parametros(Cliente cliente, int codigo, string usuario, string? observacion, string? domicilioContacto)
    {
        var esJuridica = cliente.TipoPersona == TipoPersona.Juridica;
        return new
        {
            INCO_CLIE = codigo,
            ISNO_CLIE = Texto(esJuridica ? null : cliente.NO_CLIE, mayusculas: true),
            ISDE_APEL_PATE = Texto(esJuridica ? null : cliente.DE_APEL_PATE, mayusculas: true),
            INCO_EMPR = CodigoEmpresa,
            ISNU_RSOC = cliente.RazonSocialParaGrabar(),
            INCO_ESTA = CodigoEstacion,
            ISNU_DOCU_IDEN = Texto(esJuridica ? null : cliente.NU_DOCU_IDEN),
            ISNU_RUC = Texto(esJuridica ? cliente.NU_RUC : null),
            ISNU_TEL1 = Texto(cliente.NU_TEL1),
            ISNU_TEL2 = Texto(cliente.NU_TEL2),
            ISNU_FAX = Texto(cliente.NU_FAX),
            ISDE_GIRO_EMPR = Texto(cliente.DE_GIRO_EMPR, mayusculas: true),
            ISNO_CONT_CLIE = Texto(cliente.NO_CONT_CLIE, mayusculas: true),
            ISDE_DOMI = Texto(cliente.DE_DOMI, mayusculas: true),
            ISDE_REFE = Texto(cliente.DE_REFE, mayusculas: true),
            INIM_LIMI_CRED = cliente.IM_LIMI_CRED,
            INIM_SOBR_GIRO = cliente.IM_SOBR_GIRO,
            ISDE_MAIL = Texto(cliente.DE_MAIL),
            INCO_TCLI = cliente.CO_TCLI,
            ISCO_GEOG = Texto(cliente.CO_GEOG),
            ISNO_REPR_LEGA = Texto(cliente.NO_REPR_LEGA, mayusculas: true),
            ISDE_APEL_MATE = Texto(esJuridica ? null : cliente.DE_APEL_MATE, mayusculas: true),
            IDFE_INGR = cliente.FE_INGR.Date,
            ISDE_APEL_MATE_CONT = Texto(cliente.DE_APEL_MATE_CONT, mayusculas: true),
            INCO_TEMI = cliente.CO_TEMI,
            ISDE_APEL_PATE_CONT = Texto(cliente.DE_APEL_PATE_CONT, mayusculas: true),
            ISDE_DOMI_CONT = domicilioContacto,
            ISDE_OBSI_CONT = Texto(cliente.DE_OBSI_CONT),
            ISDE_OBSI = observacion,
            ISDE_CORR_CONT = Texto(cliente.DE_CORR_CONT),
            ISDE_CARG_CONT = Texto(cliente.DE_CARG_CONT, mayusculas: true),
            ISNU_TELE_CONT = Texto(cliente.NU_TELE_CONT),
            ISST_CLIE = "N",                                // N = activo
            ISCR_CRET = cliente.ControlCredito ? "S" : "N",
            INIM_MONT_MINI = cliente.IM_MONT_MINI,
            ISCO_USUA = usuario
        };
    }

    private static string? Texto(string? valor, bool mayusculas = false)
    {
        if (string.IsNullOrWhiteSpace(valor)) return null;
        var limpio = valor.Trim();
        return mayusculas ? limpio.ToUpperInvariant() : limpio;

    }

    // QSP_TCCLIE_01 devuelve CR_CRET ('S'/'N'), que en la entidad es el booleano ControlCredito
    private sealed class ClienteFila : Cliente
    {
        public string? CR_CRET { get; set; }
    }
}
