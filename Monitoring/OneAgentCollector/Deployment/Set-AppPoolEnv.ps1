#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [string]$PoolName   = 'VisOpsDemoAppPool',
    [string]$Tags       = 'primary_tags.app=craftops primary_tags.team=craftopsvisopsdemo primary_tags.env=local',
    [string]$CustomProp = 'owner=anikris stage=dev',
    [string]$ClusterId  = $env:DT_CLUSTER_ID
)

$ErrorActionPreference = 'Stop'
$appcmd  = Join-Path $env:windir 'System32\inetsrv\appcmd.exe'
$section = 'system.applicationHost/applicationPools'

$vars = [ordered]@{
    DT_TAGS         = $Tags
    DT_CUSTOM_PROP  = $CustomProp
    DT_CLUSTER_ID   = $ClusterId
}

foreach ($name in $vars.Keys) {
    # Remove first so re-runs replace the value instead of failing on a duplicate key.
    & $appcmd set config -section:$section /-"[name='$PoolName'].environmentVariables.[name='$name']" /commit:apphost 2>&1 | Out-Null

    $value = $vars[$name]
    if ([string]::IsNullOrWhiteSpace($value)) {
        Write-Warning "$name has no value; left unset."
        continue
    }

    & $appcmd set config -section:$section /+"[name='$PoolName'].environmentVariables.[name='$name',value='$value']" /commit:apphost | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failed to set $name on pool '$PoolName' ($LASTEXITCODE)" }
    Write-Host "Set $name=$value on $PoolName"
}
