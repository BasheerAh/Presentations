<#
Presentation PowerShell DSC Overview
Author:  Igor Shenderchuk
LinkedIn: https://ua.linkedin.com/in/igorshenderchuk
LocatedAt: https://github.com/Shenderchuk/Presentations
#>

#*********************************
#***    DEMO Preparation       ***
#*********************************

#region Demo Preparation

#Set PowerShell ISE Zoom to 150-175%
$psISE.Options.Zoom = 175

#CLS
Clear-Host

#Create folder for demo files 
If (-not (Test-Path c:\demo_dsc))
    {New-Item -ItemType Directory -Path C:\demo_dsc}

#Save current location to return at the end
Push-Location
#Set location to the demo folder
Set-Location -Path C:\demo_dsc

#Set trusted host to have ability communicate remotely with target PC
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "10.10.10.1" -Force
#Get-Item WSMan:\localhost\Client\TrustedHosts

#Set credentials for connecting to VMs
$Pass = ConvertTo-SecureString "Qwerty123" -AsPlainText -Force
$VM_cred = New-Object System.Management.Automation.PSCredential ("vmuser", $pass)

Write-Output 'PowerShell version on target node:'
Invoke-Command -ComputerName 10.10.10.1 -Credential $VM_cred {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
    $PSVersionTable.PSVersion | Format-Table
}
#Enter-PSSession -ComputerName 10.10.10.1 -Credential $VM_cred

#To comunicate with remote DSC manager need to create CIM instance
$CIM = New-CimSession -ComputerName 10.10.10.1 -Credential $VM_cred

#endregion Demo Preparation

#*********************************
#***       Introducation       ***
#*********************************

#region Introducation
#CLS
Clear-Host

#To see all available commands 
Get-Command -Module PSDesiredStateConfiguration

#Show all built-in DSC Resouces 
Get-DscResource -Module PSDesiredStateConfiguration 

#Show the count 
(Get-DscResource -Module PSDesiredStateConfiguration | Measure-Object).Count

#Show detailed syntax of one DSC resource
Get-DscResource -Name File -Syntax

#Show the MSDN page with detailed information
Start-Process https://msdn.microsoft.com/en-us/powershell/dsc/builtinresource

#Additional DSC Resources
Find-Module -Name x* -includes DscResource



#endregion Introducation

#*********************************
#***      PART 0 Example       ***
#*********************************

#region Simple configuration

#Configuration and Node new keywords in PS, 
#Configuration to describe Desired State, 
#and Node is a target of that configuration.

# First we declare the configuration
Configuration WebServer
{
    #Import Built-in DSC resources
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration' 

    # Then we declare the node we are targeting
    Node "localhost"
    {
        # Then we declare the action we want to perform
        Log ImportantMessage
        {
            Message = "This has done something important"
        }
    }
}

# Compile the Configuration function
TestExample

Start-Process notepad C:\demo_dsc\TestExample\localhost.mof

#endregion Simple configuration


#*********************************
#***      PART 1 LCM           ***
#*********************************

#region Configuration LCM

#Get information about LCM settings
Get-DscLocalConfigurationManager -CimSession $CIM

#Declare the configuration
Configuration SetTheLCM
{
    param 
    (
        [Parameter(Mandatory=$true)]
        [String[]]$NodeName
    )
    Node $NodeName 
    {
        # Declare the settings we want configured
        LocalConfigurationManager
        {
            ConfigurationMode             = "ApplyAndAutoCorrect"
            #ApplyOnly
            #ApplyAndMonitor
            ConfigurationModeFrequencyMins = 30
            RefreshMode                    = "Push"
            RebootNodeIfNeeded             = $true
        }
    }
}

#Compile configuration into META.MOF
SetTheLCM -NodeName 10.10.10.1 -OutputPath c:\demo_dsc 

#View the META.MOF file
Start-Process notepad C:\demo_dsc\10.10.10.1.meta.mof

#Push LCM configuration to target PC
Set-DscLocalConfigurationManager -Path C:\demo_dsc\ -Verbose -CimSession $CIM

#Get information about LCM settings
Get-DscLocalConfigurationManager -CimSession $CIM

#endregion Configuration LCM

#*********************************
#***      PART 2 DSC           ***
#*********************************

#region Configuration DSC

#Check if there are any configuration already
#Check DSC status
Get-DscConfigurationStatus -CimSession $CIM
#Check DSC configuration
Get-DscConfiguration -CimSession $CIM

#region Preration 7Zip installer for demo
#Download 7Zip from vendor site
Invoke-WebRequest -Uri http://www.7-zip.org/a/7z920.msi -OutFile 7z920.msi
#Create new PSDrive for network share on target pc. It's required for file distribution.
New-PSDrive -Name target -PSProvider FileSystem -Root "\\10.10.10.1\C$\Shared" -Credential $VM_cred
#Copy to target PC
Copy-Item -Path C:\demo_dsc\7z920.msi -Destination target: -Force
#endregion Small preration for demo

#region Configuration TestingDSCResources
Configuration TestingDSCResources
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

        Service PrinterSpoller
        {
            Ensure      = "Present"
            Name        = "Spooler"
            StartupType =  "Manual"
            State       = "Stopped"
        }

        WindowsFeature TelnetClient
        {
            Ensure = "Present"
            Name = "Telnet-Client"
        }

        Package Sevenzip
        {
            Ensure     = "Absent"
            Name       = "7-Zip 9.20"
            ProductId  = "{23170F69-40C1-2701-0920-000001000000}"
            Path       = "C:\Shared\7z920.msi"
            LogPath    = "C:\Shared\7z920.msi-install.log"
            Arguments  = 'ARPCOMMENTS="Installed by PowerShell DSC" ARPHELPLINK="" ARPURLUPDATEINFO="" ARPURLINFOABOUT="" ARPNOREPAIR=1 ARPNOMODIFY=1'
            ReturnCode = 0
        }

        File Remove7zipHelpShortcut
        {
            Ensure          = "Absent"
            DestinationPath = "%ProgramData%\Microsoft\Windows\Start Menu\Programs\7-Zip\7-Zip Help.lnk"
            DependsOn = "[Package]Sevenzip"
        }
    } 
}
#endregion Configuration TestingDSCResources

#Compile it to MOF file
TestingDSCResources -Servers 10.10.10.1 -OutputPath c:\demo_dsc

#Show newly created MOF file
notepad c:\demo_dsc\10.10.10.1.mof
 
#Push configuration (MOF) to target node (PC)
Start-DscConfiguration -Wait -Verbose -Force -Path c:\demo_dsc -Credential $VM_cred

#Test DSC configuration
Test-DscConfiguration -CimSession $CIM

#endregion Configuration DSC

#*********************************
#***      CleanUp              ***
#*********************************

#region Demo CleanUp

#Set PowerShell ISE Zoom back to 100%
$psISE.Options.Zoom = 100

#Return to initial location
Pop-Location

#Remove temporary demo folder
Remove-Item -Path C:\demo_dsc -Force -Recurse
#endregion

