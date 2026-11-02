using System.Data;
using System.Data.Common;
using Dapper;
using Sisges.Domain.Common.Interfaces;
using Sisges.Domain.Entities;

namespace Sisges.Infrastructure.Data.Repositories;

public class FormaPagoRepository : IFormaPagoRepository
{
    private const string OrigenCombustible = "C";
    private readonly ISqlConnectionFactory _connectionFactory;

    public FormaPagoRepository(ISqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }
    
    public async Task<IReadOnlyList<TarjetaCredito>> GetTarjetasAsync()
    {
        using var connection = _connectionFactory.CreateConnection();
        var filas = await connection.QueryAsync("QSP_TTTARJ_CRED_01", new{NO_TARJ = string.Empty},
            commandType: CommandType.StoredProcedure);
        return filas.Select(f => new TarjetaCredito((int)Convert.ToInt32(f.CO_TARJ), ((string)f.NO_TARJ).Trim())).ToList();
    }

    public async Task<IReadOnlyList<int>> GetTiposDocumentoConPagoAsync()
    {
      using var connection = _connectionFactory.CreateConnection();
      var filas = await connection.QueryAsync("QSP_TTTIPO_DOCU_010", commandType: CommandType.StoredProcedure);
      return filas.Select(f => (int)Convert.ToInt32(f.CO_TDOC)).ToList();
    }

    public async Task<DocumentoPorPagar?> GetDocumentoAsync(int tipoDocumento, string serie, int numero)
    {
       using var connection = _connectionFactory.CreateConnection();
       var fila =await connection.QueryFirstOrDefaultAsync("QSP_TCDOCU_COMB_017_2", new{CO_TDOC = tipoDocumento, CO_NSER = serie, NU_NDOC = numero,  ST_TIPO = OrigenCombustible}, commandType: CommandType.StoredProcedure);
       return fila is null ? null : new DocumentoPorPagar(tipoDocumento, serie, numero, Math.Round((decimal)fila.IM_TOTA, 2));
    }

    public async Task<IReadOnlyList<FormaPagoDocumento>> GetFormasPagoAsync(int tipoDocumento, string serie, int numero)
    {
        using var connection = _connectionFactory.CreateConnection();
        var filas = await connection.QueryAsync<FormaPagoDocumento>("QSP_TTFPAG_DOCU_COMB_007",
            new{CO_TDOC = tipoDocumento, CO_NSER = serie, NU_NDOC = numero},
            commandType: CommandType.StoredProcedure);
        return filas.Select(f => { f.NU_TARJ = f.NU_TARJ.Trim();
            f.IM_TOTA = Math.Round(f.IM_TOTA, 2);
            return f;}).ToList();
        
    }

    public async Task GuardarAsync(DocumentoPorPagar documento, IReadOnlyList<FormaPagoDocumento> actuales, IReadOnlyList<FormaPagoDocumento> nuevas, string usuario)
    {
       using var connection = (DbConnection)_connectionFactory.CreateConnection();
       await connection.OpenAsync();
       await using var transaccion = await connection.BeginTransactionAsync();

       foreach (var pago in actuales)
       {
           await EjecutarAsync(connection, transaccion, documento, pago, "D",  usuario);
       }

       foreach (var pago in nuevas)
       {
           await EjecutarAsync(connection, transaccion, documento, pago, "I", usuario);
       }
       
       await connection.ExecuteAsync(
           """
           UPDATE P SET P.CO_TURN = D.CO_TURN, P.FE_TURN = D.FE_TURN
           FROM TTFPAG_DOCU_COMB P
                    INNER JOIN TCDOCU_COMB D ON D.CO_TDOC = P.CO_TDOC AND P.NU_NDOC = @NU_NDOC AND P.FE_TURN IS NULL
           """,
           new{documento.CO_TDOC, documento.CO_NSER, documento.NU_NDOC}, transaccion);
       await transaccion.CommitAsync();
    }
    
    private static Task EjecutarAsync(DbConnection connection, DbTransaction transaccion, DocumentoPorPagar documento, FormaPagoDocumento pago, string operacion, string usuario) =>
    connection.ExecuteAsync("SP_TTFPAG_DOCU_COMB_M01_2",
        new
        {
            INCO_TDOC = documento.CO_TDOC,
            INCO_NSER = documento.CO_NSER,
            INNU_NDOC = documento.NU_NDOC,
            INIM_TOTA = operacion == "D" ? 0m : pago.IM_TOTA,
            INCO_TARJ = pago.CO_TARJ,
            ISST_PROC = operacion,
            ISNU_TARJ = pago.NU_TARJ,
            ISST_ORIG_DOCU = OrigenCombustible,
            ISCO_USUA = usuario
        },
        transaccion, commandType: CommandType.StoredProcedure);
}