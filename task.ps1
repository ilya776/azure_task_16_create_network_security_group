# --------------------------
# Configuration
# --------------------------
$location = "uksouth"
$resourceGroupName = "mate-resources"   # ✅ Fix: must be mate-resources

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

$webRuleHttp = New-AzNetworkSecurityRuleConfig -Name "AllowHTTPFromInternet" -Priority 100 -Direction Inbound -Access Allow -Protocol Tcp `
    -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80

$webRuleHttps = New-AzNetworkSecurityRuleConfig -Name "AllowHTTPSFromInternet" -Priority 110 -Direction Inbound -Access Allow -Protocol Tcp `
    -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 443

$webRuleVnet = New-AzNetworkSecurityRuleConfig -Name "AllowVNet" -Priority 200 -Direction Inbound -Access Allow -Protocol * `
    -SourceAddressPrefix VirtualNetwork -SourcePortRange * -DestinationAddressPrefix VirtualNetwork -DestinationPortRange *

$webNSG = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $webSubnetName -SecurityRules @($webRuleHttp,$webRuleHttps,$webRuleVnet)

# --------------------------
# NSG for Management
# --------------------------
Write-Host "Creating management NSG..."

$mgmtRuleSsh = New-AzNetworkSecurityRuleConfig -Name "AllowSSHFromInternet" -Priority 120 -Direction Inbound -Access Allow -Protocol Tcp `
    -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22

$mgmtRuleVnet = New-AzNetworkSecurityRuleConfig -Name "AllowVNet" -Priority 200 -Direction Inbound -Access Allow -Protocol * `
    -SourceAddressPrefix VirtualNetwork -SourcePortRange * -DestinationAddressPrefix VirtualNetwork -DestinationPortRange *

$mgmtNSG = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $mngSubnetName -SecurityRules @($mgmtRuleSsh,$mgmtRuleVnet)

# --------------------------
# NSG for Database
# --------------------------
Write-Host "Creating database NSG..."

$dbRuleVnet = New-AzNetworkSecurityRuleConfig -Name "AllowVNet" -Priority 200 -Direction Inbound -Access Allow -Protocol * `
    -SourceAddressPrefix VirtualNetwork -SourcePortRange * -DestinationAddressPrefix VirtualNetwork -DestinationPortRange *

$dbNSG = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $dbSubnetName -SecurityRules @($dbRuleVnet)

# --------------------------
# Virtual Network + Subnets
# --------------------------
Write-Host "Creating virtual network with subnets ..."
$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange -NetworkSecurityGroup $webNSG
$dbSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange -NetworkSecurityGroup $dbNSG
$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange -NetworkSecurityGroup $mgmtNSG

New-AzVirtualNetwork -Name $virtualNetworkName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -AddressPrefix $vnetAddressPrefix `
    -Subnet $webSubnet,$dbSubnet,$mngSubnet

Write-Host "✅ All resources created successfully"
