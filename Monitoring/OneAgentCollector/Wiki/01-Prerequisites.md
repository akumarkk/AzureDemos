# Step 1: Prerequisites check

Read-only check of the local machine.

## Command

```powershell
Get-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole
Get-Service W3SVC
Get-Service -Name "Dynatrace OneAgent*"
Test-Path "C:\Program Files\dynatrace\oneagent"
dotnet --list-sdks
([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
```

## Result

| Item | Result | Action |
|------|--------|--------|
| IIS (`IIS-WebServerRole`) | Disabled, no `W3SVC` service | Enable in step 2 |
| OneAgent service / install folder | Not found | Install in step 5 |
| .NET SDK | 10.0.400 | OK |
| Elevated PowerShell | Yes | OK, needed to enable IIS and install OneAgent |

## Still needed from you

- Dynatrace environment URL and a token with the `InstallerDownload` scope (or the installer `.exe` from the Deploy Dynatrace page). Needed in step 5.

## Next

Step 2: enable IIS.
