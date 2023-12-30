[string]$userName = 'ADLabAdmin@ADLab.local'
[string]$userPassword = 'MySuperSecurePassword00!!'
# Convert to SecureString
[securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
[pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

If($env:USERDOMAIN -ne "ADLab")
{Add-Computer -DomainName ADLab.local -Credential $credObject -restart -force}

Else{Get-WindowsFeature | Where-Object {$_.Name -like "*RSAT*"} | Install-WindowsFeature -IncludeAllSubFeature}

#$TargetMachine = "MemberServer"
#(Get-WmiObject -class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -ComputerName $TargetMachine -Filter "TerminalName='RDP-tcp'").SetUserAuthenticationRequired(0)

#Run commands & PS1s on Azure VMs
#Start-AzVM -ResourceGroupName "ADLab" -Name "MemberServer"
#Invoke-AzVMRunCommand -VMName "MemberServer" -ResourceGroupName "ADLab" -CommandId "RunPowerShellScript" -ScriptPath ".\Config the Client.ps1"