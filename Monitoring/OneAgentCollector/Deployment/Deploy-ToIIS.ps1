#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [string]$Project  = (Join-Path $PSScriptRoot '..\DTTagsDemoApplrc\DTTagsDemoApplRC.csproj'),
    [string]$SiteName = 'VisOpsDemoSite',
    [string]$PoolName = 'VisOpsDemoAppPool',
    [string]$Path     = 'C:\inetpub\VisOpsDemoApp',
    [int]$Port        = 8081
)

$ErrorActionPreference = 'Stop'
Import-Module WebAdministration

if (-not (Get-Service W3SVC -ErrorAction SilentlyContinue)) {
    throw 'IIS is not installed (W3SVC not found). Enable IIS first.'
}

if (-not (Test-Path "IIS:\AppPools\$PoolName")) {
    New-WebAppPool -Name $PoolName | Out-Null
    # No Managed Code: ASP.NET Core runs out of process via the ASP.NET Core Module.
    Set-ItemProperty "IIS:\AppPools\$PoolName" managedRuntimeVersion ''
}

# Stop the pool so w3wp.exe releases locked files.
if ((Get-WebAppPoolState $PoolName).Value -ne 'Stopped') {
    Stop-WebAppPool $PoolName
    while ((Get-WebAppPoolState $PoolName).Value -ne 'Stopped') { Start-Sleep -Milliseconds 200 }
}

dotnet publish $Project -c Release -o $Path --nologo
if ($LASTEXITCODE -ne 0) { throw "dotnet publish failed ($LASTEXITCODE)" }

if (-not (Get-Website -Name $SiteName)) {
    New-Website -Name $SiteName -Port $Port -PhysicalPath $Path -ApplicationPool $PoolName | Out-Null
} else {
    Set-ItemProperty "IIS:\Sites\$SiteName" physicalPath $Path
    Set-ItemProperty "IIS:\Sites\$SiteName" applicationPool $PoolName
}

Start-WebAppPool $PoolName
if ((Get-WebsiteState $SiteName).Value -ne 'Started') { Start-Website $SiteName }

& (Join-Path $PSScriptRoot 'Test-Smoke.ps1') -BaseUrl "http://localhost:$Port"
if ($LASTEXITCODE -ne 0) { throw 'Smoke test failed.' }

Write-Host "Deployed to http://localhost:$Port/ (try /env)"
