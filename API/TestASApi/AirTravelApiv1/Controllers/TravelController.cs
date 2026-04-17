using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;

namespace AirTravelApiv1.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class TravelController : ControllerBase
    {
        private readonly IConfiguration _configuration;

        public TravelController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        [HttpGet("airports")]
        public IActionResult GetAirports()
        {
            var airports = new[] { "JFK", "LAX", "ORD", "ATL", "DFW" };
            return Ok(airports);
        }

        [HttpGet("aircrafts")]
        public IActionResult GetAircrafts()
        {
            var aircrafts = new[] { "Boeing 747", "Airbus A380", "Boeing 777", "Airbus A320", "Boeing 737" };
            return Ok(aircrafts);
        }

        [HttpGet("config")]
        public IActionResult GetConfig()
        {
            var configValues = new
            {
                StripePaymentUrl = _configuration["stripepaymenturl"],
                CopilotChatUrl = _configuration["copilotchaturl"]
            };
            return Ok(configValues);
        }
    }
}
