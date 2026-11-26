# Step 3: Create demo app and app pool

Status: planned, not yet executed.

## App

Minimal ASP.NET Core app in `OneAgentCollector/DemoApp` with one endpoint, `/env`, that returns the process environment variables starting with `DT_`. It shows what the process sees, which is what OneAgent reads in stage 2 of the flow.

```powershell
dotnet new web -n DemoApp
dotnet publish DemoApp -c Release -o C:\inetpub\DemoApp
```

## IIS

```powershell
Import-Module WebAdministration
New-WebAppPool -Name DemoAppPool
Set-ItemProperty IIS:\AppPools\DemoAppPool managedRuntimeVersion ""
New-Website -Name DemoSite -Port 8081 -PhysicalPath C:\inetpub\DemoApp -ApplicationPool DemoAppPool
```

## Check

- `http://localhost:8081/env` responds.
- `Get-Process w3wp` shows a worker process for `DemoAppPool` after the first request.
