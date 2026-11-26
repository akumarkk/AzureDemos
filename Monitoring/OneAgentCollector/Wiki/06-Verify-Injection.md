# Step 6: Verify injection into `w3wp.exe`

Status: planned, not yet executed. Covers stages 1 and 2 of the flow.

## Commands

```powershell
# Make sure the worker process for the pool is running
Invoke-WebRequest http://localhost:8081/ -UseBasicParsing | Out-Null

# Which w3wp.exe belongs to VisOpsDemoAppPool
Get-CimInstance Win32_Process -Filter "Name='w3wp.exe'" |
  Where-Object CommandLine -match 'VisOpsDemoAppPool' | Select-Object ProcessId, CommandLine

# OneAgent modules loaded into it
$wp = Get-CimInstance Win32_Process -Filter "Name='w3wp.exe'" | Where-Object CommandLine -match 'VisOpsDemoAppPool'
(Get-Process -Id $wp.ProcessId).Modules | Where-Object ModuleName -match 'oneagent' | Select-Object ModuleName, FileName

# What the process sees (stage 2)
(Invoke-RestMethod http://localhost:8081/env) | ConvertTo-Json
```

## Check

- At least one module with `oneagent` in its name is loaded into the `VisOpsDemoAppPool` `w3wp.exe`.
- `/env` shows `DT_TAGS`, `DT_CUSTOM_PROP` and `DT_CLUSTER_ID` with the values set in step 4.
- OneAgent logs under `C:\ProgramData\dynatrace\oneagent\log` mention the process.

## If nothing is injected

- `w3wp.exe` started before the install. Run `iisreset` and make a request again.
- .NET monitoring is turned off in the Dynatrace environment settings.
- `Get-Process ... .Modules` can fail for a 64-bit process from a 32-bit shell. Use a 64-bit PowerShell.

## If `/env` is missing values

- Recycle the app pool: `Restart-WebAppPool VisOpsDemoAppPool`.
- Recheck step 4. The environment block is fixed when `w3wp.exe` starts.
