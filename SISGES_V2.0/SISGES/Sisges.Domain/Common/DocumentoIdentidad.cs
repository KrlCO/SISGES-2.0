namespace Sisges.Domain.Common;

public static class DocumentoIdentidad
{
    private static readonly int[] PesosRuc = { 5, 4, 3, 2, 7, 6, 5, 4, 3, 2 };
    private static readonly string[] PrefijosRuc = { "10", "15", "20"}; //Se esta dejando fuera 16 y 17 ya que actualmente SUNAT se esta asignando. 

    public static bool EsRucValido(string? ruc)
    {
        if(ruc is null || ruc.Length != 11 || !ruc.All(char.IsAsciiDigit))
        return false;
        if (!PrefijosRuc.Any(ruc.StartsWith))
            return false;
        var suma = 0;
        for (var i = 0; i < 10; i++)
        {
            suma += (ruc[i] - '0') * PesosRuc[i];
        }

        var digito = 11 - suma % 11;
        if (digito == 10) digito = 0;
        if(digito ==11) digito = 1;
        
        return digito == ruc[10] -'0';
    }

    public static bool EsDniValido(string? dni)
    {
        if (dni is not { Length: 8 } || !dni.All(char.IsAsciiDigit))
            return false;
        if (dni[0] == '5')
            return false;
        if (dni.Distinct().Count() == 1)
            return false; 
        
        return true;
    } 
}
    