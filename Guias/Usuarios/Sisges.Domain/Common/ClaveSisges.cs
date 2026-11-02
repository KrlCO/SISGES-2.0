using System.Security.Cryptography;
using System.Text;

namespace Sisges.Domain.Common;

// Cifrado de claves de TMTRAB.CO_PASS, idéntico a SgClave.clsClave.EncryptString del VB6 (LibSegClave).
// NO es seguro (es reversible y la clave está fija en el código), pero el VB6 y la web deben leer
// las mismas claves mientras convivan. Nunca se descifra ni se muestra una clave guardada.
public static class ClaveSisges
{
    private const string LlaveVb6 = "soyuzperu";

    // Chr$/Asc del VB6 trabajan con la página de códigos de Windows 1252 (la misma de la columna varchar)
    private static readonly Encoding Windows1252;

    public const int LargoMinimo = 5;      // ValidarDatos del original
    public const int LargoMaximo = 10;     // CO_PASS es VARCHAR(10) y el cifrado no cambia el largo

    static ClaveSisges()
    {
        Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);
        Windows1252 = Encoding.GetEncoding(1252);
    }

    // El VB6 escribe la clave en MAYÚSCULAS (ConvertMAYUSC) antes de cifrarla
    public static string Normalizar(string clave) => clave.Trim().ToUpperInvariant();

    public static string Cifrar(string clave)
    {
        var texto = Windows1252.GetBytes(Normalizar(clave));
        var llave = Windows1252.GetBytes(LlaveVb6);
        var resultado = new byte[texto.Length];

        // Mismo recorrido de la llave que el VB6: j = IIf(j + 1 >= n, 1, j + 1), arrancando en 0.
        // (Nunca usa el último carácter de la llave; se respeta para que el resultado sea idéntico.)
        var j = 0;
        for (var i = 0; i < texto.Length; i++)
        {
            j = j + 1 >= llave.Length ? 1 : j + 1;
            var valor = texto[i] + llave[j - 1];
            if (valor > 255) valor -= 255;
            resultado[i] = (byte)valor;
        }
        return Windows1252.GetString(resultado);
    }

    // Clave aleatoria para el usuario que se desactiva: nadie la conoce, así no puede volver a entrar
    public static string Aleatoria()
    {
        const string caracteres = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        return new string(Enumerable.Range(0, LargoMaximo)
            .Select(_ => caracteres[RandomNumberGenerator.GetInt32(caracteres.Length)])
            .ToArray());
    }
}
