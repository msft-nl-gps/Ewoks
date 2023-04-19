targetScope = 'subscription'

metadata name = 'ALZ Bicep - Resource Group creation module'
metadata description = 'Module used to create Resource Groups for Azure Landing Zones'

@sys.description('Azure Region where Resource Group will be created.')
param parLocation string

@sys.description('Name of Resource Group to be created.')
param parResourceGroupName string

@sys.description('Tags you would like to be applied to all resources in this module.')
param parTags object = {}

resource resResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  location: parLocation
  name: parResourceGroupName
  tags: parTags
}

output outResourceGroupName string = resResourceGroup.name
output outResourceGroupId string = resResourceGroup.id
