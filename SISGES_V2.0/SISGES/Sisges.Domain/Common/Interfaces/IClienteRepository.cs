using Sisges.Domain.Entities;

namespace Sisges.Domain.Common.Interfaces;

public interface IClienteRepository
{
    Task<IReadOnlyList<TipoCliente>> GetTiposClienteAsync();
    Task<IReadOnlyList<TipoEmision>> GetTiposEmisionAsync();
    Task<decimal> GetLimiteCreditoPorDefectoAsync();

    //Task<IReadOnlyList<ClienteResumen>> BuscarAsync(string texto);
    Task<IReadOnlyList<ClienteResumen>> BuscarAsync(string? texto = null);
    Task<Cliente?> ObtenerAsync(int codigo);

    Task<bool> EsDocumentoValidoAsync(string ruc);
    Task<string> NormalizarRazonSocialAsync(string razonSocial);
    Task<IReadOnlyList<ClienteDuplicado>> BuscarDuplicadosAsync(Cliente cliente);
    
    Task<int>RegistrarAsync(Cliente cliente, string usuario);
    Task ActualizarAsync(Cliente cliente, string usuario);

    Task InactivarAsync(int codigo, string usuario);
    Task ReactivarAsync(int codigo, string usuario);

}
