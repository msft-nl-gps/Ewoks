param kvtTenantId string

param kvtDefaultAction string = 'Deny'

@allowed([
  'standard'
  'premium'
])
param kvtSkuName string = 'standard'
param kvtAccessPolicies array
param kvtEnabledForDeployment bool = true
param kvtEnabledForDiskEncryption bool = true
param kvtEnabledForTemplateDeployment bool = true
param kvtCount int = 1
param kvtCustomerId string

@description('Option to add a workload name to create unique keyvault name')
param kvtWorkload string = 'none'
@description('The location of the resource')
param kvtLocation string = resourceGroup().location

var kvtName = (kvtWorkload == 'none') ? '${replace(toLower(resourceGroup().name), '-', '')}${toLower(kvtCustomerId)}kvt' : '${replace(toLower(resourceGroup().name), '-', '')}${toLower(kvtWorkload)}${toLower(kvtCustomerId)}kvt'

resource resKeyvault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = [for i in range(0, kvtCount): {
  name: '${kvtName}${padLeft((i + 1), 2, '0')}'
  location: kvtLocation
  properties: {
    tenantId: kvtTenantId
    sku: {
      family: 'A'
      name: kvtSkuName
    }
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: kvtDefaultAction
      ipRules: [
        {
          value: '20.123.167.188/32'
        }
      ]
      virtualNetworkRules: []
    }
    accessPolicies: kvtAccessPolicies
    enabledForDeployment: kvtEnabledForDeployment
    enabledForDiskEncryption: kvtEnabledForDiskEncryption
    enabledForTemplateDeployment: kvtEnabledForTemplateDeployment
  }
}]

output kvtResourceId array = [for i in range(0, kvtCount): resourceId('Microsoft.KeyVault/vaults', '${kvtName}${padLeft((i + 1), 2, '0')}')]
