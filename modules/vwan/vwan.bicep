metadata name = 'ALZ Bicep - Azure vWAN Connectivity Module'
metadata description = 'Module used to set up vWAN Connectivity'

@sys.description('Region in which the resource group was created.')
param parLocation string = resourceGroup().location

@sys.description('Prefix value which will be prepended to all resource names.')
param parCompanyPrefix string = 'alz'

@sys.description('Azure Firewall Tier associated with the Firewall to deploy.')
@allowed([
  'Standard'
  'Premium'
])
param parAzFirewallTier string = 'Standard'

@sys.description('Switch to enable/disable Virtual Hub deployment.')
param parVirtualHubEnabled bool = true

@sys.description('Switch to enable/disable Azure Firewall DNS Proxy.')
param parAzFirewallDnsProxyEnabled bool = true

@sys.description('Prefix Used for Virtual WAN.')
param parVirtualWanName string = '${parCompanyPrefix}-vwan-${parLocation}'

@sys.description('Prefix Used for Virtual WAN Hub.')
param parVirtualWanHubName string = '${parCompanyPrefix}-vhub-${parLocation}'

@sys.description('''Array Used for multiple Virtual WAN Hubs deployment. Each object in the array represents an individual Virtual WAN Hub configuration. Add/remove additional objects in the array to meet the number of Virtual WAN Hubs required.

- `parVpnGatewayEnabled` - Switch to enable/disable VPN Gateway deployment on the respective Virtual WAN Hub.
- `parExpressRouteGatewayEnabled` - Switch to enable/disable ExpressRoute Gateway deployment on the respective Virtual WAN Hub.
- `parAzFirewallEnabled` - Switch to enable/disable Azure Firewall deployment on the respective Virtual WAN Hub.
- `parVirtualHubAddressPrefix` - The IP address range in CIDR notation for the vWAN virtual Hub to use.
- `parHubLocation` - The Virtual WAN Hub location.
- `parHubRoutingPreference` - The Virtual WAN Hub routing preference. The allowed values are `ASN`, `VpnGateway`, `ExpressRoute`.
- `parVirtualRouterAutoScaleConfiguration` - The Virtual WAN Hub capacity. The value should be between 2 to 50.

''')
param parVirtualWanHubs array = [ {
    parAzFirewallEnabled: true
    parVirtualHubAddressPrefix: '10.100.0.0/23'
    parHubLocation: 'westeurope'
    parHubRoutingPreference: 'ExpressRoute'
    parVirtualRouterAutoScaleConfiguration: 2 //minimum capacity should be between 2 to 50
  }
]

@sys.description('Azure Firewall Name.')
param parAzFirewallName string = '${parCompanyPrefix}-fw-${parLocation}'

@allowed([
  '1'
  '2'
  '3'
])
@sys.description('Availability Zones to deploy the Azure Firewall across. Region must support Availability Zones to use. If it does not then leave empty.')
param parAzFirewallAvailabilityZones array = []

@sys.description('Azure Firewall Policies Name.')
param parAzFirewallPoliciesName string = '${parCompanyPrefix}-azfwpolicy-${parLocation}'

@sys.description('Tags you would like to be applied to all resources in this module.')
param parTags object = {}

// Virtual WAN resource
resource resVwan 'Microsoft.Network/virtualWans@2021-08-01' = {
  name: parVirtualWanName
  location: parLocation
  tags: parTags
  properties: {
    allowBranchToBranchTraffic: true
    allowVnetToVnetTraffic: true
    disableVpnEncryption: false
    type: 'Standard'
  }
}

resource resVhub 'Microsoft.Network/virtualHubs@2022-01-01' = [for hub in parVirtualWanHubs: if (parVirtualHubEnabled && !empty(hub.parVirtualHubAddressPrefix)) {
  name: '${parVirtualWanHubName}-${hub.parHubLocation}'
  location: hub.parHubLocation
  tags: parTags
  properties: {
    addressPrefix: hub.parVirtualHubAddressPrefix
    sku: 'Standard'
    virtualWan: {
      id: resVwan.id
    }
    virtualRouterAutoScaleConfiguration:{
      minCapacity: hub.parVirtualRouterAutoScaleConfiguration
    }
    hubRoutingPreference: hub.parHubRoutingPreference
  }
}]

resource resVhubRouteTable 'Microsoft.Network/virtualHubs/hubRouteTables@2022-01-01' = [for (hub, i) in parVirtualWanHubs: if (parVirtualHubEnabled && hub.parAzFirewallEnabled) {
  parent: resVhub[i]
  name: 'defaultRouteTable'
  properties: {
    labels: [
      'default'
    ]
    routes: [
      {
        name: 'default-to-azfw'
        destinations: [
          '0.0.0.0/0'
        ]
        destinationType: 'CIDR'
        nextHop: (parVirtualHubEnabled && hub.parAzFirewallEnabled) ? resAzureFirewall[i].id : ''
        nextHopType: 'ResourceID'
      }
    ]
  }
}]

resource resFirewallPolicies 'Microsoft.Network/firewallPolicies@2022-05-01' = if (parVirtualHubEnabled && parVirtualWanHubs[0].parAzFirewallEnabled) {
  name: parAzFirewallPoliciesName
  location: parLocation
  tags: parTags
  properties: {
    dnsSettings: {
      enableProxy: parAzFirewallDnsProxyEnabled
    }
    sku: {
      tier: parAzFirewallTier
    }
  }
}

resource resAzureFirewall 'Microsoft.Network/azureFirewalls@2022-05-01' = [for (hub, i) in parVirtualWanHubs: if ((parVirtualHubEnabled) && (hub.parAzFirewallEnabled)) {
  name: '${parAzFirewallName}-${hub.parHubLocation}'
  location: hub.parHubLocation
  tags: parTags
  zones: (!empty(parAzFirewallAvailabilityZones) ? parAzFirewallAvailabilityZones : null)
  properties: {
    hubIPAddresses: {
      publicIPs: {
        count: 1
      }
    }
    sku: {
      name: 'AZFW_Hub'
      tier: parAzFirewallTier
    }
    virtualHub: {
      id: parVirtualHubEnabled ? resVhub[i].id : ''
    }
    firewallPolicy: {
      id: (parVirtualHubEnabled && hub.parAzFirewallEnabled) ? resFirewallPolicies.id : ''
    }
  }
}]

// Output Virtual WAN name and ID
output outVirtualWanName string = resVwan.name
output outVirtualWanId string = resVwan.id

// Output Virtual WAN Hub name and ID
output outVirtualHubName array = [ for (hub, i) in parVirtualWanHubs: {
  virtualhubname: resVhub[i].name
  virtualhubid: resVhub[i].id
}]

output outVirtualHubId array = [ for (hub, i) in parVirtualWanHubs: {
  virtualhubid: resVhub[i].id
}]
