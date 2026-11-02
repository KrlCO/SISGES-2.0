using System.Diagnostics;
using Dapper;
using Microsoft.Data.SqlClient;
using Sisges.Domain.Common.Interfaces;
using Sisges.Domain.Entities;

namespace Sisges.Infrastructure.Data.Repositories;

public class DashboardRepository : IDashboardRepository
{
    // Para el bloque de estaciones: no esperar los 15 s de la cadena de conexión si un grifo no responde
    private const int SegundosPruebaConexion = 4;

    // No son venta: 8 = Calibraciones (el combustible vuelve al tanque), 9 = Transferencias (TTTIPO_DOCU)
    private const string TiposNoVenta = "8, 9";

    private readonly ISqlConnectionFactory _connectionFactory;

    public DashboardRepository(ISqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    // No hay un SP del SISGES que reúna estos totales: se consultan directamente (solo lectura, NOLOCK)
    public async Task<ResumenDashboard> GetResumenAsync(CancellationToken cancellationToken = default)
    {
        using var connection = _connectionFactory.CreateConnection();
        using var multi = await connection.QueryMultipleAsync(new CommandDefinition(
            $"""
            SET NOCOUNT ON;
            DECLARE @FE DATE, @TU INT;
            SELECT TOP 1 @FE = FE_TURN, @TU = CO_TURN FROM TTTURN WITH (NOLOCK) WHERE ST_TURN = 'ACT'
            ORDER BY FE_TURN DESC, CO_TURN DESC;

            -- Fecha y hora de emisión del documento (FE_EMIS + FE_EMIS_HORA 'HH:mm').
            -- ISDATE en vez de TRY_CONVERT: algunas bases tienen nivel de compatibilidad de SQL Server 2008.
            WITH DOCS AS (
                SELECT C.FE_TURN, C.CO_TURN, C.IM_TOTA, C.NU_GALN, C.CO_PROD,
                       CASE WHEN ISDATE(CONVERT(VARCHAR(10), C.FE_EMIS, 120) + ' ' + C.FE_EMIS_HORA) = 1
                            THEN CONVERT(DATETIME, CONVERT(VARCHAR(10), C.FE_EMIS, 120) + ' ' + C.FE_EMIS_HORA) END AS EMISION
                FROM TCDOCU_COMB C WITH (NOLOCK)
                WHERE C.FE_TURN IN (@FE, DATEADD(DAY, -1, @FE)) AND C.ST_DVEN = 'N' AND C.CO_TDOC NOT IN ({TiposNoVenta})
            )
            SELECT
                CAST(@FE AS DATETIME) AS FE_TURN, @TU AS CO_TURN,
                (SELECT TOP 1 NO_TURN FROM TMTURN WITH (NOLOCK) WHERE CO_TURN = @TU) AS NO_TURN,
                COALESCE(
                    (SELECT TOP 1 FE_USUA_CREA FROM TTTURN WITH (NOLOCK) WHERE ST_TURN = 'CER' ORDER BY FE_TURN DESC, CO_TURN DESC),
                    (SELECT MIN(EMISION) FROM DOCS WHERE FE_TURN = @FE AND CO_TURN = @TU)) AS INICIO_TURNO,
                ISNULL((SELECT SUM(IM_TOTA) FROM DOCS WHERE FE_TURN = @FE), 0) AS VENTA_DIA,
                (SELECT COUNT(*) FROM DOCS WHERE FE_TURN = @FE) AS DOCUMENTOS_DIA,
                ISNULL((SELECT SUM(IM_TOTA) FROM TCDOCU_MARK WITH (NOLOCK) WHERE FE_TURN = @FE AND ST_DOC_MARK = 'N'), 0) AS VENTA_MARKET,
                ISNULL((SELECT SUM(IM_TOTA) FROM DOCS WHERE FE_TURN = DATEADD(DAY, -1, @FE) AND EMISION <= DATEADD(DAY, -1, GETDATE())), 0) AS VENTA_AYER_MISMA_HORA,
                ISNULL((SELECT SUM(IM_TOTA) FROM DOCS WHERE FE_TURN = @FE AND CO_TURN = @TU), 0) AS VENTA_TURNO,
                (SELECT COUNT(*) FROM DOCS WHERE FE_TURN = @FE AND CO_TURN = @TU) AS DOCUMENTOS_TURNO;

            SELECT ISNULL(P.DE_PROD_CORT, 'SIN PRODUCTO') AS Producto, SUM(C.NU_GALN) AS Volumen
            FROM TCDOCU_COMB C WITH (NOLOCK)
            LEFT JOIN TMPROD P WITH (NOLOCK) ON P.CO_PROD = C.CO_PROD
            WHERE C.FE_TURN = @FE AND C.ST_DVEN = 'N' AND C.CO_TDOC NOT IN ({TiposNoVenta})
            GROUP BY P.DE_PROD_CORT
            ORDER BY SUM(C.NU_GALN) DESC;
            """,
            cancellationToken: cancellationToken));

        var resumen = await multi.ReadFirstAsync<ResumenDashboard>();
        resumen.Productos = (await multi.ReadAsync<(string Producto, decimal Volumen)>())
            .Select(p => new VolumenProducto(p.Producto.Trim(), Math.Round(p.Volumen, 3)))
            .ToList();
        return resumen;
    }

    public async Task<IReadOnlyList<EstadoEstacion>> GetEstadoEstacionesAsync(CancellationToken cancellationToken = default)
    {
        var pruebas = _connectionFactory.ObtenerEstaciones().Select(e => ProbarAsync(e, cancellationToken));
        return await Task.WhenAll(pruebas);
    }

    private static async Task<EstadoEstacion> ProbarAsync(EstacionConfig estacion, CancellationToken cancellationToken)
    {
        var builder = new SqlConnectionStringBuilder(estacion.ConnectionString) { ConnectTimeout = SegundosPruebaConexion };
        var sw = Stopwatch.StartNew();
        try
        {
            await using var connection = new SqlConnection(builder.ConnectionString);
            await connection.OpenAsync(cancellationToken);
            await connection.ExecuteScalarAsync<int>(new CommandDefinition("SELECT 1",
                commandTimeout: SegundosPruebaConexion, cancellationToken: cancellationToken));
            return new EstadoEstacion(estacion.Id, estacion.Nombre, true, sw.ElapsedMilliseconds, null);
        }
        catch (Exception ex) when (!cancellationToken.IsCancellationRequested)
        {
            return new EstadoEstacion(estacion.Id, estacion.Nombre, false, sw.ElapsedMilliseconds, ex.Message);
        }
    }
}
