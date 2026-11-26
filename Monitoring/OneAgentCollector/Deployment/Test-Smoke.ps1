[CmdletBinding()]
param(
    [string]$BaseUrl = 'http://localhost:8081',
    [string[]]$Paths = @('/', '/env')
)

$failed = $false
foreach ($p in $Paths) {
    try {
        $r = Invoke-WebRequest "$BaseUrl$p" -UseBasicParsing -TimeoutSec 30
        Write-Host ("PASS {0} {1}" -f $r.StatusCode, $p)
    } catch {
        Write-Host ("FAIL {0} {1}" -f $p, $_.Exception.Message) -ForegroundColor Red
        $failed = $true
    }
}

exit ([int]$failed)
