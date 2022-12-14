#Deprovision Cloud PC
#Remove license, remove from group, end grace period, send email

#License Permissions User.ReadWrite.All, Directory.ReadWrite.All
#Group Permissions GroupMember.ReadWrite.All, Group.ReadWrite.All and Directory.ReadWrite.All
#CloudPC Permissions CloudPC.ReadWrite.All

#********************************
#region variables
$modules = @("Microsoft.Graph.Users.Actions",
                "Microsoft.Graph.Groups",
                "Microsoft.Graph.DeviceManagement.Administration",
                "Microsoft.Graph.DeviceManagement.Actions" )
$UserUPN = "LeeG@xxx.onmicrosoft.com"
$GroupName = 'CloudPC Azure Join Prov Policy en-US'
$SKUID = "e2aebe6c-897d-480f-9d62-fff1381581f7"
$SMTPServer = 'xxx.mail.protection.outlook.com'
$MailFrom ='CloudPC@xxx.onmicrosoft.com'
$Subject = "Cloud PC was Removed"

$Body = @"
<body>
<h1>Your new Cloud PC was removed.</h1>
<p></p>
Your Cloud PC has been deleted.  You no longer have access to the computer.</p>
</body>
"@
#endregion variables

#region Prepare Graph
#Install MSAL.PS module for all users (requires admin rights)
#Install-Module MSAL.PS -Force
Import-Module MSAL.PS

#Generate Access Token to use in the connection string to MSGraph
$AppId = '36e14d83-5202-4d9d-80b1-0b149bed391a'
$TenantId = '075c4074-0ff3-4ceb-958d-467fd274763a'
$ClientSecret = 'Vos8Q~UrgfMPotBMl-MHGavN~cy7u5H2Hm5GkaB5'
$Token = Get-MsalToken -TenantId $TenantId -ClientId $AppId -ClientSecret ($ClientSecret | ConvertTo-SecureString -AsPlainText -Force)
#Connect to Graph using access token
Connect-Graph -AccessToken $Token.AccessToken
Import-Module -Name $modules
Select-MgProfile beta
#endregion Prepare Graph
$UserUPN = 'AdeleV@xxx.onmicrosoft.com'
$GroupName = 'CloudPC Azure Join Prov Policy en-US'
$SKUID = '226ca751-f0a4-4232-9be5-73c02a92555e' #2 cPu 4 GB 128 GB
$GroupID = (Get-MgGroup -Filter "DisplayName eq `'$groupName`'").Id
$UserID = (get-mguser -Filter "UserPrincipalName eq `'$UserUPN`'").Id

#Remove License
Set-MgUserLicense -UserId $UserUPN -AddLicenses @() -RemoveLicenses @{SkuId = $SKUID} -Verbose

#Remove from Group
Remove-MgGroupMemberByRef -GroupId $groupId -DirectoryObjectId $UserID 
#computer should now be in grace status
$Status = (Get-MgDeviceManagementVirtualEndpointCloudPC -Filter "UserPrincipalName eq `'$userUPN`'").Status
$CloudPCID = (Get-MgDeviceManagementVirtualEndpointCloudPC -Filter "UserPrincipalName eq `'$userUPN`'").Id

If($Status -eq 'inGracePeriod')
{
    Stop-MgDeviceManagementVirtualEndpointCloudPcGracePeriod  -CloudPcId $CloudPCID
}
#Check Provisioning Status
do {
    Start-Sleep -Seconds 60 
    $Status = (Get-MgDeviceManagementVirtualEndpointCloudPC -Filter "UserPrincipalName eq `'$userUPN`'").Status    
} until ($Status -ne "deprovisioning")

#Send Email when de provisioned
Send-MailMessage -To $UserUPN -From $MailFrom -Subject $Subject -BodyAsHtml $Body -SmtpServer $SMTPServer

$DeletedMachines = Get-MgDeviceManagementVirtualEndpointAuditEvent -Filter "ActivityOperationType eq `'delete`'"
$today = Get-Date
$DeleteDateLookingFor = $today.AddDays(-15)

ForEach($machine in $DeletedMachines)
{
    if($machine.ActivityDateTime -eq $DeleteDateLookingFor)
    {
        Send-MailMessage -To $UserUPN -From $MailFrom -Subject $Subject -BodyAsHtml $Body -SmtpServer $SMTPServer
    } 
}


#Send email to graceperiod computers
$ComputersInGrace = Get-MgDeviceManagementVirtualEndpointCloudPC -Filter "Status eq `'inGracePeriod`'"
$ExpireDate = $ComputersInGrace.GracePeriodEndDateTime
$Subject = "Cloud PC is Expiring"
$Body = @"
<body>
<h1>Your new Cloud PC is scheduled to be deleted.</h1>
<p></p>
Your Cloud PC is scheduled to be deleted on $ExpireDate. Contact Tech Support to restore the computer.</p>
</body>
"@

forEach($computer in $ComputersInGrace)
{
    $EmailTo = $computer.UserPrincipalName
    Send-MailMessage -To $EmailTo -From $MailFrom -Subject $Subject -BodyAsHtml $Body -SmtpServer $SMTPServer
}
