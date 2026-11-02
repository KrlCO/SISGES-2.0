using Sisges.Domain.Entities;

namespace Sisges.Domain.Common.Interfaces;

// Reporte Depositos / Tarjetas (frmRepEntre_Tarje.frm, clase LibMant.TrnsEntregas)
public interface IReporteCajaRepository
{
    // Opciones "Todo", "Tarjetas" y "Depositos": una fecha de turno y un turno (0 = todos)
    Task<IReadOnlyList<MovimientoCaja>> GetMovimientosAsync(TipoReporteDepositos tipo, DateOnly fechaTurno, int turno);

    // Opción "Resumen Tarjetas" (rango de fechas)
    Task<IReadOnlyList<TarjetaResumen>> GetResumenTarjetasAsync(DateOnly desde, DateOnly hasta);
    Task<IReadOnlyList<TarjetaDetalle>> GetDetalleTarjetasAsync(DateOnly desde, DateOnly hasta);
}
