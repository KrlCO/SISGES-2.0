namespace Sisges.Domain.Entities;

public class FormaPagoDocumento
{
    public int CO_TARJ{get; set;}
    public string NO_TARJ{get; set;} = string.Empty;
    public string NU_TARJ{get; set;} = string.Empty;
    public decimal IM_TOTA {get; set;}
}

//Tarjeta del combo (SQP_TTTARJ_CRED_01)
public record TarjetaCredito(int Codigo, string Nombre);

//Docmento al que se le registra el pago (QSP_TCDOCU_COMB_017_2)
public record DocumentoPorPagar(int CO_TDOC, string CO_NSER, int NU_NDOC, decimal IM_TOTA);