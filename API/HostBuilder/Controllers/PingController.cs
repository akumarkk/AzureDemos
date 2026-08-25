using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Swashbuckle.AspNetCore.Annotations;
using System.Net;
using System.Threading.Tasks;

namespace HostBuilderApp.Controllers
{
    /// <summary>
    /// Check status of API
    /// </summary>
    [ApiVersion("1")]
    [Route("api/v{version:apiVersion}/[controller]")]
    [ApiController]
    public class PingController : ControllerBase
    {
        private readonly HealthCheckService _healthCheckService;

        /// <summary>
        /// 
        /// </summary>
        /// <param name="healthCheckService"></param>
        public PingController(HealthCheckService healthCheckService)
        {
            _healthCheckService = healthCheckService;
        }

        /// <summary>
        /// Check status of API
        /// </summary>
        /// <returns></returns>
        [HttpGet]
        [AllowAnonymous]
        [SwaggerResponse((int)HttpStatusCode.OK)]
        [SwaggerOperation("GET Ping")]
        public IActionResult GetPing()
        {
            return Ok();
        }

    }
}
