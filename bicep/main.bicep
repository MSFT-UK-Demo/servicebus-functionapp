param location string = resourceGroup().location

@description('This module deploys a servicebus and functionapp configured together')
module serviceBusApp 'servicebus-FunctionApp.bicep' = {
  name: 'demoapp'
  params: {
    location: location
    resNameSeed: 'demo'
    appName: 'queCode'
    ServiceBusQueueName: 'theQueue'
    
    AppGitRepoUrl: 'https://github.com/Gordonby/azure-sample-functionapps.git'
    AppGitRepoProdBranch: 'main'
    AppGitRepoStagingBranch: ''
    AppGitRepoPath: 'dotnet-functionapp-servicebus'
  }
}
