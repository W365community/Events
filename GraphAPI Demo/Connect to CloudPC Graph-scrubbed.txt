#Connect to CloudPC Graph
$CloudTestAppID = 'xxxx'
$CloudTestSecretValue = 'xxxx'
$TenantId = 'xxxx'

#Install MSAL.PS module for all users (requires admin rights)
#Install-Module MSAL.PS -Force
If(get-InstalledModule MSal.ps)
{
    write-host "MSAL.ps is already installed"
}Else 
{
    Install-Module MSAL.PS -Force
}
Import-Module -Name MSal.ps -Global -Force
$modules = @("Microsoft.Graph.Users.Actions",
                "Microsoft.Graph.Groups",
                "Microsoft.Graph.DeviceManagement.Administration",
                "Microsoft.Graph.DeviceManagement.Actions" 
            )

foreach ($Module in $modules)
{
    If(Get-InstalledModule -Name $Module)
    {
        Write-Output "$module is already installed"
    }else{
        Install-Module -Name $Module -Force
    }
}

Import-Module -Name $modules -Scope Global -Force

#Sign in to graph
$Token = Get-MsalToken -TenantId $TenantId -ClientId $CloudTestAppID  -ClientSecret ($CloudTestSecretValue | ConvertTo-SecureString -AsPlainText -Force)
#Connect to Graph using access token
Connect-Graph -AccessToken $Token.AccessToken
Select-MgProfile -Name beta

