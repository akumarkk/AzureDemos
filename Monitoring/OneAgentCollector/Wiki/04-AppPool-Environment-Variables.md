# Step 4: Set app pool environment variables

Status: planned, not yet executed.

These are stored in `applicationHost.config` under `<environmentVariables>` for the app pool and become part of the `w3wp.exe` environment block.

## Commands (elevated)

```powershell
$appcmd = "$env:windir\System32\inetsrv\appcmd.exe"
$pool = "VisOpsDemoAppPool"   # site: VisOpsDemoSite, port 8081

& $appcmd set config -section:system.applicationHost/applicationPools `
  /+"[name='$pool'].environmentVariables.[name='DT_TAGS',value='primary_tags.app=fovisops primary_tags.team=visopsdemo primary_tags.env=local']" /commit:apphost
& $appcmd set config -section:system.applicationHost/applicationPools `
  /+"[name='$pool'].environmentVariables.[name='DT_CUSTOM_PROP',value='owner=anikris stage=dev']" /commit:apphost
& $appcmd set config -section:system.applicationHost/applicationPools `
  /+"[name='$pool'].environmentVariables.[name='DT_CLUSTER_ID',value='$env:DT_CLUSTER_ID']" /commit:apphost

Restart-WebAppPool $pool
```

## Check

`http://localhost:8081/env` lists the three `DT_*` variables.

## Notes

- `DT_TAGS` and `DT_CUSTOM_PROP` are space-separated lists. Use `key=value` entries.
- Recycle the app pool after every change. The environment block is fixed when `w3wp.exe` starts.
- Values here are examples.
