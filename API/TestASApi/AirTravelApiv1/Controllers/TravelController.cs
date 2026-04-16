using Microsoft.AspNetCore.Mvc;

namespace AirTravelApiv1.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class TravelController : ControllerBase
    {
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
    }
}
