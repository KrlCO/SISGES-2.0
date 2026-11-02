using System.Data;
using System.Data.Common;
using Dapper;
using Sisges.Domain.Common.Interfaces;
using Sisges.Domain.Entities;

namespace Sisges.Infrastructure.Data.Repositories;

public class ContometroMecanicoRepository : IContometroMecanicoRepository
{
    private const int CodigoEmpresa = 1;
    private const int CodigoEstacion = 1;
    private const string LecturaMecanica = "M";
    private const string Activo = "N";
    private const string EstadoDetalle = "0";
    
    private readonly ISqlConnectionFactory _connectionFactory;

    public ContometroMecanicoRepository(ISqlConnectionFactory connectionFactory)
    {
       _connectionFactory = connectionFactory;  
    }
    
    public async Task<ContometroTurno?> GetUltimoAsync()
    {
        using var connection = _connectionFactory.CreateConnection();
        var fila = await connection.QueryFirstOrDefaultAsync(
            "SELECT CO_CONT, FE_TURN, CO_TURN FROM TCCONT WITH(NOLOCK) WHERE CO_CONT = dbo.FSP_TCCONT_02(@CO_EMPR, @CO_ESTA)",
            new { CO_EMPR = CodigoEmpresa, CO_ESTA = CodigoEstacion });
        return fila is null ? null : (ContometroTurno)Mapear(fila);
    }

    public async Task<(int Minimo, int Maximo)> GetRangoTurnosAsync()
    {
        using var connection = _connectionFactory.CreateConnection();
        var fila = await connection.QueryFirstAsync("SELECT dbo.FCN_TMTURN_04() AS MINIMO, dbo.FCN_TMTURN_03() AS MAXIMO");
        return ((int)Convert.ToInt32(fila.MINIMO),  (int)Convert.ToInt32(fila.MAXIMO));
    }

    public async Task<ContometroTurno?> GetPorTurnoAsync(DateOnly fecha, int turno)
    {
        using var connection = _connectionFactory.CreateConnection();
        var fila = await connection.QueryFirstOrDefaultAsync("QSP_TCCONT_001",
            new{CO_TURN = turno, FE_TURN = fecha.ToString("yyyyMMdd")},
        commandType: CommandType.StoredProcedure);
        return fila is null ? null : (ContometroTurno)Mapear(fila);
    }

    public async Task<IReadOnlyList<ContometroMecanico>> GetLecturasAsync(ContometroTurno contometro)
    {
        using var connection = _connectionFactory.CreateConnection();
        var filas = await connection.QueryAsync<ContometroMecanico>("QSP_TMCONT_01",
            new { CO_TURN = contometro.Turno, FE_TURN = contometro.FechaTurno.ToString("yyyyMMdd") },
            commandType: CommandType.StoredProcedure);
        return filas.Select(Redondear).ToList();
    }

    public async Task<IReadOnlyList<ContometroMecanico>> GetValoresInicialesAsync()
    {
        using var connection = _connectionFactory.CreateConnection();
        var filas = await connection.QueryAsync("QSP_TMCONT_06", commandType: CommandType.StoredProcedure);
        return filas.Select(f => new ContometroMecanico
        {
            CO_LADO = Convert.ToInt32(f.LADO),
            CO_MANG =  Convert.ToInt32(f.MANG),
            CO_PROD = Convert.ToInt32(f.PROD),
            NO_PROD = ((string?)f.DE_PROD_CORT)?.Trim() ?? string.Empty,
            IM_PRE1 = Math.Round(Convert.ToDecimal(f.IM_VENT),2),
            CO_ISLA = Convert.ToInt32(f.CO_ISLA ?? 0),
            CO_SURT = Convert.ToInt32(f.CO_SURT ?? 0),
            CO_PVEN = Convert.ToInt32(f.CO_PVEN ?? 0)
        }).ToList();
    }

    public async Task<IReadOnlyList<OpcionCatalogo>> GetGriferosAsync()
    {
        using var connection = _connectionFactory.CreateConnection();
        var filas = await connection.QueryAsync("QSP_TMTRAB_07", new{TIPO_TRAB = "G"},
            commandType: CommandType.StoredProcedure);
        return filas
            .Select(f =>
                new OpcionCatalogo((string)Convert.ToString(f.CO_TRAB), ((string?)f.NomApe)?.Trim() ?? string.Empty))
            .OrderBy(o => o.Descripcion)
            .ToList();
    }

    public async Task<int> RegistrarAsync(DateOnly fecha, int turno, IReadOnlyList<ContometroMecanico> lecturas)
    {
        using var connection = (DbConnection)_connectionFactory.CreateConnection();
        await connection.OpenAsync();
        await using var transaccion = await connection.BeginTransactionAsync();

        var yaExiste = await connection.ExecuteScalarAsync<int>(
            "SELECT COUNT(*) FROM TCCONT WITH(UPDLOCK, HOLDLOCK) WHERE CO_EMPR = @CO_EMPR AND CO_ESTA = @CO_ESTA AND CO_TURN = @CO_TURN AND FE_TURN = @FE_TURN ",
            new{CO_EMPR = CodigoEmpresa, CO_ESTA = CodigoEstacion, FE_TURN = fecha.ToDateTime(TimeOnly.MinValue)},
            transaccion);
        if (yaExiste > 0)
            throw new InvalidOperationException($"Los contometros de {fecha:MM/dd/yyyy} turno {turno} ya estan registrados.");
        var codigo = await connection.ExecuteScalarAsync<int>(
            "SELECT ISNULL (MAX(CO_CONT), 0) +1 FROM TCCONT WITH(UPDLOCK, HOLDLOCK) WHERE CO_EMPR = @CO_EMPR AND CO_ESTA = @CO_ESTA", 
            new{CO_EMPR = CodigoEmpresa, CO_ESTA = CodigoEstacion}, transaccion);
        await InsertarAsync(connection, transaccion, new ContometroTurno(codigo, fecha, turno), lecturas);
        await transaccion.CommitAsync();
        return codigo;
    }

    public async Task ModificarAsync(ContometroTurno contometro, IReadOnlyList<ContometroMecanico> lecturas)
    {
       using var connection = (DbConnection)_connectionFactory.CreateConnection();
       await connection.OpenAsync();
       await using var transaccion = await connection.BeginTransactionAsync();
       
       await ValidarUltimoAsync(connection, transaccion, contometro.CO_CONT);
       await connection.ExecuteAsync(
           """
           DELETE TDCONT WHERE CO_EMPR = @CO_EMPR AND CO_ESTA = @CO_ESTA AND CO_CONT = @CO_CONT;
           DELETE TCCONT WHERE CO_EMPR = @CO_EMPR AND CO_ESTA = @CO_ESTA AND CO_CONT = @CO_CONT;
           """,
           new { CO_EMPR = CodigoEmpresa, CO_ESTA = CodigoEstacion, contometro.CO_CONT }, transaccion);
       await InsertarAsync(connection, transaccion, contometro, lecturas);
       await transaccion.CommitAsync();
    }

    public async Task EliminarAsync(int codigocontometro)
    {
       using var connection = (DbConnection)_connectionFactory.CreateConnection();
       await connection.OpenAsync();
       await ValidarUltimoAsync(connection, null, codigocontometro);
       await connection.ExecuteAsync("QSP_TMCONT_009", new{CO_CONT = codigocontometro},
       commandType:  CommandType.StoredProcedure);
    }

    private static async Task InsertarAsync(DbConnection connection, DbTransaction transaccion,
        ContometroTurno contometro, IReadOnlyList<ContometroMecanico> lecturas)
    {
        await connection.ExecuteAsync("ISP_TCCONT_01",
            new
            {
                CO_EMPR = CodigoEmpresa,
                CO_ESTA = CodigoEstacion,
                contometro.CO_CONT,
                CO_TURN = contometro.Turno,
                FE_TURN = contometro.FechaTurno.ToDateTime(TimeOnly.MinValue),
                IM_IMPO = Math.Round(lecturas.Sum(l => l.GalonesCalculados * l.IM_PRE1), 2),
                DE_TLEC = LecturaMecanica,
                IM_GALO = lecturas.Sum(l => l.GalonesCalculados),
                ST_CONT = Activo
            },
            transaccion, commandType: CommandType.StoredProcedure);
        foreach (var l in lecturas)
        {
            await connection.ExecuteAsync("ISP_TDCONT_01",
                new
                {
                    CO_EMPR = CodigoEmpresa,
                    CO_ESTA = CodigoEstacion,
                    contometro.CO_CONT,
                    CO_DCON =1,
                    l.CO_PVEN,
                    l.CO_ISLA,
                    l.CO_SURT,
                    l.CO_LADO,
                    l.CO_MANG,
                    l.CO_TRAB,
                    l.CO_PROD,
                    l.IM_PRE1,
                    IM_PRE2 = 0m,
                    l.IM_LECI,
                    l.IM_LECF,
                    IM_VENT = l.ImporteCalculado,
                    IM_GALO = l.GalonesCalculados,
                    ST_DCON = EstadoDetalle,
                    l.IM_CALI
                },
                transaccion,  commandType: CommandType.StoredProcedure);
        }
                
    }

    private static async Task ValidarUltimoAsync(DbConnection connection, DbTransaction? transaccion,
        int codigoContometro)
    {
        var ultimo = await connection.ExecuteScalarAsync<int>(
            "SELECT ISNULL (MAX(CO_CONT), 0) FROM TCCONT WITH(UPDLOCK, HOLDLOCK) WHERE CO_EMPR = @CO_EMPR AND CO_ESTA = @CO_ESTA",
            new{CO_EMPR = CodigoEmpresa, CO_ESTA = CodigoEstacion},transaccion);
            if (ultimo != codigoContometro)
                throw new InvalidOperationException(
                    "Solo se puede modificar o eleiminar el ultimo turno registrado: existe un turno posterior");
    }
    
    private static ContometroTurno Mapear(dynamic fila) =>
        new((int)fila.CO_CONT, DateOnly.FromDateTime((DateTime)fila.FE_TURN), Convert.ToInt32(fila.CO_TURN));

    private static ContometroMecanico Redondear(ContometroMecanico l)
    {
        l.NO_PROD = l.NO_PROD.Trim();
        l.NombTrab = l.NombTrab?.Trim();
        l.IM_PRE1 = Math.Round(l.IM_PRE1, 2);
        l.IM_LECI = Math.Round(l.IM_LECI, 3);
        l.IM_LECF = Math.Round(l.IM_LECF, 3);
        l.IM_CALI = Math.Round(l.IM_CALI, 3);
        l.IM_GALO = Math.Round(l.IM_GALO, 3);
        l.IM_VENT = Math.Round(l.IM_VENT, 2);
        return l;
    }
}

