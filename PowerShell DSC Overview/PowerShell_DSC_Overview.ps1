<#
Presentation PowerShell DSC Overview
Author:  Igor Shenderchuk
LinkedIn: https://ua.linkedin.com/in/igorshenderchuk
#>

#region Demo Preparation

#Set PowerShell ISE Zoom to 150%

$psISE.Options.Zoom = 150

#Create folder for demo files 
If (-not (Test-Path c:\demo_dsc))
    {New-Item -ItemType Directory -Path C:\demo_dsc}

#Save current location to return at the end
Push-Location
#Set location to the demo folder
Set-Location -Path C:\demo_dsc

#Set trusted host to have ability communicate remotely with target PC
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "10.10.10.1" -Force
Get-Item WSMan:\localhost\Client\TrustedHosts

#ENTER credentials for connecting to VMs
$VM_cred = Get-Credential -Message "Enter VM credentials"  -UserName "vmuser"

#endregion 


#Check PS version of VMs (should be at least 4.0)
Invoke-Command -ComputerName 10.10.10.1 -Credential $VM_cred {
    $PSVersionTable.PSVersion
}
#endregion


#Enter-PSSession -ComputerName 10.10.10.1 -Credential $VM_cred


#Show all built-in DSC Resouces 
Clear-Host
Get-DscResource -Module PSDesiredStateConfiguration 

#Show the count 
(Get-DscResource -Module PSDesiredStateConfiguration | Measure-Object).Count

#Show detailed syntax of one DSC resource
Get-DscResource -Name File -Syntax

#Show the MSDN page with detailed information
Start-Process https://msdn.microsoft.com/en-us/powershell/dsc/builtinresource


#Check if there are any configuration already

#To comunicate with remote DSC manager need to create CIM instance
$CIM = New-CimSession -ComputerName 10.10.10.1 -Credential $VM_cred

#Check DSC status
Get-DscConfigurationStatus -CimSession $CIM
#Check DSC configuration
Get-DscConfiguration -CimSession $CIM



#region Configuration TestingDSCResourcesLogAndRegistry
Configuration TestingDSCResourcesLogAndRegistry
{ 
    param
    (
        [Parameter(Mandatory=$true)]
        [String[]]$Servers
    )
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration' 
  
    Node $Servers
    { 
        Log startconfig 
        { 
            # The message below gets written to the Microsoft-Windows-Desired State Configuration/Analytic log 
            Message = "Starting the file resource with ID MyProfile user : $env:username" 
        } 

        Registry Key
        {
            Ensure = "Present"
            Key = "HKLM:\SOFTWARE\DSCForWindows"
            ValueName = "DSC"
            ValueType = "String"
            ValueData = "Enabled"
        }

    } 
}
#endregion

#Compile it to MOF file
TestingDSCResourcesLogAndRegistry -Servers 10.10.10.1 -OutputPath c:\demo_dsc

#Show newly created MOF file
notepad c:\demo_dsc\10.10.10.1.mof
 
#Push configuration (MOF) to target node (PC)
Start-DscConfiguration -Wait -Verbose -Force -Path c:\demo_dsc -Credential $VM_cred






#To see all available commands launch
Get-Command -Module PSDesiredStateConfiguration

#Separate the environmental config from the structural config

#

#region Cleanup and Reset Demo

#region Demo cleanup

#Set PowerShell ISE Zoom back to 100%
$psISE.Options.Zoom = 100

#Return to initial location
Pop-Location

#Remove temporary demo folder
Remove-Item -Path C:\demo_dsc -Force -Recurse
#endregion

