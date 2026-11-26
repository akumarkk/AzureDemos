## Log folder permissions

The app writes `app.log` with log4net to `<publish dir>\logs`
(`C:\inetpub\VisOpsDemoApp\logs` by default). Under IIS the app runs as the
app pool's virtual account, `IIS AppPool\<PoolName>`, which cannot write under
`C:\inetpub` by default. log4net does not raise an error when it can't write,
so without this step the app starts but no log file appears.

`Deployment/Initialize-LogDir.ps1` fixes this. `Deploy-ToIIS.ps1` runs it
right after `dotnet publish`.
- Creates `<Path>\logs` if it doesn't exist.
- Grants `IIS AppPool\<PoolName>` Modify on that folder only, inherited by
  files and subfolders (`icacls ... (OI)(CI)M`). The rest of the site stays
  read-only for the pool identity.
- Throws if `icacls` fails, so a broken grant stops the deploy.

It is safe to re-run. To fix an existing deployment, run
`.\Deployment\Initialize-LogDir.ps1`, then recycle the pool.

`Test-SmokeEnv.ps1` checks the result by reading the newest `app.log` line and
confirming it contains the expected `dt_tags` value. A missing file or wrong
permissions fails the deploy.