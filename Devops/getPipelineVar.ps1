$groupId = az pipelines variable-group list `
  --org "https://dev.azure.com/" `
  --project "" `
  --query "[?name==''].id | [0]" `
  -o tsv

Write-Host "groupId $groupId"

  az pipelines variable-group variable list `
  --group-id $groupId `
  --org "https://dev.azure.com/" `
  --project "" `
  --query ".value" `
  -o tsv