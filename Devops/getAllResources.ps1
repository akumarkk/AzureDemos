<#
.SYNOPSIS
    Lists Azure resources created or modified by a user across enabled subscriptions via Activity Logs.

.DESCRIPTION
    Queries Azure Monitor Activity Logs across all enabled subscriptions (or specified ones)
    for write (and optionally delete) operations performed by the specified caller within the lookback window.

.PARAMETER Caller
    Email/UPN of the caller to filter by. Defaults to the currently logged-in Azure CLI user.

.PARAMETER Days
    Number of days to look back (1-90; Azure Activity Log retention limit is 90 days). Defaults to 90.

.PARAMETER MaxEvents
    Maximum number of events to retrieve per subscription. Defaults to 1000.

.PARAMETER SubscriptionIds
    Optional list of subscription IDs to query. Defaults to all enabled subscriptions.

.PARAMETER IncludeDeletes
    Include '/delete' operations in addition to '/write' operations.

.PARAMETER OutputCsv
    Optional file path to export the aggregated results as CSV.
#>
[CmdletBinding()]
param(
    [string]$Caller,

    [ValidateRange(1, 90)]
    [int]$Days = 90,

    [ValidateRange(1, 10000)]
    [int]$MaxEvents = 1000,

    [string[]]$SubscriptionIds,

    [switch]$IncludeDeletes,

    [string]$OutputCsv
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'INFO'    { 'Cyan' }
        'WARN'    { 'Yellow' }
        'ERROR'   { 'Red' }
        'SUCCESS' { 'Green' }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Invoke-AzCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & az @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $prevEAP
    }

    $stdout = @($output | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] }) -join "`n"
    $stderr = @($output | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] } | ForEach-Object { $_.ToString() }) -join "`n"

    [PSCustomObject]@{
        ExitCode = $exitCode
        StdOut   = $stdout.Trim()
        StdErr   = $stderr.Trim()
    }
}

function ConvertFrom-AzJson {
    param([string]$JsonText)

    if ([string]::IsNullOrWhiteSpace($JsonText)) {
        return @()
    }

    $parsed = $JsonText | ConvertFrom-Json
    if ($null -eq $parsed) {
        return @()
    }
    if ($parsed -is [System.Array]) {
        return $parsed
    }
    return @($parsed)
}

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
Write-Log "Starting Azure Activity Log resource query (lookback: ${Days}d, max-events: $MaxEvents)..."

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Log "Azure CLI ('az') is not installed or not in PATH." -Level 'ERROR'
    exit 1
}

if ([string]::IsNullOrWhiteSpace($Caller)) {
    Write-Log "Resolving current Azure CLI account..."
    $acctRes = Invoke-AzCommand -Arguments @('account', 'show', '--query', 'user.name', '-o', 'tsv')
    if ($acctRes.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($acctRes.StdOut)) {
        Write-Log "Failed to get current Azure account. Run 'az login' first. Details: $($acctRes.StdErr)" -Level 'ERROR'
        exit 1
    }
    $Caller = $acctRes.StdOut
}
Write-Log "Filtering activity logs for caller: $Caller"

Write-Log "Fetching enabled subscriptions..."
$subsRes = Invoke-AzCommand -Arguments @('account', 'list', '--query', "[?state=='Enabled'].{id:id, name:name}", '-o', 'json')
if ($subsRes.ExitCode -ne 0) {
    Write-Log "Failed to list subscriptions: $($subsRes.StdErr)" -Level 'ERROR'
    exit 1
}

$subscriptions = @(ConvertFrom-AzJson -JsonText $subsRes.StdOut)
if ($SubscriptionIds -and $SubscriptionIds.Count -gt 0) {
    $subscriptions = @($subscriptions | Where-Object { $SubscriptionIds -contains $_.id })
}

if ($subscriptions.Count -eq 0) {
    Write-Log "No matching enabled subscriptions found." -Level 'WARN'
    exit 0
}

Write-Log "Found $($subscriptions.Count) enabled subscription(s) to query."

$jmesFilter = if ($IncludeDeletes) {
    "[?operationName.value != null && (ends_with(operationName.value, '/write') || ends_with(operationName.value, '/delete')) && status.value == 'Succeeded'].{Time:eventTimestamp, ResourceGroup:resourceGroupName, Resource:resourceId, Operation:operationName.localizedValue}"
} else {
    "[?operationName.value != null && ends_with(operationName.value, '/write') && status.value == 'Succeeded'].{Time:eventTimestamp, ResourceGroup:resourceGroupName, Resource:resourceId, Operation:operationName.localizedValue}"
}

$allResults = [System.Collections.Generic.List[object]]::new()
$failedSubs = 0
$index = 0

foreach ($sub in $subscriptions) {
    $index++
    $subId = [string]$sub.id
    $subName = [string]$sub.name
    Write-Log "[$index/$($subscriptions.Count)] Querying subscription '$subName' ($subId)..."

    $logRes = Invoke-AzCommand -Arguments @(
        'monitor', 'activity-log', 'list',
        '--subscription', $subId,
        '--caller', $Caller,
        '--offset', "${Days}d",
        '--max-events', "$MaxEvents",
        '--query', $jmesFilter,
        '-o', 'json'
    )

    if ($logRes.ExitCode -ne 0) {
        $failedSubs++
        Write-Log "Failed to query subscription '$subName' ($subId): $($logRes.StdErr)" -Level 'WARN'
        continue
    }

    $events = @(ConvertFrom-AzJson -JsonText $logRes.StdOut)
    Write-Log "[$index/$($subscriptions.Count)] Found $($events.Count) matching event(s) in '$subName'." -Level $(if ($events.Count -gt 0) { 'SUCCESS' } else { 'INFO' })

    foreach ($evt in $events) {
        $allResults.Add([PSCustomObject]@{
            Subscription  = $subName
            SubId         = $subId
            Time          = $evt.Time
            ResourceGroup = $evt.ResourceGroup
            Operation     = $evt.Operation
            Resource      = $evt.Resource
        })
    }
}

$stopwatch.Stop()
$elapsed = [math]::Round($stopwatch.Elapsed.TotalSeconds, 2)
Write-Log "Completed in ${elapsed}s. Total events: $($allResults.Count). Failed subscriptions: $failedSubs." -Level $(if ($failedSubs -gt 0) { 'WARN' } else { 'SUCCESS' })

if ($allResults.Count -eq 0) {
    Write-Log "No matching activity log events found for caller '$Caller' in the last $Days day(s)." -Level 'INFO'
    exit 0
}

$sortedResults = $allResults | Sort-Object -Property Time -Descending

if (-not [string]::IsNullOrWhiteSpace($OutputCsv)) {
    $sortedResults | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
    Write-Log "Exported $($sortedResults.Count) record(s) to '$OutputCsv'." -Level 'SUCCESS'
}

$sortedResults | Format-Table -Property Subscription, Time, ResourceGroup, Operation, Resource -AutoSize