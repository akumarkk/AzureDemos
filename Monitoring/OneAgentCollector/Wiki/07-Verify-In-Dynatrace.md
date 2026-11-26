# Step 7: Verify tags in Dynatrace

Status: planned, not yet executed. Covers stage 3 of the flow.

## UI

1. Open Hosts or Processes and find the `w3wp.exe` process for `DemoAppPool`.
2. Open the process or process group and check its properties and tags for `DT_TAGS`, `DT_CUSTOM_PROP` and `DT_CLUSTER_ID` values.

## API

```powershell
Invoke-RestMethod "$env/api/v2/entities?entitySelector=type(PROCESS_GROUP_INSTANCE),entityName.contains(w3wp)&fields=+properties,+tags" `
  -Headers @{ Authorization = "Api-Token $plain" }
```

This needs a token with the `entities.read` scope.

## Notes

- It can take a few minutes for a new process to appear.
- Changing `DT_*` values requires an app pool recycle, and the entity may take time to update.
