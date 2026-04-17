using Microsoft.AspNetCore.OpenApi; // For MapOpenApi
using Scalar.AspNetCore;
using Azure.Identity;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Configuration.AzureAppConfiguration;

var builder = WebApplication.CreateBuilder(args);

Console.WriteLine($"env : {Environment.GetEnvironmentVariable("AZURE_Travel_APPCONFIG")}");
var appConfigEndpoint = Environment.GetEnvironmentVariable("AZURE_Travel_APPCONFIG") ?? "https://craft-travel-config.azconfig.io";
if (!string.IsNullOrEmpty(appConfigEndpoint))
{
    Console.WriteLine($"Attempting to connect to Azure App Configuration: {appConfigEndpoint}");
    try
    {
        builder.Configuration.AddAzureAppConfiguration(options =>
        {
            options.Connect(new Uri(appConfigEndpoint), new DefaultAzureCredential());
        });
        Console.WriteLine("Successfully connected to Azure App Configuration.");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Failed to connect to Azure App Configuration: {ex.Message}");
    }
}
else
{
    Console.WriteLine("AZURE_Travel_APPCONFIG environment variable not set. Skipping Azure App Configuration.");
}

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();
builder.Services.AddHealthChecks();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();

    var stripePaymentUrl = app.Configuration["stripepaymenturl"];
    var copilotChatUrl = app.Configuration["copilotchaturl"];

    Console.WriteLine($"Stripe Payment URL: {stripePaymentUrl}");
    Console.WriteLine($"Copilot Chat URL: {copilotChatUrl}");
}

app.MapHealthChecks("/health");
app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
