# Polished-Setup-a-simple-AD-lab-in-Azure-with-UI
Menu driven, user friendly tool for setting up a simple AD lab in Azure.

Simply save all these files in the same folder, then run 'Setup with a Menu.ps1' while your present working directory is the folder where everything is save.
Run each menu option in order, 1 through 6.
The first one takes 10 - 15 minutes as it is creating & configuring everything in Azure. 
The others take a few minutes each as they are only configuring the VMs.

Once you are done with the lab you can run Cleanup.ps1 to remove everything from Azure.

If you get locked out of the MemberServer VM via RDP due to Group Policy and NLA, just run

Invoke-AzVMRunCommand -VMName “MemberServer” -ResourceGroupName “ADLab” -CommandId “DisableNLA”

to get back in.

Enjoy, and please leave any comments, tips, suggestions, etc here or in the comments on https://medium.com/@happycamper84/how-to-setup-an-ad-lab-in-azure-48a19ff5081b

We are open to feedback!
