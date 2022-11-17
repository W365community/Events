#Add License to user account
#License Permissions User.ReadWrite.All, Directory.ReadWrite.All
#Group Permissions GroupMember.ReadWrite.All, Group.ReadWrite.All and Directory.ReadWrite.All

#SKUID/e2aebe6c-897d-480f-9d62-fff1381581f7
#CPC_E_2C_8GB_128GB
#$GroupName = 'CloudPC Azure Join Prov Policy en-US'
#$GroupID = (Get-MgGroup -Filter "DisplayName eq `'$groupName`'").Id



#Search the web for detailed syntax 
#https://learn.microsoft.com/en-us/graph/api/user-assignlicense?view=graph-rest-1.0&tabs=powershell
#Add User to group
#https://learn.microsoft.com/en-us/graph/api/group-post-members?view=graph-rest-1.0&tabs=http

#********************************
#region variables
#$modules = @("Microsoft.Graph.Users.Actions","Microsoft.Graph.Groups"   )
#$UserUPN = "LeeG@xxx.onmicrosoft.com"
$UserUPN = "AlexW@xxx.onmicrosoft.com"
$UserID = (get-mguser -Filter "UserPrincipalName eq `'$UserUPN`'").Id
#$SKUID = 'e2aebe6c-897d-480f-9d62-fff1381581f7' # 2 cpu 8 GB 128 GB
$SKUID = '226ca751-f0a4-4232-9be5-73c02a92555e' #2 cPu 4 GB 128 GB
$SMTPServer = 'xxx.mail.protection.outlook.com'
$MailFrom ='CloudPC@xxx.onmicrosoft.com'
$Subject = "New Cloud PC is available"

$Body = @"
<body>
<h1>Your new Cloud PC is ready.</h1>
<p></p>
Visit https://windows365.microsoft.com to access the computer.</p>
</body>
"@
#endregion variables
<#
#Connect to CloudPC Graph
$CloudTestAppID = '7649c0f4-b00f-43cb-a1fc-a27b641f5395'
$CloudTestSecretValue = '.go8Q~mIcfzWAb4RYdVtr-~vv6MKQjb3i-~iNbsA'
$TenantId = '075c4074-0ff3-4ceb-958d-467fd274763a'

#Install MSAL.PS module for all users (requires admin rights)
#Microsoft Authentication Library
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
#endregion Prepare Graph
#>

#Add License Parameters
$params = @{
	AddLicenses = @(
		@{
			DisabledPlans = @()
			SkuId = $SKUID
		}
	)
	RemoveLicenses = @()
}
#Add License
Set-MgUserLicense -UserId $UserUPN -BodyParameter $params 


#Add Group Parameters
$params = @{
	"@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/{$($UserID)}"
}
#Add to Group
New-MgGroupMemberByRef -GroupId $groupId -BodyParameter $params -Verbose

#Check Provisioning Status
do {
    Start-Sleep -Seconds 60 
    $Status = (Get-MgDeviceManagementVirtualEndpointCloudPC -Filter "UserPrincipalName eq `'$userUPN`'").Status    
} until ($Status -eq "provisioned")

#Send Email when provisioned
Send-MailMessage -To $UserUPN -From $MailFrom -Subject $Subject -BodyAsHtml $Body -SmtpServer $SMTPServer
