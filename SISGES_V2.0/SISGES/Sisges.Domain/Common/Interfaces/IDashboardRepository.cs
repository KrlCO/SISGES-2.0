using Sisges.Domain.Entities;

namespace Sisges.Domain.Common.Interfaces;

// Indicadores del Dashboard principal (Home)
public interface IDashboardRepository
{
    Task<ResumenDashboard> GetResumenAsync(CancellationToken cancellationToken = default);

    // Prueba la conexión a todas las estaciones configuradas, en paralelo
    Task<IReadOnlyList<EstadoEstacion>> GetEstadoEstacionesAsync(CancellationToken cancellationToken = default);
}
