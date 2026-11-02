namespace Sisges.Domain.Entities;

// Opciones del formulario frmRepEntre_Tarje ("Reporte Depositos / Tarjetas")
public enum TipoReporteDepositos
{
    Todo,              // QSP_TTFPAG_DOCU_COMB_008
    Tarjetas,          // QSP_TTFPAG_DOCU_COMB_009
    Depositos,         // QSP_TTFPAG_DOCU_COMB_004
    ResumenTarjetas    // QSP_TTFPAG_DOCU_COMB_010 (rango de fechas)
}

// Fila de QSP_TTFPAG_DOCU_COMB_008 / _009 / _004. IDREP indica la sección:
//   1 = voucher de tarjeta por grifero, 2 = total por tarjeta y turno, 3 = entrega de efectivo (TTENTR)
public class MovimientoCaja
{
    public const byte SeccionTarjetaGrifero = 1;
    public const byte SeccionTarjetaTurno = 2;
    public const byte SeccionDeposito = 3;

    public byte IDREP { get; set; }
    public int? CO_TRAB { get; set; }
    public string? NO_TRAB { get; set; }
    public decimal? IM_TOTA { get; set; }
    public int? CO_TARJ { get; set; }
    public string? NO_TRAJ { get; set; }      // así se llama la columna en los SP (nombre de la tarjeta)
    public string? NU_TARJ { get; set; }      // número de voucher / operación
    public decimal? IM_SOLE { get; set; }
    public decimal? IM_DOLA { get; set; }
    public int? CO_TURN { get; set; }
    public string? FE_TURN { get; set; }      // los SP la devuelven como texto dd/MM/yyyy
}

// QSP_TTFPAG_DOCU_COMB_010 con ST_TIPO = 'R'
public class TarjetaResumen
{
    public int CO_TARJ { get; set; }
    public string NO_TARJ { get; set; } = string.Empty;
    public decimal TOTAL { get; set; }
}

// QSP_TTFPAG_DOCU_COMB_010 con ST_TIPO = 'D'
public class TarjetaDetalle
{
    public string? FECHA { get; set; }        // dd/MM/yyyy
    public string? NOMBRE { get; set; }       // grifero
    public int CO_TURN { get; set; }
    public decimal IM_TOTA { get; set; }
    public string? NO_TARJ { get; set; }
    public string? NU_TARJ { get; set; }
    public int CO_TARJ { get; set; }
    public string? NRODOC { get; set; }
    public string? TDOC { get; set; }
}

// Turno = 0 significa "Todos los turnos" (igual que el original)
public record FiltroDepositosTarjetas(TipoReporteDepositos Tipo, DateOnly Fecha, int Turno, DateOnly Hasta, bool Detallado);
