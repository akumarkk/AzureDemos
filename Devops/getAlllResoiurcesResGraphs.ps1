[CmdletBinding()]
param(
    [string]$Caller,
    [string]$OutputCsv
)

$ErrorActionPreference = 'Stop'

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS')][string]$Level = 'INFO'
    )
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) { 'INFO' { 'Cyan' } 'WARN' { 'Yellow' } 'ERROR' { 'Red' } 'SUCCESS' { 'Green' } }
    Write-Host "[$ts] [$Level] $Message" -ForegroundColor $color
}

if ([string]::IsNullOrWhiteSpace($Caller)) {
    $Caller = (az account show --query "user.name" -o tsv).Trim()
}

# Resource Graph changedBy can be either UPN/email or Entra Object ID
$callerIds = @($Caller)
$prevEAP = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$oid = (az ad signed-in-user show --query "id" -o tsv 2>$null)
$ErrorActionPreference = $prevEAP
if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($oid)) {
    $callerIds += $oid.Trim()
}

Write-Log "Querying Azure Resource Graph across all accessible subscriptions for: $($callerIds -join ', ')..."

# Map subscription IDs to friendly names
$subMap = @{}
$subs = az account list --query "[?state=='Enabled'].{id:id, name:name}" -o json | ConvertFrom-Json
foreach ($s in $subs) {
    if (-not [string]::IsNullOrWhiteSpace($s.id)) {
        $subMap[[string]$s.id] = [string]$s.name
    }
}
Write-Log "Loaded $($subMap.Count) enabled subscription(s) for name resolution."

$callerFilter = ($callerIds | ForEach-Object { "tostring(properties.changeAttributes.changedBy) =~ '$_'" }) -join ' or '

$kql = @"
resourcechanges
| where properties.changeType == 'Create'
| where $callerFilter
| project
    Time          = todatetime(properties.changeAttributes.timestamp),
    Subscription  = subscriptionId,
    ResourceGroup = resourceGroup,
    ResourceId    = tostring(properties.targetResourceId),
    ChangedBy     = tostring(properties.changeAttributes.changedBy),
    ByType        = tostring(properties.changeAttributes.changedByType)
| order by Time desc
"@

# Omitting --subscriptions queries all accessible subscriptions in the tenant
$allRows = [System.Collections.Generic.List[object]]::new()
$skipToken = $null
$page = 0

do {
    $page++
    $graphArgs = @('graph', 'query', '-q', $kql, '--first', '1000', '-o', 'json')
    if ($skipToken) {
        $graphArgs += @('--skip-token', $skipToken)
    }

    $res = (& az @graphArgs) | ConvertFrom-Json
    if ($res.data) {
        foreach ($row in $res.data) {
            $subId = [string]$row.Subscription
            $subName = if (-not [string]::IsNullOrWhiteSpace($subId) -and $subMap.ContainsKey($subId)) { $subMap[$subId] } else { $subId }
            $allRows.Add([PSCustomObject]@{
                Time             = $row.Time
                SubscriptionName = $subName
                SubscriptionId   = $subId
                ResourceGroup    = $row.ResourceGroup
                ChangedBy        = $row.ChangedBy
                ByType           = $row.ByType
                ResourceId       = $row.ResourceId
            })
        }
    }
    $skipToken = $res.skip_token
    Write-Log "Page $page fetched ($($allRows.Count) total so far)..."
} while (-not [string]::IsNullOrWhiteSpace($skipToken))

Write-Log "Found $($allRows.Count) resource(s) created in the last 14 days across all subscriptions." -Level $(if ($allRows.Count -gt 0) { 'SUCCESS' } else { 'INFO' })

if ($allRows.Count -gt 0) {
    if (-not [string]::IsNullOrWhiteSpace($OutputCsv)) {
        $allRows | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
        Write-Log "Exported $($allRows.Count) record(s) to '$OutputCsv'." -Level 'SUCCESS'
    }
    $allRows | Format-Table -Property Time, SubscriptionName, ResourceGroup, ChangedBy, ResourceId -AutoSize
}