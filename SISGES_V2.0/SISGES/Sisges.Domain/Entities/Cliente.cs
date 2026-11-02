using System.ComponentModel.DataAnnotations;
using Sisges.Domain.Common;

namespace Sisges.Domain.Entities;

public enum TipoPersona
{
    Natural,
    Juridica
}

public class Cliente: IValidatableObject
{
    private const string Telefono = @"^[0-9 +()\-]*$";
    private const string MensajeTelefono = "Solo números, espacios y + - ( ).";

    public int CO_CLIE {get; set;}
    public TipoPersona TipoPersona{get; set;} =  TipoPersona.Juridica;
    
    //Identificacion
    [StringLength(11)] public string? NU_RUC {get; set;}
    [StringLength(10)] public string? NU_DOCU_IDEN {get; set;} //DNI
    [StringLength(50)] public string? NU_RSOC {get; set;}
    [StringLength(30)] public string? NO_CLIE {get; set;}
    [StringLength(50)] public string? DE_APEL_PATE { get; set; }
    [StringLength(50)] public string? DE_APEL_MATE { get; set; }
    [StringLength(50)] public string? NO_REPR_LEGA { get; set; }
    [StringLength(50)] public string? DE_GIRO_EMPR { get; set; }
    public DateTime FE_INGR { get; set; } = DateTime.Today;
    public int CO_TCLI { get; set; } = 1;
    public int CO_TEMI { get; set; } = 3;
    
    // ── Dirección y comunicación ──
    [StringLength(100)] public string? DE_DOMI { get; set; }
    [StringLength(100)] public string? DE_REFE { get; set; }
    // En TCCLIE el ubigeo se guarda con 8 dígitos (ej. 15013515)
    [StringLength(8), RegularExpression(@"^\d*$", ErrorMessage = "El ubigeo solo tiene dígitos.")]
    public string? CO_GEOG { get; set; }
    [StringLength(15), RegularExpression(Telefono, ErrorMessage = MensajeTelefono)] public string? NU_TEL1 { get; set; }
    [StringLength(15), RegularExpression(Telefono, ErrorMessage = MensajeTelefono)] public string? NU_TEL2 { get; set; }
    [StringLength(15), RegularExpression(Telefono, ErrorMessage = MensajeTelefono)] public string? NU_FAX { get; set; }
    [StringLength(30), EmailAddress] public string? DE_MAIL { get; set; }

    // ── Persona de contacto ──
    [StringLength(50)] public string? NO_CONT_CLIE { get; set; }
    [StringLength(50)] public string? DE_APEL_PATE_CONT { get; set; }
    [StringLength(50)] public string? DE_APEL_MATE_CONT { get; set; }
    [StringLength(50)] public string? DE_CARG_CONT { get; set; }
    [StringLength(15), RegularExpression(Telefono, ErrorMessage = MensajeTelefono)] public string? NU_TELE_CONT { get; set; }
    [StringLength(50), EmailAddress] public string? DE_CORR_CONT { get; set; }
    [StringLength(100)] public string? DE_OBSI_CONT { get; set; }

    // No se editan en pantalla: al modificar se devuelven tal como estaban (SP_TCCLIE_U01 sobrescribe todo)
    public string? DE_OBSI { get; set; }
    public string? DE_DOMI_CONT { get; set; }

    // ── Crédito ──
    public bool ControlCredito { get; set; }                            // CR_CRET = 'S' / 'N'
    [Range(0, 9_999_999)] public decimal IM_LIMI_CRED { get; set; }
    [Range(0, 99_999)] public decimal IM_SOBR_GIRO { get; set; }
    [Range(0, 99_999)] public decimal IM_MONT_MINI { get; set; }

    //Nombre que se imprime en los CPE. En persona natural ahora se arma "Apellidos Paterno, materno y nombres" como en los cliente con RUC 10
    public string RazonSocialParaGrabar() => TipoPersona == TipoPersona.Juridica
        ? (NU_RSOC ?? string.Empty).Trim().ToUpperInvariant()
        : string.Join(' ', new[] { DE_APEL_PATE, DE_APEL_MATE, NO_CLIE }
                .Where(p => !string.IsNullOrWhiteSpace(p))
                .Select(p => p!.Trim()))
            .ToUpperInvariant();
    
    
    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (TipoPersona == TipoPersona.Juridica)
        {
            if(!DocumentoIdentidad.EsRucValido(NU_RUC))
                yield return new ValidationResult("RUC invalido: 11 digitos y digito verificador.", new[] {nameof(NU_RUC)});
            
            if(string.IsNullOrWhiteSpace(NU_RSOC))
                yield return new ValidationResult("Ingresa la razón social.", new[]{nameof(NU_RSOC)});
            
        }
        else
        {
            if(!DocumentoIdentidad.EsDniValido(NU_DOCU_IDEN))
                yield return new ValidationResult("El DNI debe tener 8 digitos.", new[]{nameof(NU_DOCU_IDEN)});
            if (string.IsNullOrWhiteSpace(DE_APEL_PATE))
                yield return new ValidationResult("Ingrese el apellido paterno.", new[] { nameof(DE_APEL_PATE) });

            if (string.IsNullOrWhiteSpace(DE_APEL_MATE))
                yield return new ValidationResult("Ingrese el apellido materno.", new[] { nameof(DE_APEL_MATE) });

            if (string.IsNullOrWhiteSpace(NO_CLIE))
                yield return new ValidationResult("Ingrese el nombre.", new[] { nameof(NO_CLIE) });
            
            if(RazonSocialParaGrabar().Length > 50)
                yield return new ValidationResult("Apellidos y nombres no deben superar los 50 caracteres en total.", new[]{nameof(NO_CLIE)});
        }
        if(CO_TCLI <= 0)
            yield return new ValidationResult("Selecciona el tipo de cliente.", new []{nameof(CO_TCLI)});
        if(CO_TEMI <= 0)
            yield return new ValidationResult("Seleccione el tipo de emision.", new[]{nameof(CO_TEMI)});
       
    }
}