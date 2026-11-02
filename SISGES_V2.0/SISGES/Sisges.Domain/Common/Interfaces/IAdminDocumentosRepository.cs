using Sisges.Domain.Entities;
namespace Sisges.Domain.Common.Interfaces;

public interface IAdminDocumentosRepository
{
    Task<TurnoActual?> GetTurnoActualAsync();
    Task<IReadOnlyList<OpcionCatalogo>> GetTurnosAsync();
    Task<IReadOnlyList<OpcionCatalogo>> GetTerminalesAsync();
    Task<IReadOnlyList<OpcionCatalogo>> GetTrabajadoresAsync();
    Task<IReadOnlyList<OpcionCatalogo>> GetTiposDocumentosAsync();
    Task<IReadOnlyList<OpcionCatalogo>> GetFormasEmisionAsync();

    Task<IReadOnlyList<DocumentoVentaIsla>> BuscarDocumentosAsync(FiltroDocumentosIsla filtro);
    Task<string> GetEstadoTurnoAsync(DateTime fecha, int turno);
    Task<IReadOnlyList<LiquidacionTurno>> GetLiquidacionesAsync(DateTime fecha, int turno);
}