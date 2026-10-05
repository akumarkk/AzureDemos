$groupId = az pipelines variable-group list `
  --org "https://dev.azure.com/itsals" `
  --project "FlightOps" `
  --query "[?name=='Ops360BuildPipelineVariables'].id | [0]" `
  -o tsv

Write-Host "groupId $groupId"

  az pipelines variable-group variable list `
  --group-id $groupId `
  --org "https://dev.azure.com/itsals" `
  --project "FlightOps" `
  --query "DT_API_TOKEN.value" `
  -o tsv