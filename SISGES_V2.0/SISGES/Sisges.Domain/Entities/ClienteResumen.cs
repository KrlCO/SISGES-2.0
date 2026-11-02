namespace Sisges.Domain.Entities;

// Fila de búsqueda de clientes (QSP_TCCLIE_02 / QSP_TCCLIE_03)
public class ClienteResumen
{
    public int CO_CLIE { get; set; }
    public string NU_RUC { get; set; } = string.Empty;
    public string NU_RSOC { get; set; } = string.Empty;
    public string DE_DOMI { get; set; } = string.Empty;
    public string ESTADO { get; set; } = string.Empty;
}

// Cliente registrado que choca con el que se está grabando
public class ClienteDuplicado
{
    public int CO_CLIE { get; set; }
    public string? NU_RUC { get; set; }
    public string? NU_DOCU_IDEN { get; set; }
    public string? NU_RSOC { get; set; }
    public string? ST_CLIE { get; set; }

    public bool EstaAnulado => ST_CLIE == "A";
}
