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

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
Write-Log "Starting Azure Activity Log resource query (lookback: ${Days}d, max-events: $MaxEvents)..."

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Log "Azure CLI ('az') is not installed or not in PATH." -Level 'ERROR'
    exit 1
}

if ([string]::IsNullOrWhiteSpace($Caller)) {
    Write-Log "Resolving current Azure CLI account..."
    $Caller = (az account show --query "user.name" -o tsv 2>&1)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($Caller)) {
        Write-Log "Failed to get current Azure account. Run 'az login' first. Details: $Caller" -Level 'ERROR'
        exit 1
    }
    $Caller = $Caller.Trim()
}
Write-Log "Filtering activity logs for caller: $Caller"

Write-Log "Fetching enabled subscriptions..."
$subsJson = az account list --query "[?state=='Enabled'].{id:id, name:name}" -o json 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Log "Failed to list subscriptions: $subsJson" -Level 'ERROR'
    exit 1
}

$subscriptions = @($subsJson | ConvertFrom-Json)
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
    Write-Log "[$index/$($subscriptions.Count)] Querying subscription '$($sub.name)' ($($sub.id))..."

    $rawOutput = az monitor activity-log list `
        --subscription $sub.id `
        --caller $Caller `
        --offset "${Days}d" `
        --max-events $MaxEvents `
        --query $jmesFilter `
        -o json 2>&1

    if ($LASTEXITCODE -ne 0) {
        $failedSubs++
        Write-Log "Failed to query subscription '$($sub.name)' ($($sub.id)): $rawOutput" -Level 'WARN'
        continue
    }

    $events = @($rawOutput | ConvertFrom-Json)
    Write-Log "[$index/$($subscriptions.Count)] Found $($events.Count) matching event(s) in '$($sub.name)'." -Level $(if ($events.Count -gt 0) { 'SUCCESS' } else { 'INFO' })

    foreach ($evt in $events) {
        $allResults.Add([PSCustomObject]@{
            Subscription  = $sub.name
            SubId         = $sub.id
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