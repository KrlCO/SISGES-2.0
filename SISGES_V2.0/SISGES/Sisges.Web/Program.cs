using Sisges.Web.Components;
using Sisges.Domain.Common.Interfaces;
using Sisges.Infrastructure.Data.Persistence;
using Sisges.Infrastructure.Data.Repositories;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

// Contexto de grifo por usuario (ambas interfaces soportadas)
builder.Services.AddScoped<GrifoContext>();
builder.Services.AddScoped<IGrifoContext>(sp => sp.GetRequiredService<GrifoContext>());
builder.Services.AddScoped<IGrifContext>(sp => sp.GetRequiredService<GrifoContext>());
builder.Services.AddScoped<IClienteRepository, ClienteRepository>();
builder.Services.AddScoped<IAdminDocumentosRepository, AdminDocumentosRepository>();
builder.Services.AddScoped<IFormaPagoRepository, FormaPagoRepository>();
builder.Services.AddScoped<IReporteContometroRepository,  ReporteContometroRepository>();
builder.Services.AddScoped<IContometroMecanicoRepository, ContometroMecanicoRepository>();

// Fábrica de Conexiones dinámica
builder.Services.AddScoped<ISqlConnectionFactory, SqlConnectionFactory>();

// Repositorios
builder.Services.AddScoped<IEmpresaRepository, EmpresaRepository>();
builder.Services.AddScoped<IReporteFiscalRepository, ReporteFiscalRepository>();
builder.Services.AddScoped<IReporteCajaRepository, ReporteCajaRepository>();
builder.Services.AddScoped<IDashboardRepository, DashboardRepository>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseStaticFiles();
app.UseAntiforgery();

app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.Run();
