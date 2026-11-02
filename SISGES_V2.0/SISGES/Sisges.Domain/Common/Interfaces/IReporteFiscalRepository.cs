using Sisges.Domain.Entities;

namespace Sisges.Domain.Common.Interfaces;

public interface IReporteFiscalRepository
{
    // Reportes / Reportes Fiscales / Resumen por Fechas y Tipo Documento
    Task<IReadOnlyList<ResumenTipoDocumento>> GetResumenTipoDocumentoAsync(
        FiltroResumenTipoDocumento filtro, CancellationToken cancellationToken = default);
}
