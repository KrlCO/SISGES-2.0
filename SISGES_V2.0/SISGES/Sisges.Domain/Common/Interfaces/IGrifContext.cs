namespace Sisges.Domain.Common.Interfaces;

public interface IGrifContext
{
    string GrifoActivoId { get; }

    // Se dispara cuando cambia el grifo activo (las pantallas abiertas deben recargar sus datos)
    event Action? GrifoCambiado;

    void EstablecerGrifoActivo(string grifoId);
    IReadOnlyList<string> GrifosPermitidos { get; }
    void ConfigurarPermisos(string usuario, IReadOnlyList<string> grifosPermitidos);
}

// Interfaz canónica con 'o' que hereda de IGrifContext
public interface IGrifoContext : IGrifContext
{
}
