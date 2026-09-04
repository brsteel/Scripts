targetScope = 'resourceGroup'

type storageSkuName = 'Premium_LRS' | 'Premium_ZRS' | 'Standard_GRS' | 'Standard_GZRS' | 'Standard_LRS' | 'Standard_RAGRS' | 'Standard_RAGZRS' | 'Standard_ZRS'

type microsoftManagedEncryption = {
  keySource: 'Microsoft.Storage'
}

@sealed()
type customerManagedEncryption = {
  keySource: 'Microsoft.Keyvault'
  keyName: string
  keyVaultUri: string
  userAssignedIdentityResourceId: string
  keyVersion: string?
}

@sealed()
@discriminator('keySource')
type storageEncryption = microsoftManagedEncryption | customerManagedEncryption

@description('Storage account name.')
param name string

@description('Azure region for the storage account.')
param location string

@description('Storage account SKU.')
param skuName storageSkuName = 'Standard_LRS'

@description('Tags applied to the storage account.')
param tags object = {}

@description('Whether public network access is enabled.')
param enablePublicNetworkAccess bool = false

@description('Whether shared key access is allowed.')
param allowSharedKeyAccess bool = false

@description('Whether blob containers can be public.')
param allowBlobPublicAccess bool = false

@description('Optional firewall bypass mode.')
@allowed([
  'AzureServices'
  'Logging'
  'Metrics'
  'None'
])
param networkAclsBypass string = 'None'

@description('Allowed public IPv4 rules. Defaults to none.')
param ipRules string[] = []

@description('Allowed subnet resource IDs. Defaults to none.')
param virtualNetworkSubnetResourceIds string[] = []

@description('Encryption configuration.')
param encryption storageEncryption = {
  keySource: 'Microsoft.Storage'
}

var usesCustomerManagedKey = encryption.keySource == 'Microsoft.Keyvault'
var userAssignedIdentityMap = usesCustomerManagedKey ? toObject([encryption.userAssignedIdentityResourceId], identityResourceId => identityResourceId, _ => {}) : {}

resource storageAccountResource 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: name
  location: location
  tags: tags
  identity: usesCustomerManagedKey ? {
    type: 'UserAssigned'
    userAssignedIdentities: userAssignedIdentityMap
  } : null
  kind: 'StorageV2'
  sku: {
    name: skuName
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: allowBlobPublicAccess
    allowCrossTenantReplication: false
    allowSharedKeyAccess: allowSharedKeyAccess
    defaultToOAuthAuthentication: !allowSharedKeyAccess
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: networkAclsBypass
      defaultAction: 'Deny'
      ipRules: [for ipRule in ipRules: {
        action: 'Allow'
        value: ipRule
      }]
      virtualNetworkRules: [for subnetResourceId in virtualNetworkSubnetResourceIds: {
        action: 'Allow'
        id: subnetResourceId
      }]
    }
    publicNetworkAccess: enablePublicNetworkAccess ? 'Enabled' : 'Disabled'
    supportsHttpsTrafficOnly: true
    encryption: union({
      keySource: encryption.keySource
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
      }
    }, usesCustomerManagedKey ? {
      identity: {
        userAssignedIdentity: encryption.userAssignedIdentityResourceId
      }
      keyvaultproperties: union({
        keyname: encryption.keyName
        keyvaulturi: encryption.keyVaultUri
      }, empty(encryption.keyVersion ?? '') ? {} : {
        keyversion: encryption.keyVersion
      })
    } : {})
  }
}

output resourceId string = storageAccountResource.id
output resourceName string = storageAccountResource.name
output primaryBlobEndpoint string = storageAccountResource.properties.primaryEndpoints.blob
