Function Start-Lab
{
Connect-AzAccount

Start-AzVM -ResourceGroupName ADLab -Name DC1
Start-AzVM -ResourceGroupName ADLab -Name DC2
Start-AzVM -ResourceGroupName ADLab -Name MemberServer

Write-Host "Login with username ADLabAdmin@ADLab.local \ password MySuperSecurePassword00!!"
$PIP = Get-AzPublicIpAddress
mstsc /v: $PIP.IpAddress 
}

Function Stop-Lab
{
Stop-AzVM -ResourceGroupName ADLab -Name DC1 -Confirm -Force
Stop-AzVM -ResourceGroupName ADLab -Name DC2 -Confirm -Force
Stop-AzVM -ResourceGroupName ADLab -Name MemberServer -Confirm -Force
}
