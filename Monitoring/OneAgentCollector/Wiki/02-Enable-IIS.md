# Step 2: Enable IIS

Status: planned, not yet executed.

## Commands (elevated PowerShell)

```powershell
Enable-WindowsOptionalFeature -Online -All -NoRestart -FeatureName `
  IIS-WebServerRole, IIS-WebServer, IIS-ManagementConsole, IIS-RequestFiltering, IIS-StaticContent, IIS-DefaultDocument

Get-Service W3SVC
```

Install the ASP.NET Core Hosting Bundle (matching the .NET 10 SDK) so IIS can host the demo app, then run `iisreset`.

## Check

- `W3SVC` exists and is `Running`.
- `http://localhost/` returns the default IIS page.

## Notes

- A restart may be requested.
- Install the Hosting Bundle after IIS, otherwise the ASP.NET Core Module is not registered.
