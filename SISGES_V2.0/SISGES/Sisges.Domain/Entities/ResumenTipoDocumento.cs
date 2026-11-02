namespace Sisges.Domain.Entities;

// Fila devuelta por dbo.QSP_TCDOCU_COMB_028_2 (reporte "Resumen por Fechas y Tipo Documento",
// formulario original frmRepFisTipDocumento / Crystal RptFiscTipDocu.rpt).
// Los importes ya vienen con signo: anulados = 0 y notas de crédito en negativo.
public class ResumenTipoDocumento
{
    public byte T { get; set; }                         // Código SUNAT del tipo de documento (1 = Factura, 3 = Boleta, ...)
    public string TIP { get; set; } = string.Empty;     // Nombre del tipo de documento
    public string SER { get; set; } = string.Empty;     // Serie
    public int NRODOC { get; set; }
    public string FDOC { get; set; } = string.Empty;    // Fecha de emisión dd/MM/yyyy
    public string? Ruc { get; set; }
    public string? Descri { get; set; }                 // Nombre o razón social
    public string ESTADO { get; set; } = string.Empty;  // N = Normal, A = Anulado
    public decimal ValorVenta { get; set; }
    public decimal IGV { get; set; }
    public decimal ImporteVenta { get; set; }
    public decimal CANTIDAD { get; set; }               // Galones (0 en Market)

    public bool EsAnulado => ESTADO == "A";
}

public enum OrigenVenta
{
    Combustible,
    Market,
    Todo
}

public enum TipoFechaReporte
{
    Emision,
    Turno       // Turno de 06:00 del día a 06:00 del día siguiente (columna FE_TURN)
}

public enum OrdenReporte
{
    Fecha,
    Serie
}

public record FiltroResumenTipoDocumento(
    OrigenVenta Origen,
    TipoFechaReporte TipoFecha,
    DateOnly Desde,
    DateOnly Hasta,
    OrdenReporte Orden);
