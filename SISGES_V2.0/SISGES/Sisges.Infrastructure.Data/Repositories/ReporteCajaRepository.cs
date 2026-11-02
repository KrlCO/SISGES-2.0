using System.Data;
using Dapper;
using Sisges.Domain.Common.Interfaces;
using Sisges.Domain.Entities;

namespace Sisges.Infrastructure.Data.Repositories;

public class ReporteCajaRepository : IReporteCajaRepository
{
    private const int TimeoutSegundos = 120;

    private readonly ISqlConnectionFactory _connectionFactory;

    public ReporteCajaRepository(ISqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<IReadOnlyList<MovimientoCaja>> GetMovimientosAsync(TipoReporteDepositos tipo, DateOnly fechaTurno, int turno)
    {
        // TrnsEntregas.Rpt_TarjeEntreEfec / Rpt_Tarjetas / Rpt_Depositos
        var sp = tipo switch
        {
            TipoReporteDepositos.Todo => "dbo.QSP_TTFPAG_DOCU_COMB_008",
            TipoReporteDepositos.Tarjetas => "dbo.QSP_TTFPAG_DOCU_COMB_009",
            TipoReporteDepositos.Depositos => "dbo.QSP_TTFPAG_DOCU_COMB_004",
            _ => throw new ArgumentOutOfRangeException(nameof(tipo), "El resumen de tarjetas usa GetResumenTarjetasAsync")
        };

        using var connection = _connectionFactory.CreateConnection();
        var filas = await connection.QueryAsync<MovimientoCaja>(sp,
            new { CO_TURN = turno, FE_TURN = fechaTurno.ToString("yyyyMMdd") },
            commandType: CommandType.StoredProcedure, commandTimeout: TimeoutSegundos);
        return filas.AsList();
    }

    // TrnsEntregas.Rpt_TarjetasAll(..., "R")
    public async Task<IReadOnlyList<TarjetaResumen>> GetResumenTarjetasAsync(DateOnly desde, DateOnly hasta)
    {
        using var connection = _connectionFactory.CreateConnection();
        var filas = await connection.QueryAsync<TarjetaResumen>("dbo.QSP_TTFPAG_DOCU_COMB_010",
            new { FE_DESDE = desde.ToDateTime(TimeOnly.MinValue), FE_HASTA = hasta.ToDateTime(TimeOnly.MinValue), ST_TIPO = "R" },
            commandType: CommandType.StoredProcedure, commandTimeout: TimeoutSegundos);
        return filas.OrderBy(f => f.CO_TARJ).ToList();
    }

    // TrnsEntregas.Rpt_TarjetasAll(..., "D")
    public async Task<IReadOnlyList<TarjetaDetalle>> GetDetalleTarjetasAsync(DateOnly desde, DateOnly hasta)
    {
        using var connection = _connectionFactory.CreateConnection();
        var filas = await connection.QueryAsync<TarjetaDetalle>("dbo.QSP_TTFPAG_DOCU_COMB_010",
            new { FE_DESDE = desde.ToDateTime(TimeOnly.MinValue), FE_HASTA = hasta.ToDateTime(TimeOnly.MinValue), ST_TIPO = "D" },
            commandType: CommandType.StoredProcedure, commandTimeout: TimeoutSegundos);
        return filas.AsList();
    }
}
