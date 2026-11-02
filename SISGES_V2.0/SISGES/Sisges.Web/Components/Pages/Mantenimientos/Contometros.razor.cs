using Sisges.Domain.Entities;

namespace Sisges.Web.Components.Pages.Mantenimientos;

public partial class Contometros
{
    private enum Modo { Consulta, Nuevo, Modificar }

    private Modo modo = Modo.Consulta;
    private bool EnEdicion => modo != Modo.Consulta;

    // Catálogos
    private IReadOnlyList<OpcionCatalogo> turnos = Array.Empty<OpcionCatalogo>();
    private IReadOnlyList<OpcionCatalogo> griferos = Array.Empty<OpcionCatalogo>();
    private (int Minimo, int Maximo) rangoTurnos = (1, 3);
    private TurnoActual? turnoActivo;

    // Estado
    private ContometroTurno? ultimo;                       // último turno registrado en TCCONT
    private (DateOnly Fecha, int Turno) siguiente;         // el que propone "Nuevo"
    private ContometroTurno? mostrado;                     // el que se ve en la grilla (consulta o modificar)
    private DateOnly fechaConsulta = DateOnly.FromDateTime(DateTime.Today);
    private int turnoConsulta = 1;
    private DateOnly fechaEdicion;
    private int turnoEdicion;
    private List<FilaContometro> filas = new();

    private bool cambioPrecio;
    private bool avisoTurnoAbierto;
    private bool cargando = true;
    private bool guardando;
    private bool confirmandoGuardar;
    private bool confirmandoEliminar;
    private List<string> errores = new();
    private string? mensajeError;
    private string? mensajeExito;
    private int consultaActual;    // descarta respuestas de una consulta anterior o de otro grifo

    private bool EsUltimo => mostrado is not null && ultimo is not null && mostrado.CO_CONT == ultimo.CO_CONT;

    private string TituloGrilla => modo switch
    {
        Modo.Nuevo => "Nuevo registro · " + fechaEdicion.ToString("dd/MM/yyyy") + " turno " + turnoEdicion,
        Modo.Modificar => "Modificando · " + fechaEdicion.ToString("dd/MM/yyyy") + " turno " + turnoEdicion,
        _ => mostrado is null ? string.Empty : "Turno " + mostrado.FechaTurno.ToString("dd/MM/yyyy") + " · " + mostrado.Turno
    };

    private IEnumerable<ResumenContometro> Resumen => filas
        .GroupBy(f => f.Producto)
        .OrderBy(g => g.Key)
        .Select(g => new ResumenContometro(g.Key, g.Sum(f => f.Galones), Math.Round(g.Sum(f => f.ImporteExacto), 2)));

    // Como el original: el total se suma sin redondear cada línea y se redondea al final
    private decimal TotalImporte => Math.Round(filas.Sum(f => f.ImporteExacto), 2);

    protected override async Task OnInitializedAsync()
    {
        GrifoContext.GrifoCambiado += OnGrifoCambiado;
        await CargarAsync();
    }

    private async Task CargarAsync()
    {
        var consulta = ++consultaActual;
        cargando = true;
        try
        {
            turnos = await AdminDocumentosRepository.GetTurnosAsync();
            griferos = await ContometroRepository.GetGriferosAsync();
            rangoTurnos = await ContometroRepository.GetRangoTurnosAsync();
            turnoActivo = await AdminDocumentosRepository.GetTurnoActualAsync();
            await CargarUltimoAsync();
            if (consulta != consultaActual) return;

            // Abre mostrando el último turno registrado, como referencia
            if (ultimo is not null)
            {
                fechaConsulta = ultimo.FechaTurno;
                turnoConsulta = ultimo.Turno;
                await MostrarAsync(ultimo);
            }
        }
        catch (Exception ex)
        {
            if (consulta == consultaActual) mensajeError = $"No se pudieron cargar los contómetros: {ex.Message}";
        }
        finally
        {
            if (consulta == consultaActual) cargando = false;
        }
    }

    private async Task CargarUltimoAsync()
    {
        ultimo = await ContometroRepository.GetUltimoAsync();
        siguiente = ultimo is null
            ? (DateOnly.FromDateTime(turnoActivo?.Fecha ?? DateTime.Today), rangoTurnos.Minimo)
            : TurnosContometro.Siguiente(ultimo.FechaTurno, ultimo.Turno, rangoTurnos.Minimo, rangoTurnos.Maximo);
    }

    private async Task MostrarAsync(ContometroTurno contometro)
    {
        mostrado = contometro;
        var lecturas = await ContometroRepository.GetLecturasAsync(contometro);
        filas = lecturas.Select(FilaContometro.DesdeGuardada).ToList();
    }

    private async Task ConsultarAsync()
    {
        LimpiarMensajes();
        cargando = true;
        try
        {
            var encontrado = await ContometroRepository.GetPorTurnoAsync(fechaConsulta, turnoConsulta);
            if (encontrado is null)
            {
                mostrado = null;
                filas = new();
            }
            else
            {
                await MostrarAsync(encontrado);
            }
        }
        catch (Exception ex)
        {
            mensajeError = $"No se pudo consultar: {ex.Message}";
        }
        finally
        {
            cargando = false;
        }
    }

    // "Nuevo" del original: siguiente turno al último registrado; la lectura inicial es la final del anterior
    private async Task NuevoAsync()
    {
        LimpiarMensajes();
        cargando = true;
        try
        {
            await CargarUltimoAsync();
            IReadOnlyList<ContometroMecanico> base_;
            if (ultimo is null)
            {
                // Primer registro de la estación: "Valores iniciales" del original (QSP_TMCONT_06)
                base_ = await ContometroRepository.GetValoresInicialesAsync();
            }
            else
            {
                base_ = await ContometroRepository.GetLecturasAsync(ultimo);
            }

            fechaEdicion = siguiente.Fecha;
            turnoEdicion = siguiente.Turno;
            filas = base_.Select(FilaContometro.ParaNuevoTurno).ToList();
            mostrado = null;
            modo = Modo.Nuevo;
            avisoTurnoAbierto = EsTurnoAbierto(fechaEdicion, turnoEdicion);
        }
        catch (Exception ex)
        {
            mensajeError = $"No se pudo preparar el nuevo registro: {ex.Message}";
        }
        finally
        {
            cargando = false;
        }
    }

    private void Modificar()
    {
        if (!EsUltimo) return;
        LimpiarMensajes();
        fechaEdicion = mostrado!.FechaTurno;
        turnoEdicion = mostrado.Turno;
        modo = Modo.Modificar;
        avisoTurnoAbierto = EsTurnoAbierto(fechaEdicion, turnoEdicion);
    }

    private async Task CancelarEdicionAsync()
    {
        LimpiarMensajes();
        modo = Modo.Consulta;
        cambioPrecio = false;
        if (ultimo is not null) await MostrarAsync(mostrado ?? ultimo);
        else filas = new();
    }

    // Para las mangueras que no vendieron: final = inicial
    private void CopiarInicialesSinVenta()
    {
        confirmandoGuardar = false;
        foreach (var f in filas.Where(f => f.Final is null)) f.Final = f.Inicial;
    }

    private async Task GuardarAsync()
    {
        mensajeError = null;
        errores = Validar();
        if (errores.Count > 0)
        {
            confirmandoGuardar = false;
            return;
        }
        if (!confirmandoGuardar)
        {
            confirmandoGuardar = true;
            return;
        }

        guardando = true;
        try
        {
            var lecturas = filas.Select(f => f.ALectura()).ToList();
            if (modo == Modo.Nuevo)
            {
                await ContometroRepository.RegistrarAsync(fechaEdicion, turnoEdicion, lecturas);
                mensajeExito = "Contómetros del " + fechaEdicion.ToString("dd/MM/yyyy") + " turno " + turnoEdicion + " registrados.";
            }
            else
            {
                await ContometroRepository.ModificarAsync(mostrado!, lecturas);
                mensajeExito = "Contómetros del " + fechaEdicion.ToString("dd/MM/yyyy") + " turno " + turnoEdicion + " actualizados.";
            }

            modo = Modo.Consulta;
            cambioPrecio = false;
            confirmandoGuardar = false;
            await CargarUltimoAsync();
            fechaConsulta = fechaEdicion;
            turnoConsulta = turnoEdicion;
            if (ultimo is not null) await MostrarAsync(ultimo);
        }
        catch (Exception ex)
        {
            mensajeError = $"No se pudieron guardar los contómetros: {ex.Message}";
            confirmandoGuardar = false;
        }
        finally
        {
            guardando = false;
        }
    }

    private async Task EliminarAsync()
    {
        if (!EsUltimo) return;
        LimpiarMensajes(conservarConfirmacion: true);
        if (!confirmandoEliminar)
        {
            confirmandoEliminar = true;
            return;
        }

        guardando = true;
        try
        {
            var eliminado = mostrado!;
            await ContometroRepository.EliminarAsync(eliminado.CO_CONT);
            mensajeExito = "Se eliminaron los contómetros del " + eliminado.FechaTurno.ToString("dd/MM/yyyy") + " turno " + eliminado.Turno + ".";
            confirmandoEliminar = false;
            await CargarUltimoAsync();
            mostrado = null;
            filas = new();
            if (ultimo is not null)
            {
                fechaConsulta = ultimo.FechaTurno;
                turnoConsulta = ultimo.Turno;
                await MostrarAsync(ultimo);
            }
        }
        catch (Exception ex)
        {
            mensajeError = $"No se pudo eliminar: {ex.Message}";
            confirmandoEliminar = false;
        }
        finally
        {
            guardando = false;
        }
    }

    private List<string> Validar()
    {
        var lista = new List<string>();
        foreach (var f in filas)
        {
            var n = "Lado " + f.Lado + " manguera " + f.Manguera + ": ";
            if (f.Final is null) lista.Add(n + "ingresa la lectura final.");
            else if (f.Final < f.Inicial) lista.Add(n + "la lectura final es menor que la inicial.");
            if ((f.Calibracion ?? 0) < 0) lista.Add(n + "la calibración no puede ser negativa.");
            else if (f.Final is not null && f.Final >= f.Inicial && f.Galones < 0) lista.Add(n + "la calibración es mayor que el volumen vendido.");
            if (f.Precio <= 0) lista.Add(n + "el precio debe ser mayor a 0.");
            if (f.Grifero <= 0) lista.Add(n + "selecciona el grifero.");
        }
        return lista;
    }

    private bool EsTurnoAbierto(DateOnly fecha, int turno) =>
        turnoActivo is not null && DateOnly.FromDateTime(turnoActivo.Fecha) == fecha && turnoActivo.Turno == turno;

    private void LimpiarMensajes(bool conservarConfirmacion = false)
    {
        mensajeError = null;
        mensajeExito = null;
        errores = new();
        confirmandoGuardar = false;
        if (!conservarConfirmacion) confirmandoEliminar = false;
    }

    private void OnGrifoCambiado()
    {
        _ = InvokeAsync(async () =>
        {
            // Los contómetros, griferos y turnos son de cada base de datos
            modo = Modo.Consulta;
            cambioPrecio = false;
            LimpiarMensajes();
            ultimo = null;
            mostrado = null;
            filas = new();
            await CargarAsync();
            StateHasChanged();
        });
    }

    public void Dispose()
    {
        GrifoContext.GrifoCambiado -= OnGrifoCambiado;
    }

    // Fila editable de la grilla
    private class FilaContometro
    {
        private ContometroMecanico origen = new();

        public int Lado => origen.CO_LADO;
        public int Manguera => origen.CO_MANG;
        public string Producto => origen.NO_PROD;
        public decimal Inicial { get; private set; }
        public decimal? Final { get; set; }
        public decimal? Calibracion { get; set; }
        public decimal Precio { get; set; }
        public int Grifero { get; set; }
        public string? NombreGrifero => origen.NombTrab;

        public decimal Galones => Final is null ? 0 : Math.Round(Final.Value - Inicial - (Calibracion ?? 0), 3);
        public decimal ImporteExacto => Galones * Precio;
        public decimal Importe => Math.Round(ImporteExacto, 2);

        // Registro ya guardado (consulta o modificar)
        public static FilaContometro DesdeGuardada(ContometroMecanico l) => new()
        {
            origen = l,
            Inicial = l.IM_LECI,
            Final = l.IM_LECF,
            Calibracion = l.IM_CALI,
            Precio = l.IM_PRE1,
            Grifero = l.CO_TRAB
        };

        // Turno nuevo: inicial = final del turno anterior; la final se deja vacía para que se ingrese
        public static FilaContometro ParaNuevoTurno(ContometroMecanico anterior) => new()
        {
            origen = anterior,
            Inicial = anterior.IM_LECF,
            Final = null,
            Calibracion = 0,
            Precio = anterior.IM_PRE1,
            Grifero = anterior.CO_TRAB
        };

        public ContometroMecanico ALectura() => new()
        {
            CO_LADO = origen.CO_LADO,
            CO_MANG = origen.CO_MANG,
            NO_PROD = origen.NO_PROD,
            CO_PROD = origen.CO_PROD,
            CO_PVEN = origen.CO_PVEN,
            CO_ISLA = origen.CO_ISLA,
            CO_SURT = origen.CO_SURT,
            CO_TRAB = Grifero,
            IM_PRE1 = Math.Round(Precio, 2),
            IM_LECI = Inicial,
            IM_LECF = Final ?? Inicial,
            IM_CALI = Calibracion ?? 0
        };
    }
}
