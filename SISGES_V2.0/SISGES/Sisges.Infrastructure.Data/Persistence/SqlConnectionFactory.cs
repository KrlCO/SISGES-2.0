using System.Data;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Sisges.Domain.Common.Interfaces;
using Sisges.Domain.Entities;

namespace Sisges.Infrastructure.Data.Persistence;

public class SqlConnectionFactory : ISqlConnectionFactory
{
    private readonly Dictionary<string, EstacionConfig> _estaciones;
    private readonly IGrifContext _grifoContext;

    public SqlConnectionFactory(IConfiguration configuration, IGrifContext grifoContext)
    {
        _grifoContext = grifoContext;
        
        var lista = configuration.GetSection("Estaciones").Get<List<EstacionConfig>>() ?? new List<EstacionConfig>();
        
        _estaciones = lista.ToDictionary(e => e.Id, e => e, StringComparer.OrdinalIgnoreCase);
        if (_estaciones.Count == 0)
        {
            throw new InvalidOperationException(
                "No se encontró ninguna estación configurada en 'Estaciones' dentro de appsettings.json");
        }
    }
    
    public IDbConnection CreateConnection()
    {
        var grifoId = _grifoContext.GrifoActivoId;

        if (string.IsNullOrEmpty(grifoId))
        {
            //Fallback al primer grifo si aun no se definio contexto
            grifoId = _estaciones.Keys.First();
        }

        return CreateConnection(grifoId);
    }

    public IDbConnection CreateConnection(string grifoId)
    {
        if (!_estaciones.TryGetValue(grifoId, out var config))
        {
            throw new KeyNotFoundException($"El grifo con identificador '{grifoId}' no existe en la configuración");
        }
        return new SqlConnection(config.ConnectionString);
    }

    public IReadOnlyList<EstacionConfig> ObtenerEstaciones()
    {
        return _estaciones.Values.ToList().AsReadOnly();
    }
}