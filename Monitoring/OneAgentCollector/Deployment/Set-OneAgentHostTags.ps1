#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [string]$Tags      = 'primary_tags.app=craftops primary_tags.team=craftopsvisopsdemo primary_tags.env=local',
    [string]$HostGroup = ''
)

$ErrorActionPreference = 'Stop'
$ctl = Join-Path $env:ProgramFiles 'dynatrace\oneagent\agent\tools\oneagentctl.exe'
if (-not (Test-Path $ctl)) { throw "oneagentctl not found at $ctl. Install OneAgent first." }

$tagList = $Tags -split '\s+' | Where-Object { $_ }

# Host group defaults to the team value so it does not need a separate input.
if (-not $HostGroup) {
    $team = $tagList | Where-Object { $_ -like 'primary_tags.team=*' } | Select-Object -First 1
    if ($team) { $HostGroup = $team.Substring($team.IndexOf('=') + 1) }
}

# Remove first so re-runs do not leave duplicates. hostautotag.conf does not exist until the first tag is set, so remove fails then.
foreach ($tag in $tagList) {
    $ErrorActionPreference = 'Continue'
    & $ctl --remove-host-tag=$tag 2>$null | Out-Null
    $ErrorActionPreference = 'Stop'

    & $ctl --set-host-tag=$tag
    if ($LASTEXITCODE -ne 0) { throw "Failed to set host tag '$tag' ($LASTEXITCODE)" }
}

if ($HostGroup) {
    $ErrorActionPreference = 'Continue'
    $current = (& $ctl --get-host-group 2>$null | Out-String).Trim()
    $ErrorActionPreference = 'Stop'

    # oneagentctl refuses a host group change unless the service is stopped, so restart only when it changes.
    if ($current -ne $HostGroup) {
        & $ctl --set-host-group=$HostGroup --restart-service
        if ($LASTEXITCODE -ne 0) { throw "Failed to set host group '$HostGroup' ($LASTEXITCODE)" }
    }
} else {
    Write-Warning 'No host group set (no -HostGroup and no primary_tags.team in -Tags).'
}

Write-Host 'Host tags:'
& $ctl --get-host-tags
Write-Host "Host group: $(& $ctl --get-host-group)"
