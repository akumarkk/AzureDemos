# Configuration
$OrgUrl     = "https://dev.azure.com/org"
$Project    = "CraftProducts"
$TargetVar  = "BlobUrl"

# Get all variable groups in the project
# We pass the --org and --project parameters explicitly
$Groups = az pipelines variable-group list --org $OrgUrl --project $Project --output json | ConvertFrom-Json

Write-Host "Searching for '$TargetVar' in $Project..." -ForegroundColor Cyan

foreach ($Group in $Groups) {
    Write-Host "Searching $Group..."
    # Get details for the specific group
    $GroupDetails = az pipelines variable-group show --id $Group.id --org $OrgUrl --project $Project --output json | ConvertFrom-Json
    
    # Check if the variable exists in the group's 'variables' object
    # Using PSObject properties handles the dynamic nature of variable names
    if ($GroupDetails.variables.PSObject.Properties.Name -contains $TargetVar) {
        Write-Host "MATCH FOUND: '$TargetVar' exists in group: $($Group.name) (ID: $($Group.id))" -ForegroundColor Green
    }
}