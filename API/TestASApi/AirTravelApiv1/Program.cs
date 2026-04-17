using Microsoft.AspNetCore.OpenApi; // For MapOpenApi
using Scalar.AspNetCore;
using Azure.Identity;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Configuration.AzureAppConfiguration;

var builder = WebApplication.CreateBuilder(args);

var appConfigEndpoint = Environment.GetEnvironmentVariable("AZURE_Travel_APPCONFIG");
if (!string.IsNullOrEmpty(appConfigEndpoint))
{
    builder.Configuration.AddAzureAppConfiguration(options =>
    {
        options.Connect(new Uri(appConfigEndpoint), new DefaultAzureCredential());
    });
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
