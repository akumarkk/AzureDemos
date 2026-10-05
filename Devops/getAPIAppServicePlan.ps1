
function  GetServerFarmId {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory = $true)]
        [string]$PlanName
    )
    

$subscriptionIds = az account list --query "[].id" -o tsv


# Query each subscription for the server farm ID
$results = foreach ($subId in $subscriptionIds) {
    Write-Host "Subscription : $subId"
    az resource list `
        --subscription $subId `
        --resource-group $ResourceGroupName `
        --name "$PlanName" `
        --resource-type "Microsoft.Web/serverfarms" `
        --query "[].{SubscriptionId: '$subId', ServerFarmId: id}" `
        -o json | ConvertFrom-Json
}

$results | Format-List
}