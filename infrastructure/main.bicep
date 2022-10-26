param location string
param prefix string
param vnetSettings object = {
  addressPrefixes: [
    '10.0.0.0/20'
  ]
  // https://www.davidc.net/sites/default/subnets/subnets.html
  subnets: [
    {
      name: 'subnet1'
      addressPrefix: '10.0.0.0/22'
    }
    {
      name: 'acaAppSubnet'
      addressPrefix: '10.0.4.0/22'
    }
    {
      name: 'acaControlPlaneSubnet'
      addressPrefix: '10.0.8.0/22'
    }
  ]
}
param containerVersion string
param tier string = 'Consumption'
param capacity int = 0
param externalResourcesRg string
param certKeyVaultName string
param certKeyVaultUrl string

module core 'core.bicep' = {
  name: 'core'
  params: {
    prefix: prefix
    location: location
    vnetSettings: vnetSettings
  }
}

resource secretKeyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: core.outputs.SecretKeyVaultName
}

module aca 'aca.bicep' = {
  name: 'aca'
  dependsOn: [
    core
  ]
  params: {
    prefix: prefix
    location: location
    vNetId: core.outputs.vNetId
    containerRegistryName: core.outputs.ContainerRegistryName
    containerRegistryUserName: core.outputs.ContainerRegistryUserName
    containerVersion: containerVersion
    cosmosAccountName: core.outputs.CosmosAccountName
    cosmosContainerName: core.outputs.CosmosStateContainerName
    cosmosDbName: core.outputs.CosmosDbName
    containerRegistryPassword: secretKeyVault.getSecret(core.outputs.ContainerRegistrySecret)
  }
}

module apim 'apim.bicep' = {
  name: 'apim'
  dependsOn:[
    core
  ]
  params:{
    prefix: prefix
    location: location
    certKeyVaultName:certKeyVaultName
    certKeyVaultUrl:certKeyVaultUrl
    externalResourcesRg: externalResourcesRg
    capacity: capacity
    tier: tier
  }
}
