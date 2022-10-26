param location string
param prefix string
param tier string = 'Consumption'
param capacity int = 0
param externalResourcesRg string
param certKeyVaultName string
param certKeyVaultUrl string

resource apimUserIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${prefix}-apim0-mi'
  location: location
}

module apimExternalResources 'externalResources.bicep' = {
  name: '${prefix}-apim-external'
  scope: resourceGroup(externalResourcesRg)
  params: {
    zoneName: 'lambdatoys.com'
    recordName: '${prefix}-apim'
    cName: '${prefix}-apim.azure-api.net'
    managedIdentityId: apimUserIdentity.properties.principalId
    keyVaultName: certKeyVaultName
  }
}

resource apiManagementInstance 'Microsoft.ApiManagement/service@2021-08-01' = {
  name: '${prefix}-apim'
  location: location
  dependsOn: [
    apimExternalResources
  ]
  sku: {
    capacity: capacity
    name: tier
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${apimUserIdentity.id}': {}
    }
  }
  properties: {
    virtualNetworkType: 'None'
    publisherEmail: 'support@lambdatoys.com'
    publisherName: 'Lambda Toys'
    hostnameConfigurations: [
      {
        hostName: '${prefix}-apim.lambdatoys.com'
        type: 'Proxy'
        certificateSource: 'KeyVault'
        keyVaultId: certKeyVaultUrl
        identityClientId: apimUserIdentity.properties.clientId
      }
    ]
  }
}

resource lambdaStoreApi 'Microsoft.ApiManagement/service/apis@2021-08-01' = {
  name: '${apiManagementInstance.name}/LambdaStore'
  properties: {
    format: 'swagger-json'
    value: loadTextContent('../resources/lambdaStoreSwagger.json')
    path: 'lambdaToyStore'
  }
}

resource toyProduct 'Microsoft.ApiManagement/service/products@2021-08-01' = {
  name: '${apiManagementInstance.name}/toyProduct'
  properties: {
    displayName: 'Toy Product'
    description: 'Lambda Toys Ordering Product'
    subscriptionRequired: true
    approvalRequired: false
    subscriptionsLimit: 1
    state: 'published'
  }
}

resource toyProductPolicies 'Microsoft.ApiManagement/service/products/policies@2021-08-01' = {
  name: 'policy'
  parent: toyProduct
  properties: {
    value: loadTextContent('../resources/toyProductPolicy.xml')
    format: 'xml'
  }
}

resource toyProductApiLink 'Microsoft.ApiManagement/service/products/apis@2021-08-01' = {
  name: 'LambdaStore'
  parent: toyProduct
  dependsOn: [
    lambdaStoreApi
  ]
}
