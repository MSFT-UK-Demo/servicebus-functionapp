/*
  A single function app that uses CosmosDb, fronted by APIM.
  Key Vault for secrets management
  LoadTesting and Web Tests are configured

  As an Archetype there is no specific application information, just the right configuration for a standard App deployment.
*/

@description('The name seed for your functionapp. Check outputs for the actual name and url')
param appName string

@description('The name seed for all your other resources.')
param resNameSeed string

@description('Soft Delete protects your Vault contents and should be used for serious environments')
param enableKeyVaultSoftDelete bool = true

param location string = resourceGroup().location

@description('Needs to be unique as ends up as a public endpoint')
var webAppName = 'app-${appName}-${uniqueString(resourceGroup().id, appName)}'

// --------------------App Identity-------------------
//Creating the function App identity here as otherwise it'll cause circular problems in the modules
@description('The Azure Managed Identity Name assigned to the FunctionApp')
param fnAppIdentityName string = 'id-app-${appName}-${uniqueString(resourceGroup().id, appName)}'

resource fnAppUai 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: fnAppIdentityName
  location: location
}

// --------------------Function App-------------------
@description('The full publicly accessible external Git(Hub) repo url')
param AppGitRepoUrl string

param AppGitRepoProdBranch string = 'main'
param AppGitRepoStagingBranch string = ''

var ServiceBusAppSettings = [
  {
    name: 'ServiceBusConnection__fullyQualifiedNamespace'
    value: servicebus.outputs.serviceBusFqdn
  }
]

module functionApp '../foundation/functionapp.bicep' = {
  name: 'functionApp-${appName}-${resNameSeed}'
  params: {
    location: location
    appName: appName
    webAppName: webAppName
    AppInsightsName: appInsights.outputs.name
    fnAppIdentityName: fnAppUai.name
    repoUrl: AppGitRepoUrl
    repoBranchProduction: AppGitRepoProdBranch
    repoBranchStaging: AppGitRepoStagingBranch
    deploymentSlotName: ''
    additionalAppSettings: ServiceBusAppSettings
  }
}

@description('The raw function app url')
output ApplicationUrl string = functionApp.outputs.appUrl

// -------------------Service Bus---------------------
var ServiceBusNameSpaceName=resNameSeed
module servicebus '../foundation/servicebus-queue.bicep' = {
  name: 'servicebus-${resNameSeed}'
  params: {
    serviceBusQueueName: '${resNameSeed}-q'
    serviceBusNamespaceName: ServiceBusNameSpaceName
    location: location
  }
}

// --------------------App Insights-------------------
module appInsights '../foundation/appinsights.bicep' = {
  name: 'appinsights-${resNameSeed}'
  params: {
    appName: webAppName
    logAnalyticsId: logAnalyticsResourceId
    location: location
  }
}
output AppInsightsName string = appInsights.outputs.name

// --------------------Log Analytics-------------------
@description('If you have an existing log analytics workspace in this region that you prefer, set the full resourceId here')
param centralLogAnalyticsId string = ''
module log '../foundation/loganalytics.bicep' = if(empty(centralLogAnalyticsId)) {
  name: 'log-${resNameSeed}'
  params: {
    resNameSeed: resNameSeed
    retentionInDays: 30
    location: location
  }
}
var logAnalyticsResourceId =  !empty(centralLogAnalyticsId) ? centralLogAnalyticsId : log.outputs.id

module akv '../foundation/kv.bicep' = {
  name: 'keyvault-${resNameSeed}'
  params: {
    nameSeed: resNameSeed
    enableSoftDelete: enableKeyVaultSoftDelete
    tenantId: subscription().tenantId
    location: location
  }
}

module akvAssignments '../foundation/kv-roleassignments.bicep' = {
  name: 'roles-keyvault-${resNameSeed}'
  params: {
    kvName: akv.outputs.name
    UaiSecretReaderNames: [
      fnAppUai.name
    ]
  }
}

var serviceBusDataReceiver = resourceId('Microsoft.Authorization/roleDefinitions', '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0')
resource functionAppToSb 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(serviceBusDataReceiver, ServiceBusNameSpaceName, fnAppUai.id)
  properties: {
    principalId: fnAppUai.properties.principalId
    roleDefinitionId: serviceBusDataReceiver
  }
}
