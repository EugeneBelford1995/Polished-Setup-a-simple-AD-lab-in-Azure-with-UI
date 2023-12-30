Connect-AzAccount
$RGName = "ADLab"

$Confirmation = Read-Host "Are you sure you want To proceed? This will perform cleanup and remove all IPs, VMs, vDisks, vNICs, NSGs, & vNets in the resourcegroup $RGName"
If ($Confirmation -eq 'Yes')
{

Try
{
Get-AzResourceGroup -Name $RGName | Out-Null

#Detach the public IP
$NIC = Get-AzNetworkInterface -ResourceGroupName $RGName | Where-Object {$_.IpConfigurationsText -like "*PublicIpAddress*"}
$IPConfigName = (Get-AzNetworkInterface -ResourceGroupName $RGName -Name $NIC.Name).IpConfigurations.Name
$vnet = Get-AzVirtualNetwork -ResourceGroupName $RGName
$subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet
$NIC | Set-AzNetworkInterfaceIpConfig -Name $IPConfigName -PublicIPAddress $null -Subnet $subnet
$NIC | Set-AzNetworkInterface

#Remove resources, aka wipe out the entire lab
Get-AzPublicIpAddress -ResourceGroupName $RGName | Remove-AzPublicIpAddress
Get-AzVM -ResourceGroupName $RGName | Remove-AzVM
Get-AzDisk -ResourceGroupName $RGName | Remove-AzDisk
Get-AzNetworkInterface -ResourceGroupName $RGName | Remove-AzNetworkInterface
Get-AzNetworkSecurityGroup -ResourceGroupName $RGName | Remove-AzNetworkSecurityGroup
Get-AzVirtualNetwork -ResourceGroupName $RGName | Remove-AzVirtualNetwork
}

Catch
{Write-Host "The simple AD lab Resource Group does not exist."}

}

Elseif($Confirmation -eq 'No')
{Write-Host "Exiting"}
Else
{Write-Host "Please specify 'Yes' if you wish to continue. Anything else will exit"}