namespace HostBuilderApp;

using Microsoft.AspNetCore.Builder;    // For IApplicationBuilder
using Microsoft.AspNetCore.Hosting;    // For IWebHostEnvironment
using Microsoft.Extensions.Configuration; // For IConfiguration
using Microsoft.Extensions.DependencyInjection;

using HostBuilderApp.Services;

public class Startup
{
    public Startup(IConfiguration configuration)
    {
        //Configuration = configuration;
    }

    public void ConfigureServices(IServiceCollection services)
        {
            services.AddControllers()
                // Custom serialization converters
                .AddJsonOptions(
                    options => 
                    {
                        // TODO: Add custom serialization converters here
                    }
                        // DateTime objects should be in a certain format.
                      //  options.JsonSerializerOptions.Converters.Add(new DateTimeJsonConverter())
                );

                //Health checks ensure site is up and running
            services.AddHealthChecks().AddCheck<PingHealthCheckService>("PingHealthCheck");

        }

        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            app.UseHttpsRedirection();

            app.UseRouting();
            app.UseCors("CorsPolicy");
            app.UseAuthentication();
            app.UseAuthorization();

            // What environment are we deployed to?
            var environment = "Dev";
            // Swagger should only be available during development.  Never deploy to Test/QA/Production.
            //if (environment.IsDevelopment())
            if (string.Equals(environment, "Dev", StringComparison.OrdinalIgnoreCase))
            {
                // Enable middleware to serve generated Swagger as a JSON endpoint.
                app.UseSwagger();

                // Enable middleware to serve swagger-ui (HTML, JS, CSS, etc.), specifying the Swagger JSON endpoint.
                app.UseSwaggerUI(c =>
                {
                    c.SwaggerEndpoint("/swagger/v1/swagger.json", "AOC Reference API");
                });
            }

            app.UseEndpoints(endpoints =>
            {
                //Healthcheck url
                endpoints.MapHealthChecks("/healthcheck");
                endpoints.MapControllers();
            });
        }

}