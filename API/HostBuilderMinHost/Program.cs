using System.Diagnostics.CodeAnalysis; // For ExcludeFromCodeCoverage
using Microsoft.Extensions.Hosting;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Builder;
//using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.DependencyInjection;
//using Microsoft.Extensions.Hosting;
using Microsoft.OpenApi.Models;
using HostBuilderApp.Services;


namespace HostBuilderApp
{
    /// <summary>
    /// 
    /// </summary>
    [ExcludeFromCodeCoverage]
    public static class Program
    {
        /// <summary>
        /// 
        /// </summary>
        /// <param name="args"></param>
        public static void Main(string[] args)
        {
            CreateHostBuilder(args).Build().Run();
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    //webBuilder.UseStartup<Startup>();

                    // 1. Configure Services (Formerly Startup.ConfigureServices)
                    webBuilder.ConfigureServices((hostContext, services) =>
                    {
                        services.AddControllers()
                        // Custom serialization converters
                        .AddJsonOptions(options =>  {
                                // TODO: Add custom serialization converters here
                            
                                // DateTime objects should be in a certain format.
                                //  options.JsonSerializerOptions.Converters.Add(new DateTimeJsonConverter())
                        });

                        // 1. Register API versioning
                        services.AddApiVersioning(options =>
                        {
                            options.ReportApiVersions = true;
                            options.AssumeDefaultVersionWhenUnspecified = true;
                        });
                
                        services.AddSwaggerGen(c =>
                            {
                                var version = typeof(Startup).Assembly.GetName().Version?.ToString() ?? "0.0.0.0";

                                c.SwaggerDoc("v1", new OpenApiInfo
                                {
                                    Title = "Craft API",
                                    Version = version,
                                    Description = "Purpose: Host builder demos <br /> " +
                                    "Owner: anikris <br /> " +
                                    "Repo Url: https://github.com/anikris/HostBuilderApp <br /> "
                                });

                                c.EnableAnnotations();
                            });

                        //Health checks ensure site is up and running
                        services.AddHealthChecks().AddCheck<PingHealthCheckService>("PingHealthCheck");

                    });

                    // 2. Configure HTTP Pipeline (MUST be called on webBuilder)
                    webBuilder.Configure((hostContext, app) =>
                    {
                        var env = hostContext.HostingEnvironment;

                        if (env.IsDevelopment())
                        {
                            app.UseDeveloperExceptionPage();
                            app.UseSwagger();
                            app.UseSwaggerUI(c =>
                            {
                                c.SwaggerEndpoint("/swagger/v1/swagger.json", "My API V1");
                            });
                        }

                        app.UseHttpsRedirection();
                        app.UseRouting();

                        app.UseAuthentication();
                        app.UseAuthorization();

                        app.UseEndpoints(endpoints =>
                        {
                            endpoints.MapControllers();
                            endpoints.MapHealthChecks("/healthcheck");
                        });
                    });

                    
                });
    }
}