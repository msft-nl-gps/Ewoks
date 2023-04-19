param applicationGatewayName string = guid(resourceGroup().id)
param vnetName string = ''
param subnetName string = ''
 
@allowed([
  'Standard'  
  'Standard_v2'
  'WAF'  
  'WAF_v2'
])
param tierSkuName string = 'WAF_v2'
 
@allowed([
  'Standard_Small'
  'Standard_Medium'
  'Standard_Large'
  'Standard_v2'
  'WAF_Large'
  'WAF_Medium'
  'WAF_v2'
])
param sizeSkuName string = 'WAF_v2'
 
param minCapacity int = 2
param frontendPort int = 443
 
@allowed([
  'Https'
])
param frontendProtocol string = 'Https'
param backendPort int = 443
 
@allowed([
  'Http'
  'Https'
])
param backendProtocol string = 'Https'
param healthProbeHostName string = ''
param healthProbePath string = '/'
param backendIpAddress string = ''
 
@allowed([
  'Enabled'
  'Disabled'
])
param cookieBasedAffinity string = 'Disabled'
param location string = resourceGroup().location
param httpsListenerNames array = []
param listenerHostName string = ''
param backendPoolHostName string = ''
 
@secure()
param rootCertData string
 
@secure()
param certData string
 
@secure()
param certPassword string

var appGwId = resourceId('Microsoft.Network/applicationGateways', '${applicationGatewayName}')
var appGwIPConfigName = '${applicationGatewayName}-ipc'
var parappGwPublicIpName = '${applicationGatewayName}-pip'
var appGwFrontendIPConfigName = '${applicationGatewayName}-fre-ipc'
var appGwFrontendPortName = '${applicationGatewayName}-fre-port'
var appGwBackendPoolName = '${applicationGatewayName}-bkend-pool'
var appGwHttpsListenerName = '${applicationGatewayName}-https-listener'
var appGwHttpsListenerHostName = listenerHostName
var appGwSSLCertName = '${applicationGatewayName}-ssl-cert'
var appGwSSLCertId = {
  id: '${appGwId}/sslCertificates/${appGwSSLCertName}'
}
var appGwBackendHttpSettingsName = '${applicationGatewayName}-bkend-http-settings'
var appGwBackendHttpSettingsHostName = backendPoolHostName
var appGwHttpsRuleName = '${applicationGatewayName}-rule'
var appGwProbeName = '${applicationGatewayName}-health-probe'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
var appGwPublicIPRef = appGwPublicIpName.id
var appGwProbeRef = '${appGwId}/probes/${appGwProbeName}'
var appGwSize = sizeSkuName
var appGwTier = tierSkuName
var appGwTrustedRootCertName = '${applicationGatewayName}-root-cert'

resource appGwPublicIpName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: parappGwPublicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}
 
resource applicationGatewayName_resource 'Microsoft.Network/applicationGateways@2020-05-01' = {
  name: applicationGatewayName
  location: location
  properties: {
    backendHttpSettingsCollection: [for item in httpsListenerNames: {
      name: '${item}-${appGwBackendHttpSettingsName}'
      properties: {
        port: backendPort
        protocol: backendProtocol
        cookieBasedAffinity: cookieBasedAffinity
        hostName: '${item}${appGwBackendHttpSettingsHostName}'
        probeEnabled: true
        probe: {
          id: appGwProbeRef
        }
        trustedRootCertificates: [
          {
            id: '${appGwId}/trustedRootCertificates/${appGwTrustedRootCertName}'
          }
        ]
      }
   }]
    httpListeners: [for item in httpsListenerNames: {
      name: '${item}-${appGwHttpsListenerName}'
      properties: {
        frontendIPConfiguration: {
          id: '${appGwId}/frontendIPConfigurations/${appGwFrontendIPConfigName}'
        }
        frontendPort: {
          id: '${appGwId}/frontendPorts/${appGwFrontendPortName}'
        }
        protocol: frontendProtocol
        sslCertificate: appGwSSLCertId
        hostName: '${item}${appGwHttpsListenerHostName}'
      }
    }]
    requestRoutingRules: [for item in httpsListenerNames: {
      name: '${item}-${appGwHttpsRuleName}'
      properties: {
        ruleType: 'Basic'
        httpListener: {
          id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, '${item}-${appGwHttpsListenerName}')
        }
        backendAddressPool: {
          id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, appGwBackendPoolName)
        }
        backendHttpSettings: {
          id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, '${item}-${appGwBackendHttpSettingsName}')
        }
      }
    }]
    sku: {
      name: appGwSize
      tier: appGwTier
    }
    autoscaleConfiguration: {
      minCapacity: minCapacity
    }
    trustedRootCertificates: [
      {
        name: appGwTrustedRootCertName
        properties: {
          data: rootCertData
        }
      }
    ]
    sslCertificates: [
      {
        name: appGwSSLCertName
        properties: {
          data: certData
          password: certPassword
        }
      }
    ]
    gatewayIPConfigurations: [
      {
        name: appGwIPConfigName
        properties: {
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: appGwFrontendIPConfigName
        properties: {
          publicIPAddress: {
            id: appGwPublicIPRef
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: appGwFrontendPortName
        properties: {
          port: frontendPort
        }
      }
    ]
    probes: [
      {
        name: appGwProbeName
        properties: {
          protocol: backendProtocol
          path: healthProbePath
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
          host: healthProbeHostName
          port: backendPort
        }
      }
    ]
    backendAddressPools: [
      {
        name: appGwBackendPoolName
        properties: {
          backendAddresses: [
            {
              ipAddress: backendIpAddress
            }
          ]
        }
      }
    ]
  }
}
