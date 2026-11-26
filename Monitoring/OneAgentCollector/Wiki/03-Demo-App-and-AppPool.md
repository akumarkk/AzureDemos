# Step 3: Create demo app and app pool

Status: planned, not yet executed.

## App

Minimal ASP.NET Core app in `OneAgentCollector/DTTagsDemoApplrc` with one endpoint, `/env`, that returns the process environment variables starting with `DT_`. It shows what the process sees, which is what OneAgent reads in stage 2 of the flow.

```powershell
dotnet publish DTTagsDemoApplrc -c Release -o C:\inetpub\VisOpsDemoApp
```

## IIS

```powershell
Import-Module WebAdministration
New-WebAppPool -Name VisOpsDemoAppPool
Set-ItemProperty IIS:\AppPools\VisOpsDemoAppPool managedRuntimeVersion ""
New-Website -Name VisOpsDemoSite -Port 8081 -PhysicalPath C:\inetpub\VisOpsDemoApp -ApplicationPool VisOpsDemoAppPool
```

## Check

- `http://localhost:8081/env` responds.
- `Get-Process w3wp` shows a worker process for `VisOpsDemoAppPool` after the first request.

The same steps are automated, with a smoke test, by `Deployment/Deploy-ToIIS.ps1`.
