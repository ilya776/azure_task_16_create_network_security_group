# --------------------------
# Configuration
# --------------------------
$location = "uksouth"
$resourceGroupName = "mate-azure-task-16"

$virtualNetworkName = "todoapp"
$vnetAddressPrefix = "10.20.30.0/24"

$webSubnetName = "webservers"
$webSubnetIpRange = "10.20.30.0/26"

$dbSubnetName = "database"
$dbSubnetIpRange = "10.20.30.64/26"

$mngSubnetName = "management"
$mngSubnetIpRange = "10.20.30.128/26"

# --------------------------
# Resource Group
# --------------------------
Write-Host "Creating a resource group $resourceGroupName ..."
New-AzResourceGroup -Name $resourceGroupName -Location $location -Force

# --------------------------
# NSG for Webservers
# --------------------------
Write-Host "Creating webservers NSG..."
$webRule = New-AzNetworkSecurityRuleConfig -Name "AllowWeb" -Priority 100 -Direction Inbound -Access Allow -Protocol Tcp `
    -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80,443

$webNSG = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $webSubnetName -SecurityRules $webRule

# --------------------------
# NSG for Management
# --------------------------
Write-Host "Creating management NSG..."
$mgmtRule = New-AzNetworkSecurityRuleConfig -Name "AllowSSH" -Priority 100 -Direction Inbound -Access Allow -Protocol Tcp `
    -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22

$mgmtNSG = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $mngSubnetName -SecurityRules $mgmtRule

# --------------------------
# NSG for Database
# --------------------------
Write-Host "Creating database NSG..."
# Порожній NSG (немає правил)
$dbNSG = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $dbSubnetName

Write-Host "Creating virtual network with subnets ..."
$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange -NetworkSecurityGroup $webNSG
$dbSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange -NetworkSecurityGroup $dbNSG
$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange -NetworkSecurityGroup $mgmtNSG

New-AzVirtualNetwork -Name $virtualNetworkName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -AddressPrefix $vnetAddressPrefix `
    -Subnet $webSubnet,$dbSubnet,$mngSubnet

Write-Host "All resources created successfully ✅"
