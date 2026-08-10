targetScope = 'resourceGroup'

type keyVaultSkuName = 'premium' | 'standard'
type networkBypass = 'AzureServices'

@description('Key Vault name.')
param name string

@description('Azure region for the Key Vault.')
param location string

@description('Tenant ID for the Key Vault.')
param tenantId string = subscription().tenantId

@description('Key Vault SKU.')
param skuName keyVaultSkuName = 'standard'

@description('Tags applied to the Key Vault.')
param tags object = {}

@description('Whether template deployments can retrieve secrets from the vault.')
param enabledForTemplateDeployment bool = false

@description('Whether Azure Disk Encryption can retrieve secrets from the vault.')
param enabledForDiskEncryption bool = false

@description('Whether Azure deployment resources can retrieve secrets from the vault.')
param enabledForDeployment bool = false

@description('Whether public network access is allowed. Disabled by default for private-only operation.')
param enablePublicNetworkAccess bool = false

@description('Soft delete retention in days.')
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int = 90

@description('Trusted service bypass mode for the vault firewall.')
param networkAclsBypass networkBypass = 'AzureServices'

@description('Allowed public IPv4 rules. Defaults to none.')
param ipRules string[] = []

@description('Allowed subnet resource IDs. Defaults to none.')
param virtualNetworkSubnetResourceIds string[] = []

resource keyVaultResource 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    enablePurgeProtection: true
    enableRbacAuthorization: true
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    networkAcls: {
      bypass: networkAclsBypass
      defaultAction: 'Deny'
      ipRules: [for ipRule in ipRules: {
        value: ipRule
      }]
      virtualNetworkRules: [for subnetResourceId in virtualNetworkSubnetResourceIds: {
        id: subnetResourceId
      }]
    }
    publicNetworkAccess: enablePublicNetworkAccess ? 'Enabled' : 'Disabled'
    sku: {
      family: 'A'
      name: skuName
    }
    softDeleteRetentionInDays: softDeleteRetentionInDays
    tenantId: tenantId
  }
}

output resourceId string = keyVaultResource.id
output resourceName string = keyVaultResource.name
output vaultUri string = keyVaultResource.properties.vaultUri
