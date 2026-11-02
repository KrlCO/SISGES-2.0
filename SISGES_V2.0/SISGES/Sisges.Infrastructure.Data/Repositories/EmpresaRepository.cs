using System.Data;
using Dapper;
using Sisges.Domain.Common.Interfaces;
using Sisges.Domain.Entities;

namespace Sisges.Infrastructure.Data.Repositories;

public class EmpresaRepository : IEmpresaRepository
{
    private readonly ISqlConnectionFactory _connectionFactory;

    public EmpresaRepository(ISqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<IEnumerable<Empresa>> GetEmpresaAsync()
    {
        using var connection = _connectionFactory.CreateConnection();
        
        // QSP_TMEMPR_03 devuelve listado con CO_EMPR y NO_EMPR
        var listaBase = (await connection.QueryAsync<Empresa>(
            "QSP_TMEMPR_03",
            commandType: CommandType.StoredProcedure)).ToList();

        if (listaBase.Count == 0)
        {
            return listaBase;
        }

        // Enriquecer cada registro con los datos completos desde QSP_TMEMPR_02 (RUC, Dirección, Teléfono, etc.)
        var empresasCompletas = new List<Empresa>();
        foreach (var emp in listaBase)
        {
            var detalle = await connection.QueryFirstOrDefaultAsync<Empresa>(
                "QSP_TMEMPR_02",
                new { CO_EMPR = emp.CO_EMPR },
                commandType: CommandType.StoredProcedure);

            empresasCompletas.Add(detalle ?? emp);
        }

        return empresasCompletas;
    }

    public async Task<Empresa?> GetEmpresaPorCodigoAsync(int codigo)
    {
        using var connection = _connectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Empresa>(
            "QSP_TMEMPR_02",
            new { CO_EMPR = codigo },
            commandType: CommandType.StoredProcedure);
    }
}
