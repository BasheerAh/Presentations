#region Demo prep

#Create folder for demo files 
If (-not (Test-Path c:\demo_dsc))
    {New-Item -ItemType Directory -Path C:\demo_dsc}

#Save current location to return at the end
Push-Location

#Set location to the demo folder
Set-Location -Path C:\demo_dsc

#ENTER credentials for connecting to VMs
$VM_cred = Get-Credential -Message "Enter VM credentials" -UserName "vmuser"

#endregion

#Install additional DSC Resource for condiguring IIS
If ((Find-Module -name xWebAdministration | Measure-Object).Count -lt 1)
    {Install-Module -Name xWebAdministration -Force}

#Confirm if it was installed correctly
Get-DscResource


#Create new PSDrive for network share on target pc. It's required for file distribution.
New-PSDrive -Name target -PSProvider FileSystem -Root "\\10.10.10.1\C$\Shared" -Credential $VM_cred

#To use new DSC resource it should be also installed on target PC,
#it could be done through Install-Module if internet exists on target PC

#Download it to c:\demo_dsc
Save-Module -Name xWebAdministration -Path C:\demo_dsc

#Copy it to Target PC
Copy-Item -Path C:\demo_dsc\xWebAdministration -Destination target: -Recurse -Force
#Copy it to Modules folder on TargetPC
Invoke-Command -ComputerName 10.10.10.1 -Credential $VM_cred {
    Copy-Item -Path C:\Shared\xWebAdministration -Destination $env:ProgramFiles\WindowsPowerShell\Modules -Recurse -Force
    Get-DscResource -Module xWebAdministration | Format-Table
}

#Set execution policy
Invoke-Command -ComputerName 10.10.10.1 -Credential $VM_cred {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
}


#Preparation before DSC config:
#Need to copy all required source files to folder on TargetPC
git clone https://github.com/Nitij/DotNetAngularChat.git

#Check if we downloaded asp.net application
ls 

#Copy ASP.NET application to Target PC
Copy-Item -Path C:\demo_dsc\DotNetAngularChat\Chat -Destination target: -Recurse -Force

#region Configuration ChatOnIIS
Configuration ChatOnIIS
{ 
    param
    (
        [Parameter(Mandatory=$true)]
        [String[]]$Server
    )
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration' 
    Import-DscResource –ModuleName 'xWebAdministration' 
  
    Node $Server
    { 
        #Our ASP.NET website requires IIS and ASP.NET 4.5 to function. We can use the WindowsFeature DSC resource to install IIS and ASP.NET.
        WindowsFeature IIS
        {
            Ensure = "Present"
            Name   = "Web-Server"
        }
        
        WindowsFeature IISManagementConsole
        {
            Ensure    = "Present"
            Name      = "Web-Mgmt-Tools"
            DependsOn = "[WindowsFeature]IIS"
        }

        WindowsFeature NetExt45
        {
            Ensure    = "Present"
            Name      = "Web-Net-Ext45"
            DependsOn = "[WindowsFeature]IIS"
        }

        WindowsFeature WebASPNet45
        {
            Ensure    = "Present"
            Name      = "Web-ASP-NET45"
            DependsOn = "[WindowsFeature]IIS"
        }

        WindowsFeature ASPNET45
        {
            Ensure    = "Present"
            Name      = "NET-Framework-45-ASPNET"
            DependsOn = "[WindowsFeature]IIS"
        }
        
        #We need to stop the Default website so that we can use port 80 for our new website. We can use the xWebSite DSC resource to accomplish this for us.
        xwebsite defaultsite
        {
          Ensure       = 'Present'
          Name         = 'Default Web Site'
          State        = 'Stopped'
          DependsOn    = "[WindowsFeature]IIS"
        }        

        #The next step is to copy the compiled code and assets to a specified directory and then create an application pool and website. 
        #The directory we copy to needs to be present before we copy, so we need to ensure its created. 
        #With the File DSC resource we can copy in the same statement we're ensuring the directory is there.
        File WebsiteFolder
        {
            ensure          = 'Present'
            Sourcepath      = 'c:\\Shared\\Chat'
            Destinationpath = 'c:\\inetpub\\chatoniis'
            Recurse         = $true
            Type            = 'Directory'
        }

        xwebapppool NewWebAppPool
        {
            name                      = 'ChatAppPool'
            ensure                    = 'Present'
            managedruntimeversion     = 'v4.0'
            logeventonrecycle         = 'Memory'
            restartmemorylimit        = '1000'
            restartprivatememorylimit = '1000'
            identitytype              = 'ApplicationPoolIdentity'
            state                     = 'Started'
            DependsOn                 = "[WindowsFeature]IIS"
        }

        #Finally, we create the actual website using the xWebSite DSC resource and tie it to the directory and application pool we create above.

        xwebsite NewWebSite
        {
            ensure          = 'Present'
            name            = 'ChatOnIIS'
            state           = 'Started'
            physicalpath    = 'c:\inetpub\chatoniis'
            applicationpool = 'ChatAppPool'
            bindinginfo     = @(
                        MSFT_xWebBindingInformation
                        {
                            Port                  = 80
                            Protocol              = 'HTTP'
                            
                        }
                        )
            DependsOn       = "[File]WebsiteFolder", "[xwebapppool]NewWebAppPool"
        }

    } 
}

#endregion

#Compile configuration into MOF
ChatOnIIS -Server 10.10.10.1 -OutputPath C:\demo_dsc -Verbose

#Check compiled MOF
Notepad .\10.10.10.1.mof

#Push configuration to target PC
Start-DscConfiguration -Wait -Force -Verbose -Path C:\demo_dsc -Credential $VM_cred

Start-Process http://10.10.10.1

#region Demo cleanup



#Set PowerShell ISE Zoom back to 100%
$psISE.Options.Zoom = 100

#Return to initial location
Pop-Location

#Remove temporary network drive
Remove-PSDrive -Name target -Force

#Remove temporary demo folder
Remove-Item -Path C:\demo_dsc -Force -Recurse

#endregion