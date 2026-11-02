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

    private const string LecturaMecanica = "M";    // TCCONT.DE_TLEC
    private const string Activo = "N";             // TCCONT.ST_CONT
    // El original manda ST_DCON = 0 (AddParame con el valor en la posición equivocada); se conserva igual
    private const string EstadoDetalle = "0";

    private readonly ISqlConnectionFactory _connectionFactory;

    public ContometroMecanicoRepository(ISqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    // mstContometro.UltimoIngreso (FSP_TCCONT_02). La función devuelve 1 cuando no hay registros,
    // por eso se confirma que ese CO_CONT exista.
    public async Task<ContometroTurno?> GetUltimoAsync()
    {
        using var connection = _connectionFactory.CreateConnection();
        var fila = await connection.QueryFirstOrDefaultAsync(
            "SELECT CO_CONT, FE_TURN, CO_TURN FROM TCCONT WITH (NOLOCK) WHERE CO_CONT = dbo.FSP_TCCONT_02(@CO_EMPR, @CO_ESTA)",
            new { CO_EMPR = CodigoEmpresa, CO_ESTA = CodigoEstacion });
        return fila is null ? null : (ContometroTurno)Mapear(fila);
    }

    // MstTurno.MinimoTurnos / MaximoTurnos
    public async Task<(int Minimo, int Maximo)> GetRangoTurnosAsync()
    {
        using var connection = _connectionFactory.CreateConnection();
        var fila = await connection.QueryFirstAsync("SELECT dbo.FCN_TMTURN_04() AS MINIMO, dbo.FCN_TMTURN_03() AS MAXIMO");
        return ((int)Convert.ToInt32(fila.MINIMO), (int)Convert.ToInt32(fila.MAXIMO));
    }

    // mstContometro.GetTurnoByCoTurnByFeTurno
    public async Task<ContometroTurno?> GetPorTurnoAsync(DateOnly fecha, int turno)
    {
        using var connection = _connectionFactory.CreateConnection();
        var fila = await connection.QueryFirstOrDefaultAsync("dbo.QSP_TCCONT_001",
            new { CO_TURN = turno, FE_TURN = fecha.ToString("yyyyMMdd") },
            commandType: CommandType.StoredProcedure);
        return fila is null ? null : (ContometroTurno)Mapear(fila);
    }

    // mstContometro.MostrarCont_X_Turno_FTurno
    public async Task<IReadOnlyList<LecturaContometro>> GetLecturasAsync(ContometroTurno contometro)
    {
        using var connection = _connectionFactory.CreateConnection();
        var filas = await connection.QueryAsync<LecturaContometro>("dbo.QSP_TMCONT_01",
            new { CO_TURN = contometro.Turno, FE_TURN = contometro.FechaTurno.ToString("yyyyMMdd") },
            commandType: CommandType.StoredProcedure);
        return filas.Select(Redondear).ToList();
    }

    // mstContometro.GetContoInicial: lados y mangueras con el precio actual del producto
    public async Task<IReadOnlyList<LecturaContometro>> GetValoresInicialesAsync()
    {
        using var connection = _connectionFactory.CreateConnection();
        var filas = await connection.QueryAsync("dbo.QSP_TMCONT_06", commandType: CommandType.StoredProcedure);
        return filas.Select(f => new LecturaContometro
        {
            CO_LADO = Convert.ToInt32(f.CO_LADO),
            CO_MANG = Convert.ToInt32(f.CO_MANG),
            CO_PROD = Convert.ToInt32(f.CO_PROD),
            NO_PROD = ((string?)f.DE_PROD_CORT)?.Trim() ?? string.Empty,
            IM_PRE1 = Math.Round(Convert.ToDecimal(f.IM_VENT), 2),     // en este SP IM_VENT es el precio del producto
            CO_ISLA = Convert.ToInt32(f.CO_ISLA ?? 0),
            CO_SURT = Convert.ToInt32(f.CO_SURT ?? 0),
            CO_PVEN = Convert.ToInt32(f.CO_PVEN ?? 0)
        }).ToList();
    }

    // MstTrabajador.Get_Trab_X_Tipo("G"): griferos activos
    public async Task<IReadOnlyList<OpcionCatalogo>> GetGriferosAsync()
    {
        using var connection = _connectionFactory.CreateConnection();
        var filas = await connection.QueryAsync("dbo.QSP_TMTRAB_07", new { TIPO_TRAB = "G" },
            commandType: CommandType.StoredProcedure);
        return filas
            .Select(f => new OpcionCatalogo((string)Convert.ToString(f.CO_TRAB), ((string?)f.NomApe)?.Trim() ?? string.Empty))
            .OrderBy(o => o.Descripcion)
            .ToList();
    }

    // mstContometro.AgregarContometros
    public async Task<int> RegistrarAsync(DateOnly fecha, int turno, IReadOnlyList<LecturaContometro> lecturas)
    {
        using var connection = (DbConnection)_connectionFactory.CreateConnection();
        await connection.OpenAsync();
        await using var transaccion = await connection.BeginTransactionAsync();

        // UPDLOCK/HOLDLOCK hasta el COMMIT: dos usuarios no pueden registrar el mismo turno ni tomar el mismo código
        var yaExiste = await connection.ExecuteScalarAsync<int>(
            "SELECT COUNT(*) FROM TCCONT WITH (UPDLOCK, HOLDLOCK) WHERE CO_EMPR = @CO_EMPR AND CO_ESTA = @CO_ESTA AND CO_TURN = @CO_TURN AND FE_TURN = @FE_TURN",
            new { CO_EMPR = CodigoEmpresa, CO_ESTA = CodigoEstacion, CO_TURN = turno, FE_TURN = fecha.ToDateTime(TimeOnly.MinValue) },
            transaccion);
        if (yaExiste > 0)
            throw new InvalidOperationException($"Los contómetros del {fecha:dd/MM/yyyy} turno {turno} ya están registrados.");

        // Igual que dbo.QSP_TCCONT_99 (MAX + 1), pero bloqueando
        var codigo = await connection.ExecuteScalarAsync<int>(
            "SELECT ISNULL(MAX(CO_CONT), 0) + 1 FROM TCCONT WITH (UPDLOCK, HOLDLOCK) WHERE CO_EMPR = @CO_EMPR AND CO_ESTA = @CO_ESTA",
            new { CO_EMPR = CodigoEmpresa, CO_ESTA = CodigoEstacion }, transaccion);

        await InsertarAsync(connection, transaccion, new ContometroTurno(codigo, fecha, turno), lecturas);
        await transaccion.CommitAsync();
        return codigo;
    }

    // El original modifica con USP_TDCONT_01, que hace INSERT en una tabla temp_parametros2 que no existe
    // en ninguna base (falla siempre) y no actualiza los totales de TCCONT. Aquí se borra y se vuelve a
    // insertar el mismo CO_CONT en una transacción. Solo se permite sobre el último turno registrado.
    public async Task ModificarAsync(ContometroTurno contometro, IReadOnlyList<LecturaContometro> lecturas)
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

    // Botón "Eliminar" del original (QSP_TMCONT_009): solo el último turno registrado
    public async Task EliminarAsync(int codigoContometro)
    {
        using var connection = (DbConnection)_connectionFactory.CreateConnection();
        await connection.OpenAsync();
        await ValidarUltimoAsync(connection, null, codigoContometro);
        await connection.ExecuteAsync("dbo.QSP_TMCONT_009", new { CO_CONT = codigoContometro },
            commandType: CommandType.StoredProcedure);
    }

    private static async Task InsertarAsync(DbConnection connection, DbTransaction transaccion,
        ContometroTurno contometro, IReadOnlyList<LecturaContometro> lecturas)
    {
        // El original graba 0 en los totales por un error de conversión (Val("1,234.56") = 1); aquí van los reales
        await connection.ExecuteAsync("dbo.ISP_TCCONT_01",
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
            await connection.ExecuteAsync("dbo.ISP_TDCONT_01",
                new
                {
                    CO_EMPR = CodigoEmpresa,
                    CO_ESTA = CodigoEstacion,
                    contometro.CO_CONT,
                    CO_DCON = 1,               // el original siempre manda 1
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
                transaccion, commandType: CommandType.StoredProcedure);
        }
    }

    // "No se puede Actualizar Contometros Mecánicos debido a que existe un turno superior a corregir"
    private static async Task ValidarUltimoAsync(DbConnection connection, DbTransaction? transaccion, int codigoContometro)
    {
        var ultimo = await connection.ExecuteScalarAsync<int>(
            "SELECT ISNULL(MAX(CO_CONT), 0) FROM TCCONT WITH (UPDLOCK, HOLDLOCK) WHERE CO_EMPR = @CO_EMPR AND CO_ESTA = @CO_ESTA",
            new { CO_EMPR = CodigoEmpresa, CO_ESTA = CodigoEstacion }, transaccion);
        if (ultimo != codigoContometro)
            throw new InvalidOperationException("Solo se puede modificar o eliminar el último turno registrado: existe un turno posterior.");
    }

    private static ContometroTurno Mapear(dynamic fila) =>
        new((int)fila.CO_CONT, DateOnly.FromDateTime((DateTime)fila.FE_TURN), Convert.ToInt32(fila.CO_TURN));

    private static LecturaContometro Redondear(LecturaContometro l)
    {
        l.NO_PROD = l.NO_PROD.Trim();
        l.NombTra = l.NombTra?.Trim();
        l.IM_PRE1 = Math.Round(l.IM_PRE1, 2);
        l.IM_LECI = Math.Round(l.IM_LECI, 3);
        l.IM_LECF = Math.Round(l.IM_LECF, 3);
        l.IM_CALI = Math.Round(l.IM_CALI, 3);
        l.IM_GALO = Math.Round(l.IM_GALO, 3);
        l.IM_VENT = Math.Round(l.IM_VENT, 2);
        return l;
    }
}
