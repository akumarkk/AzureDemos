using System.Threading;                 // For CancellationToken
using System.Threading.Tasks;           // For Task
using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace HostBuilderApp.Services;

public class PingHealthCheckService : IHealthCheck
{
    public Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default)
    {
        return Task.FromResult(HealthCheckResult.Healthy());
    }
}