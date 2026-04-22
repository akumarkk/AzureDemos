using Microsoft.AspNetCore.Mvc;
using System;
using System.Reflection;

namespace AirTravelAccomodations.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class EnvironmentController : ControllerBase
    {
        [HttpGet("check-env")]
        public ActionResult<object> CheckAppInsightsConnectionString()
        {
            var connectionString = Environment.GetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING");
            bool isSet = !string.IsNullOrEmpty(connectionString);
            return Ok(new { isApplicationInsightsConfigured = isSet });
        }

        [HttpGet("check-appconfig")]
        public ActionResult<object> CheckAppConfigEndpoint()
        {
            var appConfigEndpoint = Environment.GetEnvironmentVariable("AZURE_Travel_APPCONFIG");
            bool isSet = !string.IsNullOrEmpty(appConfigEndpoint);
            return Ok(new { isAppConfigConfigured = isSet });
        }

        [HttpGet("check-all-env")]
        public ActionResult<object> CheckAllEnvironmentVariables()
        {
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
