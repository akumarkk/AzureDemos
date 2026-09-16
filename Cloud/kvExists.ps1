param (
    [Parameter(Mandatory=$true)]
    [string]$Subscription,

    [Parameter(Mandatory=$false)]
    [string]$SecretName = ""
)

Set-AzContext -Subscription $Subscription

$env:AZURE_CLIENTS_SHOW_BREAKING_CHANGE_WARNINGS = $false
Update-AzConfig -DisplayBreakingChangeWarning $false -Scope Process

$Vaults = Get-AzKeyVault
$TotalVaults = $Vaults.Count
$CurrentCount = 0

$Results = foreach ($Vault in $Vaults) {
    $CurrentCount++
    $VaultName = $Vault.VaultName

    Write-Progress -Activity "Checking Key Vaults for secret '$SecretName'" `
                   -Status "Checking $VaultName ($CurrentCount of $TotalVaults)" `
                   -PercentComplete (($CurrentCount / $TotalVaults) * 100)

    $Secret = Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName -ErrorAction SilentlyContinue
    if ($Secret) {
        [PSCustomObject]@{
            VaultName  = $VaultName
            SecretName = $Secret.Name
            Enabled    = $Secret.Enabled
            Created    = $Secret.Created
            Updated    = $Secret.Updated
        }
    }
}

# Complete the progress bar
Write-Progress -Activity "Checking Key Vaults for secret '$SecretName'" -Completed

if ($Results) {
    $Results | Format-Table -AutoSize
} else {
    Write-Host  "Secret '$SecretName' was not found in any Key Vault within subscription '$Subscription'." -ForegroundColor DarkYellow
}