[CmdletBinding()]
param(
    [string]$BaseUrl    = 'http://localhost:8081',
    [string]$Tags       = 'primary_tags.app=craftops primary_tags.team=craftopsvisopsdemo primary_tags.env=local',
    [string]$CustomProp = 'owner=anikris stage=dev',
    [string]$ClusterId  = $env:DT_CLUSTER_ID,
    [string]$LogFile    = 'C:\inetpub\VisOpsDemoApp\logs\app.log'
)

$expected = [ordered]@{
    DT_TAGS        = $Tags
    DT_CUSTOM_PROP = $CustomProp
    DT_CLUSTER_ID  = $ClusterId
}

$failed = $false
function Report([bool]$ok, [string]$msg) {
    if ($ok) { Write-Host "PASS $msg" } else { Write-Host "FAIL $msg" -ForegroundColor Red; $script:failed = $true }
}

try {
    $actual = Invoke-RestMethod "$BaseUrl/env" -TimeoutSec 30
} catch {
    Write-Host "FAIL GET /env: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

foreach ($name in $expected.Keys) {
    if ([string]::IsNullOrWhiteSpace($expected[$name])) { Write-Host "SKIP $name (no expected value)"; continue }
    $got = $actual.$name
    Report ($got -eq $expected[$name]) "/env $name expected=[$($expected[$name])] actual=[$got]"
}

# "/" writes a log line; the newest line must carry the dt_tags value.
Invoke-WebRequest "$BaseUrl/" -UseBasicParsing -TimeoutSec 30 | Out-Null
if (Test-Path $LogFile) {
    $last = Get-Content $LogFile -Tail 1
    Report ($last -like "*dt_tags=[$Tags]*") "log line tagged with dt_tags: $last"
} else {
    Report $false "log file not found: $LogFile"
}

exit ([int]$failed)
