// Container Apps starter: Log Analytics + Container Apps environment + ACR + user-assigned identity +
// Key Vault (RBAC) + Container App that reads a Key Vault secret BY REFERENCE (the value is added by a human).
// Deploy: az deployment group create -g <rg> -f main.bicep -p name=myapp env=dev [useApiKeySecret=true]

@description('Short app name (lowercase letters/numbers)')
param name string

@allowed(['dev', 'stg', 'prod'])
param env string = 'dev'

param location string = resourceGroup().location

@description('Initial image; CI replaces it on every deploy')
param image string = 'mcr.microsoft.com/k8se/quickstart:latest'

param targetPort int = 80

@description('Set true only AFTER you have added the "api-key" secret value to Key Vault yourself')
param useApiKeySecret bool = false

var suffix = uniqueString(resourceGroup().id, name)
var tags = { app: name, env: env, 'managed-by': 'bicep' }

resource logs 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'log-${name}-${env}'
  location: location
  tags: tags
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 30
  }
}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${name}-${env}'
  location: location
  tags: tags
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: 'acr${name}${env}${take(suffix, 6)}'
  location: location
  tags: tags
  sku: { name: 'Basic' }
  properties: {
    adminUserEnabled: false // identities only, no registry passwords
  }
}

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-${take(name, 10)}-${env}-${take(suffix, 5)}'
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: { family: 'A', name: 'standard' }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 30
    enablePurgeProtection: true
    publicNetworkAccess: 'Enabled' // set 'Disabled' + add a Private Endpoint for corp landing zones
  }
}

// Built-in role IDs
var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'
var kvSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

resource acrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, identity.id, acrPullRoleId)
  scope: acr
  properties: {
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleId)
  }
}

resource kvSecretsUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kv.id, identity.id, kvSecretsUserRoleId)
  scope: kv
  properties: {
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', kvSecretsUserRoleId)
  }
}

resource cae 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: 'cae-${name}-${env}'
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logs.properties.customerId
        sharedKey: logs.listKeys().primarySharedKey
      }
    }
    zoneRedundant: false // true for prod (requires a VNet-integrated environment)
  }
}

resource app 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'ca-${name}-${env}'
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: { '${identity.id}': {} }
  }
  properties: {
    managedEnvironmentId: cae.id
    configuration: {
      activeRevisionsMode: 'Multiple' // enables traffic splitting between revisions
      ingress: {
        external: true
        targetPort: targetPort
        transport: 'auto'
        allowInsecure: false
        traffic: [ { latestRevision: true, weight: 100 } ]
      }
      registries: [
        { server: acr.properties.loginServer, identity: identity.id }
      ]
      secrets: useApiKeySecret ? [
        {
          name: 'api-key'
          keyVaultUrl: '${kv.properties.vaultUri}secrets/api-key'
          identity: identity.id
        }
      ] : []
    }
    template: {
      containers: [
        {
          name: 'app'
          image: image
          resources: { cpu: json('0.5'), memory: '1Gi' }
          env: concat([
            { name: 'APP_ENV', value: env }
          ], useApiKeySecret ? [
            { name: 'API_KEY', secretRef: 'api-key' }
          ] : [])
          probes: [
            { type: 'Liveness', httpGet: { path: '/', port: targetPort }, periodSeconds: 10 }
          ]
        }
      ]
      scale: {
        minReplicas: env == 'prod' ? 1 : 0
        maxReplicas: 10
        rules: [
          { name: 'http', http: { metadata: { concurrentRequests: '50' } } }
        ]
      }
    }
  }
  dependsOn: [ acrPull, kvSecretsUser ]
}

output appUrl string = 'https://${app.properties.configuration.ingress.fqdn}'
output acrName string = acr.name
output acrLoginServer string = acr.properties.loginServer
output keyVaultName string = kv.name
output containerAppName string = app.name
output identityClientId string = identity.properties.clientId
