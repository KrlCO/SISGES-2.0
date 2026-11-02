using Sisges.Domain.Entities;

namespace Sisges.Domain.Common.Interfaces;

public interface IEmpresaRepository
{
    Task<IEnumerable<Empresa>> GetEmpresaAsync();
    Task<Empresa?> GetEmpresaPorCodigoAsync(int codigo);
}
