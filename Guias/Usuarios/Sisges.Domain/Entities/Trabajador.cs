using System.ComponentModel.DataAnnotations;
using Sisges.Domain.Common;

namespace Sisges.Domain.Entities;

// Trabajador y usuario del sistema (TMTRAB). Mismas columnas que QSP_TMTRAB_10.
// La clave NO viaja en esta clase: se ingresa aparte (ClaveNueva) y se guarda cifrada.
public class Trabajador : IValidatableObject
{
    public const string Activo = "N";      // TMTRAB.ST_TRAB
    public const string Inactivo = "A";
    public const string TipoGrifero = "G"; // TMTRAB.TIPO_TRAB
    public const string TipoEmpleado = "E";

    public int CO_TRAB { get; set; }

    [Required(ErrorMessage = "Ingresa los apellidos."), StringLength(50)]
    public string DE_APEL { get; set; } = string.Empty;

    [Required(ErrorMessage = "Ingresa los nombres."), StringLength(30)]
    public string NO_TRAB { get; set; } = string.Empty;

    [Required(ErrorMessage = "Ingresa el DNI.")]
    public string NU_DNI { get; set; } = string.Empty;

    public DateTime FE_NACI { get; set; } = DateTime.Today.AddYears(-18);

    [StringLength(50)] public string? DE_DIRE { get; set; }
    [StringLength(15), RegularExpression(@"^[0-9 +()\-]*$", ErrorMessage = "Solo números, espacios y + - ( ).")]
    public string? NU_TEL1 { get; set; }
    [StringLength(15), RegularExpression(@"^[0-9 +()\-]*$", ErrorMessage = "Solo números, espacios y + - ( ).")]
    public string? NU_TEL2 { get; set; }

    [Required(ErrorMessage = "Selecciona el distrito.")]
    public string CO_GEOG { get; set; } = string.Empty;

    public string TIPO_TRAB { get; set; } = TipoGrifero;

    [Required(ErrorMessage = "Ingresa el código de usuario."),
     StringLength(8, MinimumLength = 5, ErrorMessage = "El usuario debe tener entre 5 y 8 caracteres."),
     RegularExpression("^[A-Za-z0-9]+$", ErrorMessage = "El usuario solo admite letras y números.")]
    public string CO_USUA { get; set; } = string.Empty;

    public int CO_PERF { get; set; }
    public string ST_TRAB { get; set; } = Activo;

    // Permisos especiales (TMTRAB.ST_MODI, ST_ANUL...). En la base son 0 / 1.
    public bool PermisoModificar { get; set; }
    public bool PermisoAnular { get; set; }
    public bool PermisoDuplicado { get; set; }
    public bool PermisoVentaCredito { get; set; }
    public bool PermisoAdministrador { get; set; }

    // Valores con que se cargó el registro. Muchos trabajadores antiguos tienen DNI o fecha de nacimiento
    // inválidos (en Gasocentro 11 y 34 de 42 activos): solo se validan si se cambian, para poder editarlos.
    public string? DniCargado { get; set; }
    public DateTime? NacimientoCargado { get; set; }

    // Solo para la pantalla: vacía al editar = se conserva la clave actual
    public string? ClaveNueva { get; set; }
    public string? ClaveConfirmacion { get; set; }

    public bool EstaActivo => ST_TRAB == Activo;
    public string NombreCompleto => (DE_APEL + " " + NO_TRAB).Trim();

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (NU_DNI.Trim() != DniCargado && !DocumentoIdentidad.EsDniValido(NU_DNI.Trim()))
            yield return new ValidationResult("El DNI debe tener 8 dígitos.", new[] { nameof(NU_DNI) });

        if (FE_NACI.Date != NacimientoCargado?.Date && FE_NACI.Date > DateTime.Today.AddYears(-16))
            yield return new ValidationResult("Revisa la fecha de nacimiento (mínimo 16 años).", new[] { nameof(FE_NACI) });

        if (CO_PERF <= 0)
            yield return new ValidationResult("Selecciona el perfil.", new[] { nameof(CO_PERF) });

        // Al registrar la clave es obligatoria; al editar solo si se escribe una nueva
        var clave = ClaveNueva?.Trim() ?? string.Empty;
        var esNuevo = CO_TRAB == 0;
        if (esNuevo || clave.Length > 0)
        {
            if (clave.Length < ClaveSisges.LargoMinimo || clave.Length > ClaveSisges.LargoMaximo)
                yield return new ValidationResult($"La clave debe tener entre {ClaveSisges.LargoMinimo} y {ClaveSisges.LargoMaximo} caracteres.", new[] { nameof(ClaveNueva) });
            else if (!clave.All(char.IsAsciiLetterOrDigit))
                yield return new ValidationResult("La clave solo admite letras y números.", new[] { nameof(ClaveNueva) });

            if (!string.Equals(clave, ClaveConfirmacion?.Trim(), StringComparison.OrdinalIgnoreCase))
                yield return new ValidationResult("La confirmación no coincide con la clave.", new[] { nameof(ClaveConfirmacion) });
        }
    }
}

// Fila de la búsqueda (QSP_TMTRAB_02 no trae el usuario: se consulta aparte)
public class TrabajadorResumen
{
    public int CO_TRAB { get; set; }
    public string APE_NOM { get; set; } = string.Empty;
    public string ESTADO { get; set; } = string.Empty;   // ACTIVO / NO ACTIVO
    public string? CO_USUA { get; set; }
    public string? TIPO_TRAB { get; set; }
    public string? NO_PERF { get; set; }
}

// Distrito de TTUBIC_GEOG (el original solo ofrece Lima Metropolitana: departamento 15, provincia 01)
public record Distrito(string CO_GEOG, string CO_DIST, string NO_GEOG);
