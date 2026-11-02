using Sisges.Domain.Entities;

namespace Sisges.Domain.Common.Interfaces;

public interface IContometroMecanicoRepository
{
    Task<ContometroTurno?> GetUltimoAsync();
    Task<(int Minimo, int Maximo)> GetRangoTurnosAsync();
    Task<ContometroTurno?> GetPorTurnoAsync(DateOnly fecha, int turno);
    Task<IReadOnlyList<ContometroMecanico>> GetLecturasAsync(ContometroTurno contometro);
    Task<IReadOnlyList<ContometroMecanico>> GetValoresInicialesAsync();
    Task<IReadOnlyList<OpcionCatalogo>> GetGriferosAsync();
    
    Task<int> RegistrarAsync(DateOnly fecha, int turno, IReadOnlyList<ContometroMecanico> lecturas);
    Task ModificarAsync(ContometroTurno contometro, IReadOnlyList<ContometroMecanico> lecturas);
    Task EliminarAsync(int codigocontometro);
}