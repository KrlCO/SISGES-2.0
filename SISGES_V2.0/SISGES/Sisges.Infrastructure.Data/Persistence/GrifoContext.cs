using Sisges.Domain.Common.Interfaces;

namespace Sisges.Infrastructure.Data.Persistence;

public class GrifoContext : IGrifoContext
{
    private string _grifoActivoId = string.Empty;
    private List<string> _grifosPermitidos = new();
    
    public string GrifoActivoId => _grifoActivoId;
    public IReadOnlyList<string> GrifosPermitidos => _grifosPermitidos.AsReadOnly();

    public event Action? GrifoCambiado;

    public void EstablecerGrifoActivo(string grifoId)
    {
        if (_grifosPermitidos.Count > 0 && !_grifosPermitidos.Contains("*") && !_grifosPermitidos.Contains(grifoId))
        {
            throw new UnauthorizedAccessException($"No tienes autorización para acceder al grifo '{grifoId}'.");
        }
        if (string.Equals(_grifoActivoId, grifoId, StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        _grifoActivoId = grifoId;
        GrifoCambiado?.Invoke();
    }

    public void ConfigurarPermisos(string usuario, IReadOnlyList<string> grifosPermitidos)
    {
        _grifosPermitidos = grifosPermitidos.ToList();
        
        // Si no hay grifo seleccionado aún, seleccionar el primero al que tenga acceso
        if (string.IsNullOrEmpty(_grifoActivoId) && _grifosPermitidos.Count > 0)
        {
            _grifoActivoId = _grifosPermitidos[0] == "*" ? "Grifo_01" : _grifosPermitidos[0];
        }
    }
}
