namespace Sisges.Domain.Entities;

// Indicadores del Dashboard para el grifo activo. "Día" = fecha del turno en curso (TTTURN ST_TURN = 'ACT'),
// que va de 06:00 a 06:00, no la fecha del reloj.
public class ResumenDashboard
{
    public DateTime? FE_TURN { get; set; }
    public int? CO_TURN { get; set; }
    public string? NO_TURN { get; set; }
    public DateTime? INICIO_TURNO { get; set; }      // cierre del turno anterior o, si no se registró, primer documento

    public decimal VENTA_DIA { get; set; }
    public int DOCUMENTOS_DIA { get; set; }
    public decimal VENTA_MARKET { get; set; }
    public decimal VENTA_AYER_MISMA_HORA { get; set; }

    public decimal VENTA_TURNO { get; set; }
    public int DOCUMENTOS_TURNO { get; set; }

    public IReadOnlyList<VolumenProducto> Productos { get; set; } = Array.Empty<VolumenProducto>();

    // Variación frente al día anterior hasta la misma hora (null si ayer no hubo ventas a esa hora)
    public decimal? VariacionPorcentaje => VENTA_AYER_MISMA_HORA > 0
        ? Math.Round((VENTA_DIA + VENTA_MARKET - VENTA_AYER_MISMA_HORA) / VENTA_AYER_MISMA_HORA * 100, 1)
        : null;
}

// Volumen despachado por producto en el día. El GNV se mide en m³; el resto en galones.
public record VolumenProducto(string Producto, decimal Volumen)
{
    public bool EsGnv => Producto.Equals("GNV", StringComparison.OrdinalIgnoreCase);
}

// Estado de conexión de cada estación de appsettings.json
public record EstadoEstacion(string Id, string Nombre, bool EnLinea, long LatenciaMs, string? Error);
