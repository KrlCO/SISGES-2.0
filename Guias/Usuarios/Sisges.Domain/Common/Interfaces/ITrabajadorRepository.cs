using Sisges.Domain.Entities;

namespace Sisges.Domain.Common.Interfaces;

// Tablas / Trabajadores - Usuarios (frmMstTrabajador.frm, LibMant.MstTrabajador)
public interface ITrabajadorRepository
{
    Task<IReadOnlyList<TrabajadorResumen>> BuscarAsync(string texto, bool incluirInactivos);
    Task<Trabajador?> ObtenerAsync(int codigo);
    Task<IReadOnlyList<OpcionCatalogo>> GetPerfilesAsync();
    Task<IReadOnlyList<Distrito>> GetDistritosAsync();

    // Otro trabajador (distinto a 'excluirCodigo') que ya usa ese código de usuario; null si está libre
    Task<TrabajadorResumen?> BuscarUsuarioDuplicadoAsync(string usuario, int excluirCodigo);

    Task<int> RegistrarAsync(Trabajador trabajador, string usuarioOperacion);
    Task ActualizarAsync(Trabajador trabajador, string usuarioOperacion);

    // Baja lógica: ST_TRAB = 'A', sin permisos especiales y con una clave aleatoria que nadie conoce
    Task DesactivarAsync(int codigo, string usuarioOperacion);
}
