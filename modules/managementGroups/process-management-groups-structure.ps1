$Structure = ConvertFrom-Json -InputObject (Get-Content -Path "./modules/managementGroups/management-groups-structure.json" -Raw)
$Structure

function createUpdateMG ($mg, $parentId) {
    $managementGroup = Get-AzManagementGroup -GroupName $mg.id -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    if ($null -eq $managementGroup) {
        Write-Output ("Creating Management Group [{0}] with name [{1}] under parent ID [{2}]." -f $mg.id, $mg.name, $parentId)
        $out = New-AzManagementGroup -GroupName $mg.id -DisplayName $mg.name -parentId $parentId -WarningAction SilentlyContinue
    }
    else {
        Write-Output ("Updating Management Group [{0}] with name [{1}] under parent ID [{2}]" -f $mg.id, $mg.name, $parentId)
        switch ($managementGroup.id) {
            $global:TopManagementGroupId {
                $out = Get-AzManagementGroup -GroupName $mg.id -WarningAction SilentlyContinue
            }
            Default {
                $out = Update-AzManagementGroup -GroupName $mg.id -DisplayName $mg.name -parentId $parentId -WarningAction SilentlyContinue
            }
        }
        
    }
    $GitHubOutPutVariableName = $out.DisplayName.Replace(' ', '_').Replace('-', '_').Replace('.','_') + '_MG_Resource_Id' 
    $GitHubOutPutVariableValue = $out.Id
    Write-Output "$GitHubOutPutVariableName=$GitHubOutPutVariableValue" >> $Env:GITHUB_OUTPUT
    return $out
}

function updateStructure ($object, $parentId) {
    switch ($object.type) {
        'subscription' { 
            Write-Output ("Processing Subscription ID [{0}] with name [{1}]..." -f $object.id, $object.name)
            $subscription = Get-AzSubscription -SubscriptionId $object.id -WarningAction SilentlyContinue -ErrorAction Stop
            if ($null -ne $subscription) {
                New-AzManagementGroupSubscription -SubscriptionId $subscription.Id -GroupName $parentId.split('/')[-1] -WarningAction SilentlyContinue -ErrorAction Stop | Out-Null
            }
        }
        'managementGroup' { 
            Write-Output  ("Processing Management Group ID [{0}] with name [{1}]..." -f $object.id, $object.name)
            $mg = createUpdateMG -mg $object -parentId $parentId
            if ($null -ne $object.children) {
                foreach ($child in $object.children) {
                    updateStructure -object $child -parentId $mg.Id
                }
            }
        }
    }
}

$TopManagementGroup = Get-AzManagementGroup -GroupName $structure.id -WarningAction SilentlyContinue -ErrorAction Stop
$global:TopManagementGroupId = $TopManagementGroup.Id


if ($null -ne $TopManagementGroupId) {
    foreach ($element in $Structure) {
        updateStructure -object $element -parentId $TopManagementGroupId
    }
}


Write-Output "top_management_group_id=$($TopManagementGroup.Name)" >> $Env:GITHUB_OUTPUT
Get-Content $Env:GITHUB_OUTPUT