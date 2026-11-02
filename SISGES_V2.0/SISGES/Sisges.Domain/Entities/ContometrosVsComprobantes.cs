namespace Sisges.Domain.Entities;

public class ContometrosVsComprobantesItem
{
    public string? GRIFO{ get; set; }
    public DateTime? FE_TURN { get; set; }
    public int TIPOREG { get; set; }
    public string? DSC{ get; set; }
    public decimal G84 { get; set; }
    public decimal G90  { get; set; }
    public decimal G95 { get; set; }
    public decimal G97 { get; set; }
    public decimal GD2{ get; set; }
    public decimal GD1 { get; set; }
    public decimal GLP { get; set; }
    public decimal GNV{ get; set; }
    public decimal TOTGLN { get; set; }
    public decimal TOT { get; set; }
}

public class FiltroContometroVsComprobantes
{
    public DateOnly Fecha { get; set; } = DateOnly.FromDateTime(DateTime.Today);
    public byte Turno { get; set; } = 0;
    public byte Empresa { get; set; } = 1;
    public byte Estacion { get; set; } = 1;
}