using Sisges.Domain.Entities;

namespace Sisges.Domain.Common.Interfaces;

//Forma de pago por Documentos
public interface IFormaPagoRepository
{
    Task<IReadOnlyList<TarjetaCredito>> GetTarjetasAsync();
    Task<IReadOnlyList<int>> GetTiposDocumentoConPagoAsync();
    
    Task<DocumentoPorPagar?>GetDocumentoAsync(int tipoDocumento, string serie, int numero);
    Task<IReadOnlyList<FormaPagoDocumento>>GetFormasPagoAsync(int tipoDocumento, string serie, int numero);
    //Lista vacia = todo en efectivo
    Task GuardarAsync(DocumentoPorPagar documento, IReadOnlyList<FormaPagoDocumento> actuales, IReadOnlyList<FormaPagoDocumento> nuevas, string usuario);
}