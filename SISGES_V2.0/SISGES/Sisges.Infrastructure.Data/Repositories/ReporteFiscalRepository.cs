using System.Data;
using Dapper;
using Sisges.Domain.Common.Interfaces;
using Sisges.Domain.Entities;

namespace Sisges.Infrastructure.Data.Repositories;

public class ReporteFiscalRepository : IReporteFiscalRepository
{
    // En el SISGES original (modMain.bas) empresa y estación siempre son 1 en cada base de datos
    private const byte CodigoEmpresa = 1;
    private const byte CodigoEstacion = 1;

    // Mismo timeout que LibMant.RptIsla (360 s): el SP recorre todo el detalle de documentos
    private const int TimeoutSegundos = 360;

    private readonly ISqlConnectionFactory _connectionFactory;

    public ReporteFiscalRepository(ISqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<IReadOnlyList<ResumenTipoDocumento>> GetResumenTipoDocumentoAsync(
        FiltroResumenTipoDocumento filtro, CancellationToken cancellationToken = default)
    {
        using var connection = _connectionFactory.CreateConnection();

        // Equivalente a LibMant.RptIsla.RepFiscalTipoDocumento (frmRepFisTipDocumento.frm).
        // Con @TIPOFEC = 'T' el SP filtra por FE_TURN: el POS ya graba ahí la fecha del turno
        // de 06:00 a 06:00 (una venta del 21/10 a las 05:00 pertenece al turno del 20/10).
        var parametros = new
        {
            CO_EMPR = CodigoEmpresa,
            CO_ESTA = CodigoEstacion,
            FE_INI = filtro.Desde.ToString("yyyyMMdd"),
            FE_FIN = filtro.Hasta.ToString("yyyyMMdd"),
            CASO = filtro.Origen switch
            {
                OrigenVenta.Combustible => "C",
                OrigenVenta.Market => "M",
                _ => "A"
            },
            TIPOFEC = filtro.TipoFecha == TipoFechaReporte.Turno ? "T" : "E",
            DE_ORDE = filtro.Orden == OrdenReporte.Serie ? "S" : "F"
        };

        var comando = new CommandDefinition(
            "dbo.QSP_TCDOCU_COMB_028_2",
            parametros,
            commandType: CommandType.StoredProcedure,
            commandTimeout: TimeoutSegundos,
            cancellationToken: cancellationToken);

        var filas = (await connection.QueryAsync<ResumenTipoDocumento>(comando)).AsList();

        foreach (var fila in filas)
        {
            if (fila.T == CodigoSunatNotaCredito)
            {
                ForzarNegativo(fila);
            }
        }

        return filas;
    }

    // Código SUNAT de Nota de Crédito (TTTIPO_DOCU.CO_SUNA = '7', ST_POSI_DOCU = 'N')
    private const byte CodigoSunatNotaCredito = 7;

    // Las notas de crédito importadas ("IMPORT GNV SISDOCU") ya se graban en negativo en TCDOCU_COMB
    // y el SP les vuelve a aplicar (-1) por ST_POSI_DOCU = 'N', así que llegan en positivo y suman.
    // Siempre deben restar: se fuerza el signo sin importar cómo vengan de la base de datos.
    private static void ForzarNegativo(ResumenTipoDocumento fila)
    {
        fila.ValorVenta = -Math.Abs(fila.ValorVenta);
        fila.IGV = -Math.Abs(fila.IGV);
        fila.ImporteVenta = -Math.Abs(fila.ImporteVenta);
        fila.CANTIDAD = -Math.Abs(fila.CANTIDAD);
    }
}
