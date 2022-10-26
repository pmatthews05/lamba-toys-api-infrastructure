param zoneName string
param recordName string
param cName string
param keyVaultName string
param managedIdentityId string


resource dnsZone 'Microsoft.Network/dnsZones@2018-05-01' existing = {
  name: zoneName
}

resource dnsRecord 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = {
  parent: dnsZone
  name: recordName
  properties:{
    TTL:3600
    CNAMERecord: {
      cname:cName
    }
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyVaultName
}

resource keyvaultCertificateOfficer 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing ={
  scope:subscription()
  name: 'a4417e6f-fecd-4de8-b567-7b0420556985'
} 

resource keyvaultSecretOfficer 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing ={
  scope:subscription()
  name: '4633458b-17de-408a-b874-0445c86b69e6'
}

var roleIds = [
  keyvaultCertificateOfficer.id
  keyvaultSecretOfficer.id
]

resource kvRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [ for roleId in roleIds:{
  name: guid(keyVaultName, managedIdentityId, roleId)
  scope: keyVault
  properties:{
    roleDefinitionId: roleId
    principalId: managedIdentityId
    principalType: 'ServicePrincipal'
  }
}]
