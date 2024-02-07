@secure()
param domainJoinPassword string
@secure()
param domainJoinUserPrincipalName string
param keyVaultCertificatesOfficerRoleDefinitionResourceId string
param keyVaultName string
param keyVaultSecretsOfficerRoleDefinitionResourceId string
@secure()
param localAdministratorPassword string
@secure()
param localAdministratorUsername string
param location string
@secure()
param primarySiteAdministratorAccountPassword string
param primarySiteAdministratorAccountUserName string
param tags object
param userAssignedIdentityPrincipalId string
// param resourcePrefix string
// param subnetResourceId string
// param keyVaultPrivateDnsZoneResourceId string

var Secrets = [
  {
    name: 'DomainJoinPassword'
    value: domainJoinPassword
  }
  {
    name: 'DomainJoinUserPrincipalName'
    value: domainJoinUserPrincipalName
  }
  {
    name: 'LocalAdministratorPassword'
    value: localAdministratorPassword
  }
  {
    name: 'LocalAdministratorUsername'
    value: localAdministratorUsername
  }
  {
    name: 'PrimarySiteAdministratorAccountUserName'
    value: primarySiteAdministratorAccountUserName
  }
  {
    name: 'PrimarySiteAdministratorAccountPassword'
    value: primarySiteAdministratorAccountPassword
  }
]

// The key vault stores the secrets to deploy virtual machines
resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: keyVaultName
  location: location
  tags: contains(tags, 'Microsoft.KeyVault/vaults') ? tags['Microsoft.KeyVault/vaults'] : {}
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    enableRbacAuthorization: true
    enableSoftDelete: true
    networkAcls: {
      bypass: 'AzureServices'
  }
  }
}

resource secrets 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = [for Secret in Secrets: {
  parent: keyVault
  name: Secret.name
  tags: contains(tags, 'Microsoft.KeyVault/vaults') ? tags['Microsoft.KeyVault/vaults'] : {}
  properties: {
    value: Secret.value
  }
}]

// Gives the selected users rights to get key vault secrets in deployments
resource keyVaultSecretsOfficerRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(userAssignedIdentityPrincipalId, keyVaultSecretsOfficerRoleDefinitionResourceId, resourceGroup().id)
  scope: keyVault
  properties: {
    roleDefinitionId: keyVaultSecretsOfficerRoleDefinitionResourceId
    principalId: userAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource keyVaultCertificatesOfficerRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(userAssignedIdentityPrincipalId, keyVaultCertificatesOfficerRoleDefinitionResourceId, resourceGroup().id)
  scope: keyVault
  properties: {
    roleDefinitionId: keyVaultCertificatesOfficerRoleDefinitionResourceId
    principalId: userAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output name string = keyVault.name
output resourceId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri