$ResourceGroup = "rg"
$Location = "westus2"
$NicName = "" # Use your actual current active NIC name
$PublicIpName = "DevMachineOCAI-pip"

# 1. Create Public IP
Write-Host "Creating Public IP..." -ForegroundColor Cyan
$PublicIp = New-AzPublicIpAddress -Name $PublicIpName -ResourceGroupName $ResourceGroup -Location $Location -AllocationMethod Static -Sku Standard

# 2. Assign Public IP to NIC
Write-Host "Attaching Public IP to NIC..." -ForegroundColor Cyan
$Nic = Get-AzNetworkInterface -Name $NicName -ResourceGroupName $ResourceGroup
$Nic.IpConfigurations[0].PublicIpAddress = $PublicIp
Set-AzNetworkInterface -NetworkInterface $Nic | Out-Null

Write-Host "Public IP attached! Your VM is now accessible via the public IP." -ForegroundColor Green

# 3. Output the Public IP address to connect with
(Get-AzPublicIpAddress -Name $PublicIpName -ResourceGroupName $ResourceGroup).IpAddress