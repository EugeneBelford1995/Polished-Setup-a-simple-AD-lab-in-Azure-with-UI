#Basic menu structure was borrowed from https://adamtheautomator.com/powershell-menu/

#Set the pre-reqs first
$CurrentPath = (Get-Location).Path

If(Get-Module | Where-Object {$_.Name -like "Az.*"})
{Write-Host "Az Modules are already installed."}
Else
{
Write-Host "Installing AD Modules, this may take a few minutes."
Install-Module -Name Az -Repository PSGallery -Force
Update-Module -Name Az -Force
Connect-AzAccount

Install-Module -Name PSReadline
Install-Module -Name Az.Tools.Predictor
Enable-AzPredictor -AllSession
}

Connect-AzAccount

# --- Show the menu ---
function Show-Menu {
    param (
        [string]$Title = "Mishky's Setup a Simple AD Lab Tool"
    )
    Clear-Host
    Write-Host "================ $Title ================"
    
    Write-Host "1. Set everything up in Azure (create the VMs, config the NSGs, create & assign the public IP, etc)"
    Write-Host "2. Config the DC1 VM"
    Write-Host "3. Config the DC2 VM, Part 1"
    Write-Host "4. Config the DC2 VM, Part 2"
    Write-Host "5. Config the MemberServer VM, Part 1"
    Write-Host "6. Config the MemberServer VM, Part 2"
    Write-Host "Q. Press 'Q' to quit."
}


# --- Set everything up in Azure (create the VMs, config the NSGs, create & assign the public IP, etc) ---
function Setup-RG {

Write-Host "Please be patient, this part will take 10 - 15 minutes."

If(Get-AzResourceGroup -Name ADLab)
{Write-Host "Resource Group already exists, creating VMs"}
Else {New-AzResourceGroup -Name ADLab}

Try
{

# --- Create & setup networking on DC1 ---

[string]$userName = 'ADLabAdmin'
[string]$userPassword = 'MySuperSecurePassword00!!'
# Convert to SecureString
[securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
[pscredential]$credObject2 = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

#Create DC1
New-AzVM -ResourceGroupName "ADLab" -Name "DC1" -Location "East US" -Image Win2019Datacenter -Size "Standard_B2s" -VirtualNetworkName "ADLabVN"-SubnetName "ADLabSubnet" -Credential $credObject2
Start-Sleep -Seconds 60

#All ports that a DC uses in the NSG
$RGname="ADLab"
$rulename="Allow_DC_Ports"
$nsgname="DC1"

# Get the NSG resource
$nsg = Get-AzNetworkSecurityGroup -Name $nsgname -ResourceGroupName $RGname

# Add the inbound security rule.
$nsg | Add-AzNetworkSecurityRuleConfig -Name $rulename -Description "Allow app port" -Access Allow `
    -Protocol * -Direction Inbound -Priority 3891 -SourceAddressPrefix "*" -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange (53, 88, 123, 389, 445, 464, 636, 3268, 3269, '49152-65535') 

# Update the NSG.
$nsg | Set-AzNetworkSecurityGroup

#Set the DC1 NIC to a static IP (Check your VM's private IP after it's created & set the private IP to that)
$PrivateDCIP = (Get-AzNetworkInterface -ResourceGroupName ADLab -Name DC1).IpConfigurations.PrivateIpAddress
$DCNIC = Get-AzNetworkInterface -ResourceGroupName ADLab -Name DC1
$DCNIC.IpConfigurations[0].PrivateIpAddress = $PrivateDCIP
$DCNIC.IpConfigurations[0].PrivateIpAllocationMethod = "Static"
$DCNIC.DnsSettings.DnsServers.Add("127.0.0.1")
#$DCNIC.DnsSettings.DnsServers.Add("$PrivateDCIP")
$DCNIC.DnsSettings.DnsServers.Add("8.8.8.8")
Set-AzNetworkInterface -NetworkInterface $DCNIC

Start-Sleep -Seconds 60

# --- Create & setup networking on DC2 ---

[string]$userName = 'ADLabLocalAdmin'
[string]$userPassword = 'MySuperSecurePassword00!!'
# Convert to SecureString
[securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
[pscredential]$credObject3 = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

#Create DC2
New-AzVM -ResourceGroupName "ADLab" -Name "DC2" -Location "East US" -Image Win2019Datacenter -Size "Standard_DS1_v2" -VirtualNetworkName "ADLabVN"-SubnetName "ADLabSubnet" -Credential $credObject3
Start-Sleep -Seconds 60

#All ports that a DC uses in the NSG
$RGname="ADLab"
$rulename="Allow_DC_Ports"
$nsgname="DC2"

# Get the NSG resource
$nsg = Get-AzNetworkSecurityGroup -Name $nsgname -ResourceGroupName $RGname

# Add the inbound security rule.
$nsg | Add-AzNetworkSecurityRuleConfig -Name $rulename -Description "Allow app port" -Access Allow `
    -Protocol * -Direction Inbound -Priority 3891 -SourceAddressPrefix "*" -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange (53, 88, 123, 389, 445, 464, 636, 3268, 3269, '49152-65535') 

# Update the NSG.
$nsg | Set-AzNetworkSecurityGroup

#Set the DC2 NIC to a static IP (Check your VM's private IP after it's created & set the private IP to that)
$PrivateDCIP2 = (Get-AzNetworkInterface -ResourceGroupName ADLab -Name DC2).IpConfigurations.PrivateIpAddress
$DC2NIC = Get-AzNetworkInterface -ResourceGroupName ADLab -Name DC2
$DC2NIC.IpConfigurations[0].PrivateIpAddress = $PrivateDCIP2
$DC2NIC.IpConfigurations[0].PrivateIpAllocationMethod = "Static"
$DC2NIC.DnsSettings.DnsServers.Add("$PrivateDCIP")
#$DCNIC.DnsSettings.DnsServers.Add("127.0.0.1")
$DC2NIC.DnsSettings.DnsServers.Add("8.8.8.8")
Set-AzNetworkInterface -NetworkInterface $DC2NIC

Start-Sleep -Seconds 60

# --- Create & setup networking on the "client" ---

[string]$userName = 'ADLabLocalAdmin'
[string]$userPassword = 'MySuperSecurePassword00!!'
# Convert to SecureString
[securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
[pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

New-AzVM -ResourceGroupName "ADLab" -Name "MemberServer" -Location "East US" -Image Win2019Datacenter -Size "Standard_DS1_v2" -VirtualNetworkName "ADLabVN" -SubnetName "ADLabSubnet" -Credential $credObject
Start-Sleep -Seconds 60

#Create a public IP
New-AzPublicIpAddress -Name "ADLabPIP" -ResourceGroupName "ADLab" -AllocationMethod Static -Location "East US"
Start-Sleep -Seconds 60
$PIP = Get-AzPublicIpAddress -Name ADLabPIP
$vnet = Get-AzVirtualNetwork -Name "ADLabVN" -ResourceGroupName "ADLab"
$subnet = Get-AzVirtualNetworkSubnetConfig -Name "ADLabSubnet" -VirtualNetwork $vnet
$VM = Get-AzVm -Name "MemberServer" -ResourceGroupName "ADLab"
$NIC = Get-AzNetworkInterface -ResourceGroupName "ADLab" -Name "MemberServer"
$NIC | Set-AzNetworkInterfaceIpConfig -Name "MemberServer" -PublicIPAddress $PIP -Subnet $subnet
$NIC | Set-AzNetworkInterface

Start-Sleep -Seconds 120

Update-AzVm -ResourceGroupName "ADLab" -VM $VM
Start-Sleep -Seconds 60

#Set the client's DNS (Check the DC VM's private IP to be sure)
$PublicNIC = Get-AzNetworkInterface -ResourceGroupName ADLab -Name MemberServer
$PublicNIC.DnsSettings.DnsServers.Add("$PrivateDCIP")
$PublicNIC.DnsSettings.DnsServers.Add("$PrivateDCIP2")
$PublicNIC.DnsSettings.DnsServers.Add("8.8.8.8")
Set-AzNetworkInterface -NetworkInterface $PublicNIC

Start-Sleep -Seconds 120

Start-AzVM -ResourceGroupName ADLab -Name MemberServer
Start-AzVM -ResourceGroupName ADLab -Name DC1
Start-AzVM -ResourceGroupName ADLab -Name DC2

} #Close the Try
Catch {Write-Host "Error, VM may already exist"}
} #Close the function


# --- Config the DC1 VM ---
function Config-DC1 {
Try
{

Invoke-AzVMRunCommand -VMName "DC1" -ResourceGroupName "ADLab" -CommandId "RunPowerShellScript" -ScriptPath ".\New Forest.ps1"

} #Close the try
Catch {Write-Host "You made a typo somewhere in your input, or you lack the rights required (WriteDACL). Please enumerate again."}
} #Close the function


# --- Option 3, Config the DC2 VM, Part 1 ---
function Config-DC2P1 {
Try 
{

Invoke-AzVMRunCommand -VMName "DC2" -ResourceGroupName "ADLab" -CommandId "RunPowerShellScript" -ScriptPath ".\Config DC2 P1.ps1"

} #Close the try
Catch {Write-Host "Error, make sure the VM was started."}
} #Close the function


# --- Option 4, Config the DC2 VM, Part 2 ---
function Config-DC2P2 {
Try
{

Invoke-AzVMRunCommand -VMName "DC2" -ResourceGroupName "ADLab" -CommandId "RunPowerShellScript" -ScriptPath ".\Config DC2 P2.ps1"

} #Close the try
Catch {Write-Host "Error, make sure the VM was started."}
} #Close the function


# --- Option 5, Config the MemberServer VM, Part 1 ---
function Config-MemberServerP1 {
Try
{

Write-Host "Wait for this to join MemberServer to the ADLab domain & restart, then run it again to install RSAT"
Invoke-AzVMRunCommand -ResourceGroupName ADLab -VMName MemberServer -CommandId "RunPowerShellScript" -ScriptPath ".\Config the Client.ps1"

} #Close the try
Catch {Write-Host "Error, make sure the VM was started."}
} #Close the function


# --- Option 6, Config the MemberServer VM, Part 2 ---
function Config-MemberServerP2 {

#Now that DC1 & DC2 are both on the ADLab domain, make both of them DNS servers on each other
$PrivateDCIP2 = (Get-AzNetworkInterface -ResourceGroupName ADLab -Name DC2).IpConfigurations.PrivateIpAddress
$DC2NIC = Get-AzNetworkInterface -ResourceGroupName ADLab -Name DC2
$DC2NIC.DnsSettings.DnsServers.Add("127.0.0.1")
Set-AzNetworkInterface -NetworkInterface $DC2NIC

$DCNIC = Get-AzNetworkInterface -ResourceGroupName ADLab -Name DC1
$DCNIC.DnsSettings.DnsServers.Add("$PrivateDCIP2")
Set-AzNetworkInterface -NetworkInterface $DCNIC

#Lastly, RDP into the client
#username = ADLab\ADLabAdmin
#password = MySuperSecurePassword00!!
Write-Host "Login with username ADLabAdmin@ADLab.local \ password MySuperSecurePassword00!!"
mstsc /v: $PIP.IpAddress 

#Knock out whatever AD lab tasks you want, ideally using PowerShell_ISE instead of the GUI :P
#Don't forget to shutdown both VMs whenever you're done labbing!
#If you're extra paranoid, pull your public IP from your home RTR and set it the only allowed IP in the MemberServer's NSG rule for RDP access.
#I only left my VMs running for a few minutes at a time just to verify this setup worked.

Try {Start-Process MSEdge "https://medium.com/@happycamper84/how-to-setup-an-ad-lab-in-azure-48a19ff5081b"}
Catch {Write-Host "Error, your browser is broken, or you ran this on a disconnected system."}
} #Close the function


# --- Get the user's menu choice & run the proper function ---
Do
 {
    Show-Menu
    $selection = Read-Host "Please make a selection"
    switch ($selection)
    {
    
    '1'
    {
        'You chose option #1'
        Setup-RG
    } 
    
    '2' 
    {
        'You chose option #2'
        Config-DC1
    }
    
    '3'
    {
        'You chose option #3'
        Config-DC2P1
    }

    '4'
    {
        'You chose option #4.'
        Config-DC2P2
    }

    '5'
    {
        'You chose option #5'
        Config-MemberServerP1
    }

    '6'
    {
        'You chose option #6'
        Config-MemberServerP2
    }

    }
    pause
 }
 Until ($selection -eq 'q')

 Write-Host "We hope you enjoyed Mishka's Setup a Simple AD Lab in Azure tool."
 Write-Host "Please leave any suggestions in the comments of the Medium writeup on Mishka's tool."
 Set-Location $CurrentPath