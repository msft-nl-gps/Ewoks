@description('Describes plan\'s pricing tier')
@allowed([
  'F1'
  'B1'
  'B2'
  'B3'
])
param aspSKU string = 'B1'
@description('Service tier of the resource SKU.')
@allowed([
  'Free'
  'Basic'
])
param aspSKUTier string = 'Basic'
@description('The number of server farms')
param aspCount int = 1
@description('Scaling worker count.')
param aspTargetWorkerCount int = 1
@description('If true, this App Service Plan will perform availability zone balancing.')
param aspZoneRedundant bool = false
@description('ServerFarm supports ElasticScale. Apps in this plan will scale as if the ServerFarm was ElasticPremium sku')
param aspElasticScaleEnabled bool = false
@description('Kind of resource.')
param aspKind string = 'functionapp'
@description('Current number of instances assigned to the resource.')
param aspCapacity int = 1
@description('The location of the resource')
param aspLocation string = resourceGroup().location
@description('The operating system type of the resource')
@allowed([
  'Windows'
  'Linux'
])
param aspOsType string = 'Windows'

resource resAppServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = [for i in range(0, aspCount): {
  name: '${replace(resourceGroup().name, '-', '')}asp${padLeft((i + 1), 2, '0')}'
  location: aspLocation
  sku: {
    name: aspSKU
    tier: aspSKUTier
    capacity: aspCapacity
  }
  kind: aspKind
  properties: {
    targetWorkerCount: aspTargetWorkerCount
    zoneRedundant: aspZoneRedundant
    elasticScaleEnabled: aspElasticScaleEnabled
    reserved: aspOsType == 'Linux' ? true : false
  }
}]

output aspServerFarmResourceId array = [for i in range(0, aspCount): resourceId('Microsoft.Web/serverfarms', '${replace(resourceGroup().name, '-', '')}asp${padLeft((i + 1), 2, '0')}')]
output aspReserved array = [for i in range(0, aspCount): resAppServicePlan[i].properties.reserved]
