using System.Data;
using Sisges.Domain.Entities;

namespace Sisges.Domain.Common.Interfaces;

public interface ISqlConnectionFactory
{
    //Obtiene conexión de la base de datos del grifo actualmente seleccionado en sesión
    IDbConnection CreateConnection();
    
    //Permite abrir conexión a un grifo especifico
    IDbConnection CreateConnection(string grifoId);
    
    //Listado de estaciones configuradas en el sistema
    IReadOnlyList<EstacionConfig> ObtenerEstaciones();

}

