using AirTravelAccomodations.Models;
using Microsoft.AspNetCore.Mvc;

namespace AirTravelAccomodations.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class HotelsController : ControllerBase
    {
        private static readonly List<Hotel> Hotels = new List<Hotel>
        {
            new Hotel { Id = 1, Name = "Grand Hyatt", Location = "New York" },
            new Hotel { Id = 2, Name = "The Plaza", Location = "New York" },
            new Hotel { Id = 3, Name = "The Beverly Hills Hotel", Location = "Los Angeles" },
            new Hotel { Id = 4, Name = "The Peninsula", Location = "Chicago" },
            new Hotel { Id = 5, Name = "The Ritz-Carlton", Location = "Chicago" }
        };

        [HttpGet]
        public ActionResult<IEnumerable<Hotel>> GetHotels()
        {
            return Ok(Hotels);
        }

        [HttpGet("locations")]
        public ActionResult<IEnumerable<string>> GetHotelLocations()
        {
            var locations = Hotels.Select(h => h.Location).Distinct();
            return Ok(locations);
        }

        [HttpGet("{id}/similar")]
        public ActionResult<IEnumerable<Hotel>> GetSimilarHotels(int id)
        {
            var hotel = Hotels.FirstOrDefault(h => h.Id == id);
            if (hotel == null)
            {
                return NotFound();
            }

            var similarHotels = Hotels.Where(h => h.Location == hotel.Location && h.Id != id);
            return Ok(similarHotels);
        }
    }
}
