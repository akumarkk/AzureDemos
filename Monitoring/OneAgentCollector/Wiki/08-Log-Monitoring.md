# Step 8: Ship application logs to Dynatrace

Status: in progress. Covers stage 4 of the flow.

## Concept

1. **The app writes a file.** log4net writes `app.log` under the app's `logs` folder. Each line includes the `DT_*` values, which `Program.cs` reads from the environment at start-up. They are plain text in the message, not Dynatrace tags.
2. **OneAgent finds the file.** The OneAgent log module runs as a system service and reads files from disk. It does not read the log4net config. It learns about a file in one of two ways:
   - **Auto-discovery.** The code module in a monitored process reports files the process holds open for writing. This can miss files that are opened and closed on every write.
   - **Custom log source.** A path pattern configured in the tenant. The log module watches it directly.
3. **The tenant decides what is stored.** Ingest rules include or exclude sources. A discovered or configured source is only stored if a rule includes it.
4. **Enrichment is separate.** OneAgent can add trace and entity context (`trace_id`, `dt.entity.*`) to log lines written by the monitored process. This confirms the agent is attached. It does not mean the file has been ingested.

```text
app (log4net) -> app.log -> OneAgent log module -> ingest rules -> Dynatrace Logs
```

## Steps

### 1. Application

- `log4net.config` has a rolling file appender writing to `<publish dir>\logs\app.log`. It is copied to the publish output.
- `Program.cs` sets `LogDir` and the `DT_*` log properties before `AddLog4Net` loads the config.

### 2. Write permission (IIS)

The app pool identity (`IIS AppPool\<pool>`) cannot write under `C:\inetpub` by default, and log4net fails silently. `Deployment/Initialize-LogDir.ps1` creates the `logs` folder and grants that identity Modify on it. `Deploy-ToIIS.ps1` runs it after publishing.

### 3. Deploy and generate traffic

```powershell
.\Deployment\Deploy-ToIIS.ps1
Invoke-WebRequest http://localhost:8081/ -UseBasicParsing | Out-Null
Get-Content C:\inetpub\VisOpsDemoApp\logs\app.log -Tail 5
```

The first request starts the app, so the file does not exist before it.

### 4. OneAgent on the host

Check that the agent may read log content:

```powershell
& "$env:ProgramFiles\dynatrace\oneagent\agent\tools\oneagentctl.exe" --get-app-log-content-access
```

If it is not `true`, enable it with `--set-app-log-content-access=true`.

### 5. Tenant settings

In Settings > Log Monitoring:

1. Add a custom log source with the path `C:\inetpub\VisOpsDemoApp\logs\*.log`. `*.log` does not match rolled files such as `app.log.1`.
2. Scope it to this host or host group only. A broad scope shows "Not found" on every other host.
3. Check that an ingest rule includes the source.

### 6. Verify

- In the log source status for this host, the source shows **Readable**. **Not found** means the path does not match a file on that host.
- In Logs, search for `Handled request to`. Lines should appear after a few minutes.
- The host-side log module logs are in `C:\ProgramData\dynatrace\oneagent\log\loganalytics`. Search them for the app's folder name to see whether the file was detected.

## Notes

- Auto-discovery can miss the file if log4net uses `MinimalLock`. Use a custom log source, or switch the appender to `ExclusiveLock` so the file stays open.
- Changing the log pattern or `DT_*` values needs a redeploy or an app pool recycle.
- To make `primary_tags` real attributes instead of message text, use a Dynatrace log processing rule or OneAgent metadata enrichment. The log4net pattern alone does not do that.
