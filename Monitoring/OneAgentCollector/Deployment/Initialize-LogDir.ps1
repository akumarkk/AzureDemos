#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [string]$PoolName = 'VisOpsDemoAppPool',
    [string]$Path     = 'C:\inetpub\VisOpsDemoApp'
)

$ErrorActionPreference = 'Stop'

# log4net fails silently if the pool identity cannot write, so grant it up front.
$logDir = Join-Path $Path 'logs'
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

icacls $logDir /grant "IIS AppPool\${PoolName}:(OI)(CI)M" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "icacls failed on $logDir ($LASTEXITCODE)" }

Write-Host "Log folder ready: $logDir (modify for IIS AppPool\$PoolName)"
