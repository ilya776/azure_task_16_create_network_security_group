param (
    [string]$resourceGroupName = "mate-resources",
    [string]$location = "East US",
    [string]$vnetName = "mate-vnet"
)

# Сабнети
$webSubnetName = "webservers"
$dbSubnetName = "database"
$mgmtSubnetName = "management"

# NSG
$webNsgName = "webservers"
$dbNsgName = "database"
$mgmtNsgName = "management"

# ===== VNET =====
$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
if (-not $vnet) {
    Write-Host "Creating VNet..."
    $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix "10.0.0.0/16"
    Add-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix "10.0.1.0/24" -VirtualNetwork $vnet | Out-Null
    Add-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix "10.0.2.0/24" -VirtualNetwork $vnet | Out-Null
    Add-AzVirtualNetworkSubnetConfig -Name $mgmtSubnetName -AddressPrefix "10.0.3.0/24" -VirtualNetwork $vnet | Out-Null
    $vnet | Set-AzVirtualNetwork | Out-Null
} else {
    Write-Host "VNet already exists, using existing one."
}

# ===== RULES =====
# Shared intra-VNet allow
$allowVNetRule = New-AzNetworkSecurityRuleConfig -Name "AllowVNet" -Priority 200 -Direction Inbound -Access Allow -Protocol * -SourceAddressPrefix VirtualNetwork -DestinationAddressPrefix VirtualNetwork -SourcePortRange * -DestinationPortRange *

# Web (HTTP + HTTPS)
$allowHttpRule = New-AzNetworkSecurityRuleConfig -Name "AllowHTTPFromInternet" -Priority 100 -Direction Inbound -Access Allow -Protocol Tcp -SourceAddressPrefix Internet -DestinationAddressPrefix * -SourcePortRange * -DestinationPortRange 80
$allowHttpsRule = New-AzNetworkSecurityRuleConfig -Name "AllowHTTPSFromInternet" -Priority 110 -Direction Inbound -Access Allow -Protocol Tcp -SourceAddressPrefix Internet -DestinationAddressPrefix * -SourcePortRange * -DestinationPortRange 443

# Management (SSH)
$allowSshRule = New-AzNetworkSecurityRuleConfig -Name "AllowSSHFromInternet" -Priority 100 -Direction Inbound -Access Allow -Protocol Tcp -SourceAddressPrefix Internet -DestinationAddressPrefix * -SourcePortRange * -DestinationPortRange 22

# ===== WEB NSG =====
$webNsg = Get-AzNetworkSecurityGroup -Name $webNsgName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
if (-not $webNsg) {
    Write-Host "Creating Webservers NSG..."
    $webNsg = New-AzNetworkSecurityGroup -Name $webNsgName -ResourceGroupName $resourceGroupName -Location $location -SecurityRules @($allowHttpRule, $allowHttpsRule, $allowVNetRule)
} else {
    Write-Host "Updating Webservers NSG..."
    $webNsg.SecurityRules.Clear()
    $webNsg.SecurityRules.Add($allowHttpRule)
    $webNsg.SecurityRules.Add($allowHttpsRule)
    $webNsg.SecurityRules.Add($allowVNetRule)
    Set-AzNetworkSecurityGroup -NetworkSecurityGroup $webNsg | Out-Null
}

# ===== MANAGEMENT NSG =====
$mgmtNsg = Get-AzNetworkSecurityGroup -Name $mgmtNsgName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
if (-not $mgmtNsg) {
    Write-Host "Creating Management NSG..."
    $mgmtNsg = New-AzNetworkSecurityGroup -Name $mgmtNsgName -ResourceGroupName $resourceGroupName -Location $location -SecurityRules @($allowSshRule, $allowVNetRule)
} else {
    Write-Host "Updating Management NSG..."
    $mgmtNsg.SecurityRules.Clear()
    $mgmtNsg.SecurityRules.Add($allowSshRule)
    $mgmtNsg.SecurityRules.Add($allowVNetRule)
    Set-AzNetworkSecurityGroup -NetworkSecurityGroup $mgmtNsg | Out-Null
}

# ===== DATABASE NSG =====
$dbNsg = Get-AzNetworkSecurityGroup -Name $dbNsgName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
if (-not $dbNsg) {
    Write-Host "Creating Database NSG..."
    $dbNsg = New-AzNetworkSecurityGroup -Name $dbNsgName -ResourceGroupName $resourceGroupName -Location $location -SecurityRules @($allowVNetRule)
} else {
    Write-Host "Updating Database NSG..."
    $dbNsg.SecurityRules.Clear()
    $dbNsg.SecurityRules.Add($allowVNetRule)
    Set-AzNetworkSecurityGroup -NetworkSecurityGroup $dbNsg | Out-Null
}

# ===== ASSOCIATE NSG TO SUBNETS =====
$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName
$vnet.Subnets | ForEach-Object {
    if ($_.Name -eq $webSubnetName) { $_.NetworkSecurityGroup = $webNsg }
    elseif ($_.Name -eq $dbSubnetName) { $_.NetworkSecurityGroup = $dbNsg }
    elseif ($_.Name -eq $mgmtSubnetName) { $_.NetworkSecurityGroup = $mgmtNsg }
}
$vnet | Set-AzVirtualNetwork | Out-Null

Write-Host "Deployment completed successfully."
