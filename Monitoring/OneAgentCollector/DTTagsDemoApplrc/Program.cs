var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => "Hello World!");

app.MapGet("/env", () => Environment.GetEnvironmentVariables()
    .Cast<System.Collections.DictionaryEntry>()
    .Where(e => ((string)e.Key).StartsWith("DT_", StringComparison.OrdinalIgnoreCase))
    .Where(e => !((string)e.Key).Contains("TOKEN", StringComparison.OrdinalIgnoreCase))
    .OrderBy(e => (string)e.Key, StringComparer.OrdinalIgnoreCase)
    .ToDictionary(e => (string)e.Key, e => e.Value?.ToString()));


app.Run();
