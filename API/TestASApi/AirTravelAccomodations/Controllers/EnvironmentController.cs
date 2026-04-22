using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System;
using System.Diagnostics;
using System.Reflection;

namespace AirTravelAccomodations.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class EnvironmentController : ControllerBase
    {
        private readonly ILogger<EnvironmentController> _logger;

        public EnvironmentController(ILogger<EnvironmentController> logger)
        {
            _logger = logger;
        }

        [HttpGet("check-env")]
        public ActionResult<object> CheckAppInsightsConnectionString()
        {
            _logger.LogInformation("Checking Application Insights connection string. Correlation ID: {correlationId}", Activity.Current?.Id);
            var connectionString = Environment.GetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING");
            bool isSet = !string.IsNullOrEmpty(connectionString);
            return Ok(new { isApplicationInsightsConfigured = isSet });
        }

        [HttpGet("check-appconfig")]
        public ActionResult<object> CheckAppConfigEndpoint()
        {
            _logger.LogInformation("Checking App Config endpoint. Correlation ID: {correlationId}", Activity.Current?.Id);
            var appConfigEndpoint = Environment.GetEnvironmentVariable("AZURE_Travel_APPCONFIG");
            bool isSet = !string.IsNullOrEmpty(appConfigEndpoint);
            return Ok(new { isAppConfigConfigured = isSet });
        }

        [HttpGet("check-all-env")]
        public ActionResult<object> CheckAllEnvironmentVariables()
        {
            _logger.LogInformation("Checking all environment variables. Correlation ID: {correlationId}", Activity.Current?.Id);
            var appInsightsConnectionString = Environment.GetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING");
            var appConfigEndpoint = Environment.GetEnvironmentVariable("AZURE_Travel_APPCONFIG");
            var assemblyVersion = Assembly.GetExecutingAssembly().GetName().Version?.ToString();

            var result = new
            {
                isApplicationInsightsConfigured = !string.IsNullOrEmpty(appInsightsConnectionString),
                isAppConfigConfigured = !string.IsNullOrEmpty(appConfigEndpoint),
                assemblyVersion = assemblyVersion
            };

            return Ok(result);
        }
    }
}
