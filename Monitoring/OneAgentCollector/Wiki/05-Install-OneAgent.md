# Step 5: Install OneAgent

Status: planned, not yet executed. Needs a Dynatrace environment URL and an `InstallerDownload` token. Covers the install part of stage 1 of the flow.

## Before you start

- Steps 2 to 4 are done: IIS is running and `VisOpsDemoSite` responds on port 8081.
- Elevated PowerShell.
- The token is entered at a prompt. Do not put it in a file, script or the wiki.

## Commands (elevated)

```powershell
$tenant = "https://<environment-id>.live.dynatrace.com"
$secure = Read-Host "Installer token" -AsSecureString
$token  = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))

$installer = Join-Path $env:TEMP "Dynatrace-OneAgent.exe"
Invoke-WebRequest "$tenant/api/v1/deployment/installer/agent/windows/default/latest?arch=x86" `
  -Headers @{ Authorization = "Api-Token $token" } -OutFile $installer

& $installer --quiet
iisreset
```

Alternatively, download the installer from the Deploy Dynatrace page in the UI and run it with `--quiet`.

## Check

```powershell
Get-Service "Dynatrace OneAgent*" | Select-Object Name, Status
Test-Path "C:\Program Files\dynatrace\oneagent"
```

- The service is `Running`.
- The install folder exists.
- The host appears in Dynatrace under Hosts after a few minutes.

## Notes

- Run `iisreset` after the install. A `w3wp.exe` that was already running is not injected.
- `/env` hides variables with `TOKEN` in the name, so a token set in the environment is never shown.
- Remove the token variable when done: `Remove-Variable token, secure`.
