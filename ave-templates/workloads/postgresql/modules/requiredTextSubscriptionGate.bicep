targetScope = 'subscription'

@description('Non-empty compatibility token. Deployment fails validation when the supplied value is empty.')
@minLength(1)
param requiredText string

output value string = requiredText
