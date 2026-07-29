# ==========================================
# PowerShell Script to Whitelist IP for RDP / All Ports
# ==========================================

$ResourceGroup = "rg"
$Location = "westus2"
$NSGName = "DevMachineOCAI-nsg"
$RuleName = "Allow_All_Ports_RDP"
$YourIP = "" # Replace with your public IP address (e.g., "203.0.113.50" or use "*" for any)
$NicName = "devmachineocai972_z3" # Replace with your active NIC name if different

Write-Host "Step 1: Creating or retrieving Network Security Group (NSG)..." -ForegroundColor Cyan
$NSG = Get-AzNetworkSecurityGroup -Name $NSGName -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue
if (-not $NSG) {
    $NSG = New-AzNetworkSecurityGroup -Name $NSGName -ResourceGroupName $ResourceGroup -Location $Location
}

Write-Host "Step 2: Adding inbound security rule for RDP / all ports..." -ForegroundColor Cyan
$NSG | Add-AzNetworkSecurityRuleConfig -Name $RuleName `
    -Description "Allow inbound traffic from specified IP" `
    -Access Allow `
    -Protocol * `
    -Direction Inbound `
    -Priority 100 `
    -SourceAddressPrefix $YourIP `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange * | Set-AzNetworkSecurityGroup | Out-Null

Write-Host "Step 3: Associating NSG with Network Interface '$NicName'..." -ForegroundColor Cyan
$Nic = Get-AzNetworkInterface -Name $NicName -ResourceGroupName $ResourceGroup
$Nic.NetworkSecurityGroup = $NSG
Set-AzNetworkInterface -NetworkInterface $Nic | Out-Null

Write-Host "Network Security Group configured and associated successfully!" -ForegroundColor Green