
param location string = resourceGroup().location

@description('This module deploys a freestanding sample with a servicebus and functionapp together')
module serviceBusApp 'archetype/servicebus-FunctionApp.bicep' = {
  name: 'demoapp'
  params: {
    appName: 'app'
    resNameSeed: 'demo'
    location: location
    
    AppGitRepoUrl: 'https://github.com/Gordonby/azure-sample-functionapps.git'
    AppGitRepoProdBranch: 'main'
    AppGitRepoStagingBranch: ''
    AppGitRepoPath: 'dotnet-functionapp-servicebus'
  }
}
