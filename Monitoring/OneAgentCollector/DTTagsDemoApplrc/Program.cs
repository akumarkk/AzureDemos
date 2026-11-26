using log4net;

var builder = WebApplication.CreateBuilder(args);

// Must be set before the log4net provider loads log4net.config.
GlobalContext.Properties["LogDir"] = Path.Combine(builder.Environment.ContentRootPath, "logs");
GlobalContext.Properties["primary_tags.app"] = Environment.GetEnvironmentVariable("DT_TAGS_APP") ?? "";
GlobalContext.Properties["primary_tags.team"] = Environment.GetEnvironmentVariable("DT_TAGS_TEAM") ?? "";
GlobalContext.Properties["dt_cluster_id"] = Environment.GetEnvironmentVariable("DT_CLUSTER_ID") ?? "";

builder.Logging.AddLog4Net("log4net.config");

var app = builder.Build();

app.MapGet("/", (ILogger<Program> logger) =>
{
    logger.LogInformation("Handled request to /");
    return "Hello World!";
});

app.MapGet("/env", (ILogger<Program> logger) =>
{
    logger.LogInformation("Handled request to /env");
    return Environment.GetEnvironmentVariables()
        .Cast<System.Collections.DictionaryEntry>()
        .Where(e => ((string)e.Key).StartsWith("DT_", StringComparison.OrdinalIgnoreCase))
        .Where(e => !((string)e.Key).Contains("TOKEN", StringComparison.OrdinalIgnoreCase))
        .OrderBy(e => (string)e.Key, StringComparer.OrdinalIgnoreCase)
        .ToDictionary(e => (string)e.Key, e => e.Value?.ToString());
});

app.Logger.LogInformation("Application started");

app.Run();
