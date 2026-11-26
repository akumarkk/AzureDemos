#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [string]$TenantId,
    [string]$ApiToken = $env:DT_API_TOKEN,
    [switch]$SkipIisReset
)

function Install-OneAgent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidatePattern('^[a-z0-9]+$')]
        [string]$TenantId,

        [string]$Domain = 'live.dynatrace.com',

        [string]$ApiToken = $env:DT_API_TOKEN,

        [switch]$SkipIisReset
    )

    $ErrorActionPreference = 'Stop'

    if (-not $ApiToken) {
        throw 'No API token. Pass -ApiToken or set $env:DT_API_TOKEN (needs the InstallerDownload scope).'
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $url       = "https://$TenantId.$Domain/api/v1/deployment/installer/agent/windows/default/latest?arch=x86"
    $installer = Join-Path $env:TEMP 'Dynatrace-OneAgent.exe'

    try {
        Write-Host "Downloading OneAgent installer from $TenantId.$Domain ..."
        Invoke-WebRequest $url -Headers @{ Authorization = "Api-Token $ApiToken" } -OutFile $installer -UseBasicParsing

        Write-Host 'Installing OneAgent ...'
        $p = Start-Process $installer -ArgumentList '--quiet' -Wait -PassThru
        if ($p.ExitCode -ne 0) { throw "OneAgent installer failed (exit code $($p.ExitCode))." }
    }
    finally {
        Remove-Item $installer -Force -ErrorAction SilentlyContinue
    }

    if (-not $SkipIisReset) {
        # An already running w3wp.exe is not injected.
        iisreset | Out-Null
    }

    Get-Service 'Dynatrace OneAgent*' | Select-Object Name, Status
}

# Run directly: .\Install-OneAgent.ps1 -TenantId abc12345. Dot-source to only load the function.
if ($TenantId) {
    Install-OneAgent -TenantId $TenantId -ApiToken $ApiToken -SkipIisReset:$SkipIisReset
}
