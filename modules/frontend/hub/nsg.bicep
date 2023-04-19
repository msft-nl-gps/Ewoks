param nsgSecurityRules array = [
  {
    description: 'empty'
  }
]
@description('The location of the resource')
param nsgLocation string

@minValue(1)
@maxValue(99)
param nsgIndex int

resource modNsg 'Microsoft.Network/networkSecurityGroups@2020-07-01' = {
  name: '${replace(resourceGroup().name, '-', '')}nsg${padLeft(nsgIndex, 2, '0')}'
  location: nsgLocation
}

resource mogNsgSR 'Microsoft.Network/networkSecurityGroups/securityRules@2020-07-01' = [for (item, i) in nsgSecurityRules: if (nsgSecurityRules[0].description != 'empty') {
  name: toLower('${replace(resourceGroup().name, '-', '')}nsg${padLeft(nsgIndex, 2, '0')}/${item.direction}-${item.access}-${padLeft((i + 1), 2, '0')}')
  properties: item
  dependsOn: [
    modNsg
  ]
}]

output nsgResourceId string = modNsg.id
