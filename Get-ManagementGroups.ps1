$ManagementGroups = Get-AzManagementGroup -GroupName $MGObjectID -Expand -Recurse | Select-Object Name,DisplayName,Children


$OutputManagementGroups = $ManagementGroups



