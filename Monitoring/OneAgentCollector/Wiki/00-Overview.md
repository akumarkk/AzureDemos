# OneAgent on IIS: local setup

Goal: reproduce locally how Dynatrace OneAgent picks up `DT_TAGS`, `DT_CUSTOM_PROP` and `DT_CLUSTER_ID` from an IIS app pool.

## Flow

1. **Injection at start-up.** OneAgent installs a system-level hook on the host (on Windows, a service plus a loader injected into new processes). When IIS starts `w3wp.exe` for the app pool, the OneAgent code module loads into that process before the app code runs.
2. **Reading the environment.** The module reads the process's own environment block. That block includes variables set for the app pool in IIS (`applicationHost.config` under `<environmentVariables>`), plus machine and user variables inherited at launch. `DT_TAGS`, `DT_CUSTOM_PROP`, `DT_CLUSTER_ID` and similar are read from there.
3. **Reporting to the server.** The module sends the process metadata, including those tags, to the OneAgent service, which forwards it to Dynatrace. This is how they end up on the process and process group entities.

## Steps

| # | Step | Flow stage | Status |
|---|------|------------|--------|
| 1 | [Prerequisites check](01-Prerequisites.md) | - | Done |
| 2 | [Enable IIS](02-Enable-IIS.md) | - | Not started |
| 3 | [Create demo app and app pool](03-Demo-App-and-AppPool.md) | - | Not started |
| 4 | [Set app pool environment variables](04-AppPool-Environment-Variables.md) | 2 | Not started |
| 5 | [Install OneAgent](05-Install-OneAgent.md) | 1 | Not started |
| 6 | [Verify injection into `w3wp.exe`](06-Verify-Injection.md) | 1 | Not started |
| 7 | [Verify tags in Dynatrace](07-Verify-In-Dynatrace.md) | 3 | Not started |
