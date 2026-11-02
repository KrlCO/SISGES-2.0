using Sisges.Domain.Entities;

namespace Sisges.Domain.Common.Interfaces;

// Mantenimientos / Contómetros (frmContometroMeca.frm, LibMant.mstContometro)
public interface IContometroMecanicoRepository
{
    Task<ContometroTurno?> GetUltimoAsync();                       // último turno registrado
    Task<(int Minimo, int Maximo)> GetRangoTurnosAsync();          // FCN_TMTURN_04 / FCN_TMTURN_03
    Task<ContometroTurno?> GetPorTurnoAsync(DateOnly fecha, int turno);
    Task<IReadOnlyList<LecturaContometro>> GetLecturasAsync(ContometroTurno contometro);
    Task<IReadOnlyList<LecturaContometro>> GetValoresInicialesAsync();   // solo si nunca se registraron contómetros
    Task<IReadOnlyList<OpcionCatalogo>> GetGriferosAsync();

    Task<int> RegistrarAsync(DateOnly fecha, int turno, IReadOnlyList<LecturaContometro> lecturas);
    Task ModificarAsync(ContometroTurno contometro, IReadOnlyList<LecturaContometro> lecturas);
    Task EliminarAsync(int codigoContometro);
}
