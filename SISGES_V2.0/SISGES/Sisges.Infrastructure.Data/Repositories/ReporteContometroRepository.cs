using System.Data;
using Dapper;
using Sisges.Domain.Common.Interfaces;
using Sisges.Domain.Entities;

namespace Sisges.Infrastructure.Data.Repositories;

public class ReporteContometroRepository : IReporteContometroRepository
{
    private const int TimeoutSegundos = 180;
    private readonly ISqlConnectionFactory _connectionFactory;

    public ReporteContometroRepository(ISqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }
    
    public async Task<IReadOnlyList<ContometrosVsComprobantesItem>> GetContometrosVsComprobantesAsync(DateOnly fechaTurno, byte turno = 0, byte empresa = 1, byte estacion = 1,
        CancellationToken cancellationToken = default)
    {
        using var connection = _connectionFactory.CreateConnection();
        var parametros = new
        {
            CO_EMPR = empresa,
            CO_ESTA = estacion,
            FE_TURN = fechaTurno.ToString("yyyyMMdd"),
            CO_TURN = turno
        };

        var resultado = await connection.QueryAsync<ContometrosVsComprobantesItem>(
            new CommandDefinition(
                "QSP_TMCONT_08_2",
                parametros,
                commandType: CommandType.StoredProcedure,
                commandTimeout: TimeoutSegundos,
                cancellationToken: cancellationToken));
        return resultado.AsList();
    }
    
}