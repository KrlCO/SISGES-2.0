using System.Data;
using System.Data.Common;
using Dapper;
using Sisges.Domain.Common.Interfaces;
using Sisges.Domain.Entities;

namespace Sisges.Infrastructure.Data.Repositories;

public class AdminDocumentosRepository : IAdminDocumentosRepository
{
    private const int CodigoEmpresa = 1;
    private const int CodigoEstacion = 1;
    
    private readonly ISqlConnectionFactory _connectionFactory;

    public AdminDocumentosRepository(ISqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }
    
    public async Task<TurnoActual?> GetTurnoActualAsync()
    {
        using var connection = _connectionFactory.CreateConnection();
        var fila = await connection.QueryFirstOrDefaultAsync("QSP_TTTURN_01", commandType: CommandType.StoredProcedure);
        return fila is null ? null : new TurnoActual((DateTime)fila.FE_TURN, Convert.ToInt32(fila.FECHA_TURN));
    }

    public Task<IReadOnlyList<OpcionCatalogo>> GetTurnosAsync() => CatalogoAsync("QSP_TMTURN_01", "CO_TURN", "NO_TURN");

    public Task<IReadOnlyList<OpcionCatalogo>> GetTerminalesAsync() => CatalogoAsync("QSP_TMPNTO_VENT_03", "CO_VEN", "NO_PVEN");

    public Task<IReadOnlyList<OpcionCatalogo>> GetTrabajadoresAsync() => CatalogoAsync("QSP_TMTRAB_05", "CO_TRAB", "APE_NOM");
    public Task<IReadOnlyList<OpcionCatalogo>> GetTiposDocumentosAsync() => CatalogoAsync("QSP_TTTIPO_DOCU_011", "CO_TDOC", "DE_NOMB");
    public Task<IReadOnlyList<OpcionCatalogo>> GetFormasEmisionAsync() => CatalogoAsync("SP_TTFORM_EMIS_M01", "CO_EMIS", "DE_EMIS", new { ISDE_OPCI = "S" });
    
    public async Task<IReadOnlyList<DocumentoVentaIsla>> BuscarDocumentosAsync(FiltroDocumentosIsla filtro)
    {
        using var connection = (DbConnection)_connectionFactory.CreateConnection();

        var porDocumento = filtro.EsBusquedaPorDocumento;
        var parametros = new
        {
            INCO_EMPR = CodigoEmpresa,
            INCO_ESTA = CodigoEstacion,
            INCO_TURN = porDocumento ? 0 : filtro.Turno,
            IDFE_TURN = porDocumento ? DateTime.Today : filtro.Fecha.Date,
            ISTI_BUSQ = porDocumento ? "S" : filtro.TipoFecha == TipoFechaReporte.Turno ? "T" : "E",
            INCO_PVEN = porDocumento ? 0 : filtro.Terminal,
            INCO_TRAB = porDocumento ? 0 : filtro.Trabajador,
            INCO_TDOC = porDocumento ? filtro.TipoDocumento : 0,
            INCO_NSER = porDocumento ? filtro.Serie.Trim().ToUpperInvariant() : string.Empty,
            INNU_NDOC = porDocumento ? filtro.Numero : 0,
            ISCO_EMIS = porDocumento ? string.Empty : filtro.FormaEmision
        };

        using var reader = await connection.ExecuteReaderAsync("SP_TCDOCU_COMB_Q18", parametros, commandType: CommandType.StoredProcedure);

        if (TieneColumna(reader, "DE_ERRO"))
        {
            var mensaje = await reader.ReadAsync() ? reader["DE_ERRO"]?.ToString() : null;
            throw new InvalidOperationException($"Error en SP_TCDOCU_COMB_Q18: {mensaje}");
        }
        
        var parser = reader.GetRowParser<DocumentoVentaIsla>();
        var documentos = new List<DocumentoVentaIsla>();
        while (await reader.ReadAsync())
        {
            documentos.Add(parser(reader));
        }

        return documentos;
    }

    public async Task<string> GetEstadoTurnoAsync(DateTime fecha, int turno)
    {
        if (turno <= 0) return string.Empty;
        using var connection = (DbConnection)_connectionFactory.CreateConnection();
        var estado = await connection.ExecuteScalarAsync<string?>("QSP_TTTURN_02", new { FE_TURN = fecha.ToString("yyyyMMdd"), CO_TURN = turno }, commandType: CommandType.StoredProcedure);
        return estado?.Trim() ?? string.Empty;
    }

    public async Task<IReadOnlyList<LiquidacionTurno>> GetLiquidacionesAsync(DateTime fecha, int turno)
    {
        using var connection = _connectionFactory.CreateConnection();
        if (turno > 0)
        {
            var parametros = new
            {
                FE_TURN = fecha.ToString("yyyyMMdd"),
                CO_TURN = (byte)turno
            };
            var liquidaciones = await connection.QueryAsync<LiquidacionTurno>(
                "QSP_TCLIQI_05",
                parametros,
                commandType: CommandType.StoredProcedure);
            return liquidaciones.AsList();
        }
        else
        {
            const string sql = @"
                SELECT T1.NU_LIQI, T1.FE_TURN, T1.CO_TURN, T1.CO_TRAB, 
                       T2.NO_TRAB + ' ' + T2.DE_APEL AS NombTrab, 
                       CASE WHEN ST_LIQI = 'CER' THEN 'CERRADA' WHEN ST_LIQI = 'ACT' THEN 'ACTIVA' ELSE ST_LIQI END AS ESTADO
                FROM TCLIQI T1 (NOLOCK) 
                INNER JOIN TMTRAB T2 (NOLOCK) ON T1.CO_TRAB = T2.CO_TRAB
                WHERE CONVERT(VARCHAR(8), T1.FE_TURN, 112) = @FE_TURN
                ORDER BY T1.CO_TURN, T1.NU_LIQI";
            var liquidaciones = await connection.QueryAsync<LiquidacionTurno>(sql, new { FE_TURN = fecha.ToString("yyyyMMdd") });
            return liquidaciones.AsList();
        }
    }

    private async Task<IReadOnlyList<OpcionCatalogo>> CatalogoAsync(string sp, string columnaCodigo,
        string columnaDescripcion, object? parametros = null)
    {
        using var connection = _connectionFactory.CreateConnection();
        var filas = await connection.QueryAsync(sp, parametros, commandType: CommandType.StoredProcedure);
        return filas
            .Cast<IDictionary<string, object>>()
            .Select(f => new OpcionCatalogo(
                Convert.ToString(f[columnaCodigo])?.Trim() ?? string.Empty,
                Convert.ToString(f[columnaDescripcion])?.Trim() ?? string.Empty))
            .ToList();
    }

    private static bool TieneColumna(IDataRecord reader, string columna)
    {
        for (var i = 0; i < reader.FieldCount; i++)
        {
            if (string.Equals((reader.GetName(i)), columna, StringComparison.OrdinalIgnoreCase)) return true;
        }

        return false;
    }
}
