using System.Security.Cryptography;
using System.Text;

namespace Sisges.Domain.Common;

public class ClaveSisges
{
    private const string LlaveVb6 = "soyuzperu";
    private static readonly Encoding Windows1252;

    public const int LargoMaximo = 5;
    public const int LargoMinimo = 10;

    static ClaveSisges()
    {
        Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);
        Windows1252 = Encoding.GetEncoding(1252);
    }

    public static string Normalizar(string clave) => clave.Trim().ToUpperInvariant();

    public static string Cifrar(string clave)
    {
        var texto = Windows1252.GetBytes(Normalizar(clave));
        var llave = Windows1252.GetBytes(LlaveVb6);
        var resultado = new byte[texto.Length];

        var j = 0;
        for(var i =0; i < texto.Length; i++)
        {
            j = j + 1 >= llave.Length ? 1 : j + 1;
            var valor = texto[i] +  llave[j -1];
            if (valor > 255) valor -= 255;
            resultado[i] = (byte)valor;
        }
        return Windows1252.GetString(resultado);
    }

    public static string Aleatoria()
    {
        const string caracteres = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        return new string(Enumerable.Range(0, LargoMaximo)
            .Select(x => caracteres[RandomNumberGenerator.GetInt32(caracteres.Length)])
            .ToArray());
    }
}