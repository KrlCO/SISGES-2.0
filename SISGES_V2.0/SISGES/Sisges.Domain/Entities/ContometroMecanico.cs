namespace Sisges.Domain.Entities;

public class ContometroMecanico
{
    public int CO_LADO { get; set; }
    public int CO_MANG { get; set; }
    public string NO_PROD { get; set; } = string.Empty;
    public int CO_PROD{ get; set; }
    public decimal IM_PRE1 { get; set; }
    public decimal IM_LECI { get; set; }
    public decimal IM_LECF { get; set; }
    public decimal IM_CALI { get; set; }
    public decimal IM_GALO { get; set; }
    public decimal IM_VENT{get;set;}
    public int CO_TRAB{get;set;}
    public string? NombTrab{get;set;}
    public int CO_PVEN{get;set;}
    public int CO_ISLA { get; set; }
    public int CO_SURT{get;set;}
    
    public decimal GalonesCalculados => Math.Round(IM_LECF - IM_LECI - IM_CALI, 3);
    public decimal ImporteCalculado => Math.Round(GalonesCalculados * IM_PRE1, 2);
    
}

public record ContometroTurno(int CO_CONT, DateOnly FechaTurno, int Turno);

public record ResumenContometro(string Producto, decimal Galones, decimal Importe);

public static class TurnosContometro
{
    public static (DateOnly Fecha, int Turno) Siguiente(DateOnly fecha, int turno, int turnoMinimo, int turnoMaximo) =>
        turno >= turnoMaximo ? (fecha.AddDays(1), turnoMinimo) : (fecha, turno + 1);
}



