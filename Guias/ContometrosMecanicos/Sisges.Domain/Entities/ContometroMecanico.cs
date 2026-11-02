namespace Sisges.Domain.Entities;

// Lectura de una manguera (TDCONT). Mismas columnas que devuelven QSP_TMCONT_01 / _03 / _06.
// Es editable: la pantalla cambia IM_LECF, IM_CALI, CO_TRAB y, con "cambio de precio", IM_PRE1.
public class LecturaContometro
{
    public int CO_LADO { get; set; }
    public int CO_MANG { get; set; }
    public string NO_PROD { get; set; } = string.Empty;     // QSP_TMCONT_06 lo llama DE_PROD_CORT
    public int CO_PROD { get; set; }
    public decimal IM_PRE1 { get; set; }
    public decimal IM_LECI { get; set; }
    public decimal IM_LECF { get; set; }
    public decimal IM_CALI { get; set; }
    public decimal IM_GALO { get; set; }
    public decimal IM_VENT { get; set; }
    public int CO_TRAB { get; set; }
    public string? NombTra { get; set; }
    public int CO_PVEN { get; set; }
    public int CO_ISLA { get; set; }
    public int CO_SURT { get; set; }

    // Galones = final - inicial - calibración; importe = galones x precio (SSDBGConto_KeyPress del original)
    public decimal GalonesCalculados => Math.Round(IM_LECF - IM_LECI - IM_CALI, 3);
    public decimal ImporteCalculado => Math.Round(GalonesCalculados * IM_PRE1, 2);
}

// Cabecera (TCCONT) de los contómetros de un turno
public record ContometroTurno(int CO_CONT, DateOnly FechaTurno, int Turno);

// Galones e importe por producto (cuadro "Resumen" del original)
public record ResumenContometro(string Producto, decimal Galones, decimal Importe);

public static class TurnosContometro
{
    // IdentificarTurno del original: turno siguiente al último registrado (después del último va el primero del día siguiente)
    public static (DateOnly Fecha, int Turno) Siguiente(DateOnly fecha, int turno, int turnoMinimo, int turnoMaximo) =>
        turno >= turnoMaximo ? (fecha.AddDays(1), turnoMinimo) : (fecha, turno + 1);
}
