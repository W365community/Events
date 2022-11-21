

#Restart Computer
$cloudPCName = 'CPC-Adele-61DG0'
$cloudPC=Get-MgDeviceManagementVirtualEndpointCloudPC -Filter "ManagedDeviceName eq `'$cloudPCName`'"
Restart-MgDeviceManagementVirtualEndpointCloudPc -CloudPCId $cloudPCId

#Resize computer
<#
    https://learn.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-service-plan-reference

    ServicePlan IDs
    3efff3fe-528a-4fc5-b1ba-845802cc764f	Windows 365 Enterprise 2 vCPU 8 GB 128 GB
    545e3611-3af8-49a5-9a0a-b7867968f4b0	Windows 365 Enterprise 2 vCPU 4 GB 128 GB
#>
$cloudPCName = 'CPC-LeeG-D47L2N'
$cloudPC=Get-MgDeviceManagementVirtualEndpointCloudPC -Filter "ManagedDeviceName eq `'$cloudPCName`'"
$ManagedDeviceID = $cloudPC.ManagedDeviceId
$TargetServicePlanId='545e3611-3af8-49a5-9a0a-b7867968f4b0'
Resize-MgDeviceManagementManagedDeviceCloudPc -ManagedDeviceId $ManagedDeviceID  -TargetServicePlanId $TargetServicePlanId

#Restore Snapshot
$CloudPCName = 'CPC-Adele-61DG0'
$cloudPC=Get-MgDeviceManagementVirtualEndpointCloudPC -Filter "ManagedDeviceName eq `'$cloudPCName`'"
$cloudPCId = $cloudPC.Id
$managedDeviceId=$cloudPC.ManagedDeviceId
Get-MgDeviceManagementVirtualEndpointSnapshot -filter "CloudPcID eq `'$CloudPCId`'"
$SnapshotId = 'A0004XSY000_4fc72a00-1a7f-435c-85a5-0a8eb85a0d43'
Restore-MgDeviceManagementManagedDeviceCloudPc -ManagedDeviceId $managedDeviceId -CloudPcSnapshotId $SnapshotId


#Reprovision
$CloudPCName = 'CPC-Adele-61DG0'
$cloudPC=Get-MgDeviceManagementVirtualEndpointCloudPC -Filter "ManagedDeviceName eq `'$cloudPCName`'"
$cloudPCId = $cloudPC.Id
Invoke-MgReprovisionDeviceManagementVirtualEndpointCloudPc -CloudPcId $cloudPCId -OSVersion windows11 -UserAccountType standardUser




# connectivityHistory
Get-MgDeviceManagementVirtualEndpointCloudPcConnectivityHistory -CloudPcId $cloudPCId

#Make user an admin on pc
Rename-MgDeviceManagementVirtualEndpointCloudPcUserAccountType -CloudPCId $cloudPCId -UserAccountType administrator

#Audit Events
Get-MgDeviceManagementVirtualEndpointAuditEvent
