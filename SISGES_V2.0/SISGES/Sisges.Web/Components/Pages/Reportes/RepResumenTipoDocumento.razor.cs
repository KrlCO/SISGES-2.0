using System.Text;
using Microsoft.JSInterop;
using Sisges.Domain.Entities;

namespace Sisges.Web.Components.Pages.Reportes;

public partial class RepResumenTipoDocumento
{
    private async Task ExportarCsvAsync()
    {
        if (filas is null || filtroAplicado is null) return;

        var sb = new StringBuilder();
        sb.AppendLine(Csv(nombreEmpresa));
        sb.AppendLine(Csv($"RESUMEN POR TIPO DE DOCUMENTO - {TituloFiltro(filtroAplicado)} - {OrigenTexto(filtroAplicado.Origen)}"));
        sb.AppendLine();
        sb.AppendLine("TD,Tipo,Serie,Numero,Fecha,RUC,Nombre o Razon Social,Estado,Cantidad,Valor Venta,Impuestos,Total");
        foreach (var f in filas)
        {
            sb.AppendLine(string.Join(",",
                f.T, Csv(f.TIP), Csv(f.SER), f.NRODOC, f.FDOC, Csv(f.Ruc), Csv(f.Descri), f.ESTADO,
                f.CANTIDAD.ToString("0.000", Cultura), f.ValorVenta.ToString("0.00", Cultura),
                f.IGV.ToString("0.00", Cultura), f.ImporteVenta.ToString("0.00", Cultura)));
        }
        sb.AppendLine(string.Join(",", "", Csv("TOTAL GENERAL"), "", "", "", "", "", "",
            totalGeneral.Cantidad.ToString("0.000", Cultura), totalGeneral.ValorVenta.ToString("0.00", Cultura),
            totalGeneral.Impuestos.ToString("0.00", Cultura), totalGeneral.Total.ToString("0.00", Cultura)));

        var nombreArchivo = $"ResumenTipoDocumento_{GrifoContext.GrifoActivoId}_{filtroAplicado.Desde:yyyyMMdd}_{filtroAplicado.Hasta:yyyyMMdd}.csv";
        await JS.InvokeVoidAsync("sisgesDescargarArchivo", nombreArchivo, "text/csv;charset=utf-8", sb.ToString());
    }

    private static string Csv(string? valor) => "\"" + (valor ?? string.Empty).Replace("\"", "\"\"") + "\"";

    private static string TituloFiltro(FiltroResumenTipoDocumento f) =>
        $"{(f.TipoFecha == TipoFechaReporte.Turno ? "FECHA TURNO" : "FECHA EMISIÓN")} DEL {f.Desde:dd/MM/yyyy} AL {f.Hasta:dd/MM/yyyy}";

    private static string OrigenTexto(OrigenVenta o) => o switch
    {
        OrigenVenta.Combustible => "Combustible",
        OrigenVenta.Market => "Market",
        _ => "Combustible + Market"
    };

    private record GrupoTipo(byte T, string Tipo, List<ResumenTipoDocumento> Filas, List<ResumenSerie> Series, Totales Totales);

    private record ResumenSerie(string Serie, int NumeroDesde, int NumeroHasta, Totales Totales);

    private record Totales(int Documentos, int Anulados, decimal Cantidad, decimal ValorVenta, decimal Impuestos, decimal Total)
    {
        public static readonly Totales Vacio = new(0, 0, 0, 0, 0, 0);

        public static Totales De(IEnumerable<ResumenTipoDocumento> filas)
        {
            int docs = 0, anulados = 0;
            decimal cant = 0, vv = 0, igv = 0, total = 0;
            foreach (var f in filas)
            {
                docs++;
                if (f.EsAnulado) anulados++;
                cant += f.CANTIDAD;
                vv += f.ValorVenta;
                igv += f.IGV;
                total += f.ImporteVenta;
            }
            return new Totales(docs, anulados, cant, vv, igv, total);
        }
    }
}
