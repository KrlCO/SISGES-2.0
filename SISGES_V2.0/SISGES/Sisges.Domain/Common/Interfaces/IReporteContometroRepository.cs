using Sisges.Domain.Entities;

namespace Sisges.Domain.Common.Interfaces;

public interface IReporteContometroRepository
{
    Task<IReadOnlyList<ContometrosVsComprobantesItem>> GetContometrosVsComprobantesAsync( DateOnly fechaTurno,
    byte turno = 0, byte empresa = 1, byte estacion = 1, CancellationToken cancellationToken = default);
}