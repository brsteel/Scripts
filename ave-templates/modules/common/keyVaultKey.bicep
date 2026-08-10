targetScope = 'resourceGroup'

type keyVaultKeyType = 'RSA' | 'RSA-HSM'

@description('Parent Key Vault name.')
param vaultName string

@description('Key name.')
param name string

@description('Key type. Defaults to RSA-HSM for stronger CMK posture.')
param keyTypeName keyVaultKeyType = 'RSA-HSM'

@description('RSA key size.')
@allowed([
  2048
  3072
  4096
])
param keySize int = 3072

@description('Whether the key is enabled.')
param enabled bool = true

@description('Allowed key operations.')
param keyOps string[] = [
  'unwrapKey'
  'wrapKey'
]

resource keyVaultResource 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: vaultName
}

resource keyVaultKeyResource 'Microsoft.KeyVault/vaults/keys@2023-07-01' = {
  parent: keyVaultResource
  name: name
  properties: {
    attributes: {
      enabled: enabled
    }
    keyOps: keyOps
    keySize: keySize
    kty: keyTypeName
  }
}

output resourceId string = keyVaultKeyResource.id
output resourceName string = keyVaultKeyResource.name
output versionlessKeyUri string = 'https://${keyVaultResource.name}${environment().suffixes.keyvaultDns}/keys/${keyVaultKeyResource.name}'
