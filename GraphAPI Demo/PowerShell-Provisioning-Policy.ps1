
Get-MgDeviceManagementVirtualEndpointGalleryImage |Out-GridView

$Image = Get-MgDeviceManagementVirtualEndpointGalleryImage |`
Where-Object {$_.SkuDisplayName -eq '22H2' -and $_.RecommendedSku -eq 'heavy'`
-and $_.displayName -like 'Windows 11 Enterprise*'}

$ImageDisplayName = $image.displayName
$ImageId = $image.Id

#Get Conection ID
$ConnectionId=(Get-MgDeviceManagementVirtualEndpointOnPremisesConnection).Id
#-----------------------------------

# Demo 1 - create a single provisioning policy
$params = @{
	"@odata.type" = "#microsoft.graph.cloudPcProvisioningPolicy"
	Description = "Azure Join Prov Policy demo 4"
	DisplayName = "Azure Join Prov Policy demo 4"
	DomainJoinConfiguration = @{
		DomainJoinType = "azureADJoin"
		OnPremisesConnectionId = $ConnectionId
	}
	ImageDisplayName = $ImageDisplayName
	ImageId = $ImageId
	ImageType = "gallery"
	OnPremisesConnectionId = $ConnectionId
	WindowsSettings = @{
		Language = "en-US"
	}
}
$ProvPolicy=New-MgDeviceManagementVirtualEndpointProvisioningPolicy -BodyParameter $params

#Create Group
$params = @{
	DisplayName = "Cloud PC Demo 4"
	MailEnabled = $false
	MailNickname = "CloudPCDemo4"
	SecurityEnabled = $true
	Description = "Cloud PC Demo 4"
}

$Group=New-MgGroup -BodyParameter $params
$GroupID = $Group.Id
$AssignmentID = New-Guid

$params = @{
	"@odata.type" = "#microsoft.graph.cloudPcProvisioningPolicyAssignment"
	Assignments = @(
		@{
			Id = "$AssignmentID"
			Target = @{
				"@odata.type" = "microsoft.graph.cloudPcManagementGroupAssignmentTarget"
				GroupId = "$GroupID"
			}
		}
	)
}
$cloudPcProvisioningPolicyId = $ProvPolicy.Id
Set-MgDeviceManagementVirtualEndpointProvisioningPolicy -CloudPcProvisioningPolicyId $cloudPcProvisioningPolicyId -BodyParameter $params

<#
#*************************
#Demo 2 - create with a list of different languages
function Create-ProvisioningPolicy {
    param (
        $Language
    )
    $params2 =@{
        "@odata.type" = "#microsoft.graph.cloudPcProvisioningPolicy"
        Description = "Azure Join Prov Policy $Language"
        DisplayName = "Azure Join Prov Policy $Language"
        DomainJoinConfiguration = @{
            DomainJoinType = "azureADJoin"
            OnPremisesConnectionId = $ConnectionId
        }
        ImageDisplayName = $ImageDisplayName
        ImageId = $ImageId
        ImageType = "gallery"
        OnPremisesConnectionId = $ConnectionId
        WindowsSettings = @{
            Language = "$Language"
        }
	
    }
    New-MgDeviceManagementVirtualEndpointProvisioningPolicy -BodyParameter $params2
}

$Languages = @('en-US','en-GB','es-MX','zh-CN','zh-TW')
ForEach($Lang in $Languages)
{
    Create-ProvisioningPolicy -Language $Lang
}
#>
