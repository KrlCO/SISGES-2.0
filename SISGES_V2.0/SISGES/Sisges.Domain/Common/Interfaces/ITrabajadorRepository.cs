using Sisges.Domain.Entities;

namespace Sisges.Domain.Common.Interfaces;

public interface ITrabajadorRepository
{
    Task<IReadOnlyList<TrabajadorResumen>> BuscarAsync(string texto, bool incluirIncativo);
    Task<Trabajador> ObtenerAsync(int codigo);
    Task<IReadOnlyList<OpcionCatalogo>> GetPerfilesAsync();
    Task<IReadOnlyList<Distrito>>GetDistritoAsync();

    Task<TrabajadorResumen?> BuscarUsuarioDuplicadoAsync(string usuario, int excluirCodigo);
    
    Task<int>RegistrarAsync(Trabajador trabajador, string usuarioOperacion);
    Task ActualizarAsync(Trabajador trabajador, string usuarioOperacion);

    Task DescativarAsync(int codigo, string usuarioOperacion);
}