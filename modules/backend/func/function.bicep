param name string
param location string
param aspServerFarmResourceId string
param alwaysOn bool
param use32BitWorkerProcess bool
param ftpsState string
param funcStorageAccountName string
param powerShellVersion string
param netFrameworkVersion string

resource name_resource 'Microsoft.Web/sites@2018-11-01' = {
  name: name
  kind: 'functionapp'
  location: location
  tags: {
  }
  properties: {
    name: name
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'powershell'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${funcStorageAccountName};AccountKey=${listKeys(storageAccount.id, '2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
      ]
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
        ]
      }
      use32BitWorkerProcess: use32BitWorkerProcess
      ftpsState: ftpsState
      alwaysOn: alwaysOn
      powerShellVersion: powerShellVersion
      netFrameworkVersion: netFrameworkVersion
    }
    serverFarmId: aspServerFarmResourceId
    clientAffinityEnabled: false
    virtualNetworkSubnetId: null
    httpsOnly: true
    publicNetworkAccess: 'Disabled'
  }
}
