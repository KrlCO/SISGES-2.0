namespace Sisges.Domain.Entities;

public class DocumentoVentaIsla
{
    public int CO_PVEN{get;set;}
    public int NU_LADO { get; set; } 
    public string DE_NOMB{get;set;} = string.Empty;
    public string NRODOC{get;set;} =  string.Empty;
    public string NU_RUC{get;set;} = string.Empty;
    public string NU_RSOC{get;set;} = string.Empty;
    public string DE_PROD_CORT{get;set;} = string.Empty;
    public decimal IM_VNET {get;set;}
    public decimal IM_IGV{get;set;}
    public decimal IM_TOTA{get;set;}
    public string? GRIFERO{get;set;}
    public string ESTADO{get;set;} = string.Empty;
    public int CO_TDOC{get;set;}
    public string CO_NSER{get;set;} = string.Empty;
    public int NU_NDOC{get;set;}
    public int CO_TRAB{get;set;}
    public string? FE_HORA{get;set;}
    public string? NU_LIQI{get;set;}
    public string? EMISION{get;set;}
    public int CO_PROD{get;set;}
    public DateTime? FE_TURN{get;set;}
    public DateTime? FE_EMIS{get;set;}
    public string? FE_EMIS_HORA{get;set;}
    
    public bool EstaAnulado => ESTADO == "ANULADO";
}

public record ResumenVentaIsla(string TipoDocumento, decimal ValorVenta, decimal Igv, decimal Total, int Activos, int Anulados);

//Liquidaciones de griferos por del turno
public class LiquidacionTurno
{
    public object? NU_LIQI { get; set; }
    public DateTime? FE_TURN{get;set;}
    public int CO_TURN{get;set;}
    public int CO_TRAB{get;set;}
    public string? NombTrab{get;set;}
    public string? ESTADO{get;set;}
}

//turno en curso
public record TurnoActual(DateTime Fecha, int Turno);

//Combo de turnos, terminales, trabajadores, tipos de documentos
public record OpcionCatalogo(string Codigo, string Descripcion);

//Opcion de Combo de turnos
public record FiltroDocumentosIsla(
    DateTime Fecha,
    TipoFechaReporte TipoFecha,
    int Turno,
    int Terminal = 0,
    int Trabajador = 0,
    string FormaEmision = "",
    int TipoDocumento = 0,
    string Serie = "",
    int Numero = 0)
{
    public bool EsBusquedaPorDocumento => !string.IsNullOrWhiteSpace(Serie) && Numero > 0;
}