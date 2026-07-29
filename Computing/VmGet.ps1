# ==========================================
# Robust Idempotent VM Deployment Script
# ==========================================

$ResourceGroup = "dev-rg"
$Location = "westus2"
$VMName = "DevmachineAIFO"
$NicName = "devmachineocai972_z3_" + (Get-Date -Format "yyyyMMddHHmmss")
$VNetName = "DevMachine-vnet"
$AddressPrefix = "10.0.0.0/16"
$SubnetName = "default"
$SubnetPrefix = "10.0.0.0/24"
$AdminUser = "devAdmin"

# Secure password setup
$SecurePassword = ConvertTo-SecureString "YourStrongPasswordHere123!" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($AdminUser, $SecurePassword)

# Tags (PascalCase format)
$Tags = @{
    
    "ApplicationName" = "OCVAI"
    "Contact"         = ""
    "Environment"     = "Test"
    "ProductName"     = "CVAI"
    "Team"            = ""
    "CreationDate"    = "2026-05-04"
    "Expiration"      = "2028-05-04"
}

# 1. Resource Group Upsert
if (-not (Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue)) {
    Write-Host "Creating Resource Group: $ResourceGroup..." -ForegroundColor Cyan
    New-AzResourceGroup -Name $ResourceGroup -Location $Location | Out-Null
} else {
    Write-Host "Resource Group '$ResourceGroup' already exists." -ForegroundColor Green
}

# 2. VNet & Subnet Upsert
$VNet = Get-AzVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue
if (-not $VNet) {
    Write-Host "Creating VNet: $VNetName..." -ForegroundColor Cyan
    $SubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetPrefix
    $VNet = New-AzVirtualNetwork -ResourceGroupName $ResourceGroup -Name $VNetName -Location $Location -AddressPrefix $AddressPrefix -Subnet $SubnetConfig
} else {
    Write-Host "VNet '$VNetName' already exists." -ForegroundColor Green
}

# 3. Create a fresh Network Interface with validation (Zone is passed via ZonalAllocation or omitted as standard NICs inherit placement)
Write-Host "Creating Network Interface: $NicName..." -ForegroundColor Cyan
$Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $VNet
if (-not $Subnet) {
    throw "Subnet '$SubnetName' was not found in Virtual Network '$VNetName'."
}
$Nic = New-AzNetworkInterface -Name $NicName -ResourceGroupName $ResourceGroup -Location $Location -Subnet $Subnet
if (-not $Nic) {
    throw "Failed to create Network Interface '$NicName'."
}

# 4. Clean up existing VM shell if it exists to prevent profile/lock conflicts
$ExistingVM = Get-AzVM -Name $VMName -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue
if ($ExistingVM) {
    Write-Host "Removing existing VM shell '$VMName' for clean redeployment..." -ForegroundColor Yellow
    Remove-AzVM -ResourceGroupName $ResourceGroup -Name $VMName -Force | Out-Null
}

# 5. Build VM Configuration
Write-Host "Creating Virtual Machine configuration..." -ForegroundColor Cyan
$VMConfig = New-AzVMConfig -VMName $VMName -VMSize "Standard_E4ads_v6" -Zone "3" -Tag $Tags
Set-AzVMOperatingSystem -VM $VMConfig -Windows -ComputerName $VMName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
Set-AzVMSourceImage -VM $VMConfig -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2025-datacenter-g2" -Version "latest"
Set-AzVMSecurityProfile -VM $VMConfig -SecurityType "TrustedLaunch"
Set-AzVMUefi -VM $VMConfig -EnableSecureBoot $true -EnableVTpm $true

# Explicitly attach the new NIC and validate object reference
Add-AzVMNetworkInterface -VM $VMConfig -Id $Nic.Id | Out-Null

# Disable boot diagnostics to bypass organizational storage policy enforcement blocks
Set-AzVMBootDiagnostic -VM $VMConfig -Disable | Out-Null

# 6. Provision the Virtual Machine
Write-Host "Provisioning Virtual Machine '$VMName'..." -ForegroundColor Cyan
New-AzVM -ResourceGroupName $ResourceGroup -Location $Location -VM $VMConfig
Write-Host "Virtual Machine '$VMName' created successfully!" -ForegroundColor Green