using System.Globalization;
using System.Text;
using Microsoft.JSInterop;
using Sisges.Domain.Entities;

namespace Sisges.Web.Components.Pages.Ventas;

public partial class RepDepositosTarjetas
{
    private static readonly CultureInfo Cultura = CultureInfo.InvariantCulture;

    private static readonly (TipoReporteDepositos Valor, string Texto, string Icono)[] opcionesTipo =
    {
        (TipoReporteDepositos.Todo, "Todo", "bi-collection"),
        (TipoReporteDepositos.Tarjetas, "Tarjetas", "bi-credit-card"),
        (TipoReporteDepositos.Depositos, "Depósitos", "bi-cash-stack"),
        (TipoReporteDepositos.ResumenTarjetas, "Resumen Tarjetas", "bi-calendar-range"),
    };

    // Filtros (por defecto "Todo" y "Todos los turnos", como el formulario original)
    private TipoReporteDepositos tipo = TipoReporteDepositos.Todo;
    private DateOnly fecha = DateOnly.FromDateTime(DateTime.Today);
    private DateOnly hasta = DateOnly.FromDateTime(DateTime.Today);
    private int turno;
    private bool detallado;
    private IReadOnlyList<OpcionCatalogo> turnos = Array.Empty<OpcionCatalogo>();
    private DateOnly fechaTurnoActual = DateOnly.FromDateTime(DateTime.Today);

    // Resultado
    private FiltroDepositosTarjetas? filtroAplicado;
    private List<FilaTarjeta> resumenTarjetas = new();
    private List<int> turnosResumen = new();
    private List<GrupoGrifero> vouchersPorGrifero = new();
    private List<FilaDeposito> depositos = new();
    private decimal totalTarjetas;
    private decimal totalSoles;
    private decimal totalDolares;
    private int cantidadVouchers;
    private DateTime fechaProceso;
    private string busqueda = string.Empty;

    private bool cargando;
    private string? mensajeError;
    private int consultaActual;    // descarta respuestas de una consulta anterior o de otro grifo

    private string nombreEmpresa = string.Empty;
    private string nombreEstacion = string.Empty;

    private bool EsResumen => tipo == TipoReporteDepositos.ResumenTarjetas;
    private bool HayDatos => resumenTarjetas.Count > 0 || vouchersPorGrifero.Count > 0 || depositos.Count > 0;
    private bool MostrarFecha => filtroAplicado is { Tipo: TipoReporteDepositos.ResumenTarjetas, Detallado: true };
    private bool MostrarDocumento => MostrarFecha;
    private int ColumnasVoucher => 4 + (MostrarFecha ? 1 : 0) + (MostrarDocumento ? 1 : 0);

    protected override async Task OnInitializedAsync()
    {
        GrifoContext.GrifoCambiado += OnGrifoCambiado;
        await CargarDatosGrifoAsync();
    }

    private async Task CargarDatosGrifoAsync()
    {
        nombreEstacion = ConnectionFactory.ObtenerEstaciones()
                             .FirstOrDefault(e => e.Id == GrifoContext.GrifoActivoId)?.Nombre
                         ?? GrifoContext.GrifoActivoId;
        try
        {
            turnos = await AdminDocumentosRepository.GetTurnosAsync();
            var actual = await AdminDocumentosRepository.GetTurnoActualAsync();
            if (actual is not null) fechaTurnoActual = DateOnly.FromDateTime(actual.Fecha);
            FijarFecha(0);

            var empresa = (await EmpresaRepository.GetEmpresaAsync()).FirstOrDefault();
            nombreEmpresa = empresa?.NO_EMPR ?? nombreEstacion;
            if (!string.IsNullOrWhiteSpace(empresa?.DE_NOMB_CORT)) nombreEstacion = empresa.DE_NOMB_CORT;
        }
        catch (Exception ex)
        {
            nombreEmpresa = nombreEstacion;
            mensajeError = $"No se pudieron cargar los turnos: {ex.Message}";
        }
    }

    // Toma la fecha del turno en curso (QSP_TTTURN_01), no la del reloj
    private void FijarFecha(int dias)
    {
        fecha = fechaTurnoActual.AddDays(dias);
        hasta = fecha;
    }

    private async Task ProcesarAsync()
    {
        if (EsResumen && fecha > hasta)
        {
            mensajeError = "La fecha 'Desde' no puede ser mayor que la fecha 'Hasta'.";
            return;
        }

        var filtro = new FiltroDepositosTarjetas(tipo, fecha, EsResumen ? 0 : turno, EsResumen ? hasta : fecha, detallado);
        var consulta = ++consultaActual;
        cargando = true;
        mensajeError = null;

        try
        {
            IReadOnlyList<MovimientoCaja> movimientos = Array.Empty<MovimientoCaja>();
            IReadOnlyList<TarjetaResumen> resumen = Array.Empty<TarjetaResumen>();
            IReadOnlyList<TarjetaDetalle> detalle = Array.Empty<TarjetaDetalle>();

            if (filtro.Tipo != TipoReporteDepositos.ResumenTarjetas)
                movimientos = await ReporteCajaRepository.GetMovimientosAsync(filtro.Tipo, filtro.Fecha, filtro.Turno);
            else if (filtro.Detallado)
                detalle = await ReporteCajaRepository.GetDetalleTarjetasAsync(filtro.Fecha, filtro.Hasta);
            else
                resumen = await ReporteCajaRepository.GetResumenTarjetasAsync(filtro.Fecha, filtro.Hasta);

            if (consulta != consultaActual) return;
            Construir(filtro, movimientos, resumen, detalle);
            filtroAplicado = filtro;
            fechaProceso = DateTime.Now;
            busqueda = string.Empty;
        }
        catch (Exception ex)
        {
            if (consulta == consultaActual) mensajeError = $"Ocurrió un problema al procesar el reporte: {ex.Message}";
        }
        finally
        {
            if (consulta == consultaActual) cargando = false;
        }
    }

    // Arma las tres secciones a partir de lo que devuelve cada SP
    private void Construir(FiltroDepositosTarjetas filtro, IReadOnlyList<MovimientoCaja> movimientos,
        IReadOnlyList<TarjetaResumen> resumen, IReadOnlyList<TarjetaDetalle> detalle)
    {
        resumenTarjetas = new();
        vouchersPorGrifero = new();
        depositos = new();
        turnosResumen = new();

        switch (filtro.Tipo)
        {
            case TipoReporteDepositos.Todo:
                var porTurno = movimientos.Where(m => m.IDREP == MovimientoCaja.SeccionTarjetaTurno).ToList();
                turnosResumen = porTurno.Select(m => m.CO_TURN ?? 0).Distinct().Order().ToList();
                resumenTarjetas = porTurno
                    .GroupBy(m => (m.CO_TARJ ?? 0, Texto(m.NO_TRAJ)))
                    .OrderBy(g => g.Key.Item1)
                    .Select(g => new FilaTarjeta(g.Key.Item2,
                        g.GroupBy(m => m.CO_TURN ?? 0).ToDictionary(t => t.Key, t => t.Sum(m => m.IM_TOTA ?? 0)),
                        g.Sum(m => m.IM_TOTA ?? 0)))
                    .ToList();

                vouchersPorGrifero = movimientos
                    .Where(m => m.IDREP == MovimientoCaja.SeccionTarjetaGrifero)
                    .GroupBy(m => Texto(m.NO_TRAB, "SIN GRIFERO"))
                    .OrderBy(g => g.Key)
                    .Select(g => new GrupoGrifero(g.Key, g
                        .OrderBy(m => m.CO_TURN).ThenBy(m => m.CO_TARJ).ThenBy(m => m.NU_TARJ)
                        .Select(m => new Voucher(m.FE_TURN, m.CO_TURN ?? 0, Texto(m.NO_TRAJ), Texto(m.NU_TARJ), null, m.IM_TOTA ?? 0))
                        .ToList()))
                    .ToList();

                depositos = movimientos
                    .Where(m => m.IDREP == MovimientoCaja.SeccionDeposito)
                    .Select(m => new FilaDeposito(Texto(m.NO_TRAB), m.CO_TURN, m.IM_SOLE, m.IM_DOLA))
                    .ToList();
                break;

            case TipoReporteDepositos.Tarjetas:
                resumenTarjetas = movimientos
                    .OrderBy(m => m.CO_TARJ)
                    .Select(m => new FilaTarjeta(Texto(m.NO_TRAJ), new Dictionary<int, decimal>(), m.IM_TOTA ?? 0))
                    .ToList();
                break;

            case TipoReporteDepositos.Depositos:
                // QSP_TTFPAG_DOCU_COMB_004 devuelve la moneda en CO_TRAB (1 = soles, 2 = dólares)
                depositos = movimientos
                    .Select(m => new FilaDeposito(m.CO_TRAB == 2 ? "DÓLARES" : "SOLES", null, m.IM_SOLE, m.IM_DOLA))
                    .ToList();
                break;

            case TipoReporteDepositos.ResumenTarjetas when filtro.Detallado:
                turnosResumen = detalle.Select(d => d.CO_TURN).Distinct().Order().ToList();
                resumenTarjetas = detalle
                    .GroupBy(d => (d.CO_TARJ, Texto(d.NO_TARJ)))
                    .OrderBy(g => g.Key.CO_TARJ)
                    .Select(g => new FilaTarjeta(g.Key.Item2,
                        g.GroupBy(d => d.CO_TURN).ToDictionary(t => t.Key, t => t.Sum(d => d.IM_TOTA)),
                        g.Sum(d => d.IM_TOTA)))
                    .ToList();
                vouchersPorGrifero = detalle
                    .GroupBy(d => Texto(d.NOMBRE, "SIN GRIFERO"))
                    .OrderBy(g => g.Key)
                    .Select(g => new GrupoGrifero(g.Key, g
                        .Select(d => new Voucher(d.FECHA, d.CO_TURN, Texto(d.NO_TARJ), Texto(d.NU_TARJ),
                            (Texto(d.TDOC) + " " + Texto(d.NRODOC)).Trim().ToUpperInvariant(), d.IM_TOTA))
                        .ToList()))
                    .ToList();
                break;

            case TipoReporteDepositos.ResumenTarjetas:
                resumenTarjetas = resumen
                    .Select(r => new FilaTarjeta(Texto(r.NO_TARJ), new Dictionary<int, decimal>(), r.TOTAL))
                    .ToList();
                break;
        }

        totalTarjetas = resumenTarjetas.Sum(r => r.Total);
        cantidadVouchers = vouchersPorGrifero.Sum(g => g.Vouchers.Count);
        totalSoles = depositos.Sum(d => d.Soles ?? 0);
        totalDolares = depositos.Sum(d => d.Dolares ?? 0);
    }

    private IEnumerable<GrupoGrifero> GriferosFiltrados
    {
        get
        {
            var texto = busqueda.Trim();
            if (texto.Length == 0) return vouchersPorGrifero;
            return vouchersPorGrifero
                .Select(g => g.Grifero.Contains(texto, StringComparison.OrdinalIgnoreCase)
                    ? g
                    : g with
                    {
                        Vouchers = g.Vouchers.Where(v =>
                            v.Tarjeta.Contains(texto, StringComparison.OrdinalIgnoreCase) ||
                            v.Numero.Contains(texto, StringComparison.OrdinalIgnoreCase) ||
                            (v.Documento ?? string.Empty).Contains(texto, StringComparison.OrdinalIgnoreCase)).ToList()
                    })
                .Where(g => g.Vouchers.Count > 0);
        }
    }

    private static string TituloReporte(FiltroDepositosTarjetas f) => f.Tipo switch
    {
        TipoReporteDepositos.Todo => "DEPÓSITOS / TARJETAS",
        TipoReporteDepositos.Tarjetas => "TARJETAS",
        TipoReporteDepositos.Depositos => "DEPÓSITOS",
        _ => f.Detallado ? "DETALLADO TARJETAS" : "RESUMEN TARJETAS"
    };

    private string SubtituloFiltro(FiltroDepositosTarjetas f)
    {
        if (f.Tipo == TipoReporteDepositos.ResumenTarjetas)
            return "Desde " + f.Fecha.ToString("dd/MM/yyyy") + " hasta " + f.Hasta.ToString("dd/MM/yyyy");
        var texto = "Fecha turno: " + f.Fecha.ToString("dd/MM/yyyy");
        return f.Turno > 0 ? texto + " · Turno " + f.Turno.ToString("00") : texto + " · Todos los turnos";
    }

    private static string Monto(decimal? valor) => valor is null or 0 ? string.Empty : valor.Value.ToString("N2", Cultura);

    private static string Texto(string? valor, string vacio = "") =>
        string.IsNullOrWhiteSpace(valor) ? vacio : valor.Trim();

    private async Task ExportarCsvAsync()
    {
        if (filtroAplicado is null) return;

        var sb = new StringBuilder();
        sb.AppendLine(Csv(nombreEmpresa));
        sb.AppendLine(Csv(TituloReporte(filtroAplicado) + " - " + SubtituloFiltro(filtroAplicado)));

        if (resumenTarjetas.Count > 0)
        {
            sb.AppendLine();
            sb.AppendLine(string.Join(",", new[] { "Tarjeta" }.Concat(turnosResumen.Select(t => "Turno " + t)).Append("Total")));
            foreach (var r in resumenTarjetas)
            {
                sb.AppendLine(string.Join(",", new[] { Csv(r.Tarjeta) }
                    .Concat(turnosResumen.Select(t => r.PorTurno.GetValueOrDefault(t).ToString("0.00", Cultura)))
                    .Append(r.Total.ToString("0.00", Cultura))));
            }
            sb.AppendLine(string.Join(",", new[] { Csv("TOTAL") }
                .Concat(turnosResumen.Select(t => resumenTarjetas.Sum(r => r.PorTurno.GetValueOrDefault(t)).ToString("0.00", Cultura)))
                .Append(totalTarjetas.ToString("0.00", Cultura))));
        }

        if (vouchersPorGrifero.Count > 0)
        {
            sb.AppendLine();
            sb.AppendLine("Grifero,Fecha,Turno,Tarjeta,Voucher,Documento,Importe");
            foreach (var g in vouchersPorGrifero)
            foreach (var v in g.Vouchers)
            {
                sb.AppendLine(string.Join(",", Csv(g.Grifero), Csv(v.Fecha), v.Turno, Csv(v.Tarjeta), Csv(v.Numero),
                    Csv(v.Documento), v.Importe.ToString("0.00", Cultura)));
            }
        }

        if (depositos.Count > 0)
        {
            sb.AppendLine();
            sb.AppendLine("Depositos,Turno,Soles,Dolares");
            foreach (var d in depositos)
            {
                sb.AppendLine(string.Join(",", Csv(d.Descripcion), d.Turno?.ToString() ?? string.Empty,
                    (d.Soles ?? 0).ToString("0.00", Cultura), (d.Dolares ?? 0).ToString("0.00", Cultura)));
            }
        }

        var nombreArchivo = "DepositosTarjetas_" + GrifoContext.GrifoActivoId + "_" + filtroAplicado.Fecha.ToString("yyyyMMdd") + ".csv";
        await JS.InvokeVoidAsync("sisgesDescargarArchivo", nombreArchivo, "text/csv;charset=utf-8", sb.ToString());
    }

    private static string Csv(string? valor) => "\"" + (valor ?? string.Empty).Replace("\"", "\"\"") + "\"";

    private async Task ImprimirAsync() => await JS.InvokeVoidAsync("print");

    private void OnGrifoCambiado()
    {
        _ = InvokeAsync(async () =>
        {
            // Los resultados y los turnos eran de otro grifo
            consultaActual++;
            cargando = false;
            filtroAplicado = null;
            resumenTarjetas.Clear();
            vouchersPorGrifero.Clear();
            depositos.Clear();
            mensajeError = null;
            turno = 0;
            await CargarDatosGrifoAsync();
            StateHasChanged();
        });
    }

    public void Dispose()
    {
        GrifoContext.GrifoCambiado -= OnGrifoCambiado;
    }

    private record FilaTarjeta(string Tarjeta, Dictionary<int, decimal> PorTurno, decimal Total);

    private record Voucher(string? Fecha, int Turno, string Tarjeta, string Numero, string? Documento, decimal Importe);

    private record GrupoGrifero(string Grifero, List<Voucher> Vouchers);

    private record FilaDeposito(string Descripcion, int? Turno, decimal? Soles, decimal? Dolares);
}
