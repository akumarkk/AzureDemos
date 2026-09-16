param (
    [Parameter(Mandatory=$true)]
    [string]$Subscription,

    [Parameter(Mandatory=$false)]
    [string]$SecretName = ""
)

Set-AzContext -Subscription $Subscription

$Vaults = Get-AzKeyVault
$Results = foreach ($Vault in $Vaults) {
    $VaultName = $Vault.VaultName
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

if ($Results) {
    $Results | Format-Table -AutoSize
} else {
    Write-Host "Secret '$SecretName' was not found in any Key Vault within subscription '$Subscription'." -ForegroundColor Yellow
}