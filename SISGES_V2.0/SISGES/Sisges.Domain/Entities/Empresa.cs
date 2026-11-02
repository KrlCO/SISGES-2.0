namespace Sisges.Domain.Entities;

public class Empresa
{
    public int CO_EMPR { get; set; }
    public string NO_EMPR { get; set; } = string.Empty;
    public string DE_NOMB_CORT { get; set; } = string.Empty;
    public string? NU_RUCS { get; set; }
    public string? DE_DIRE { get; set; }
    public string? NU_TEL1 { get; set; }
    public string? NU_TEL2 { get; set; }
    public string? NU_FAXS { get; set; }
    public string? DE_SITE_WEB { get; set; }
    public string? DE_MAIL { get; set; }
    public string? CO_GEOG { get; set; }
    public string? DEP { get; set; }
    public string? PROV { get; set; }
    public string? DIST { get; set; }
}
