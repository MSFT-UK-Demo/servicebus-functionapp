
param location string = resourceGroup().location

module doIt 'archetype/functionapp-servicebus.bicep' = {
  name: 'demoapp'
  params: {
    appName: 'myapp6'
    resNameSeed: 'myproj'
    location: location
    
    AppGitRepoUrl: 'https://github.com/Gordonby/azure-sample-functionapps.git'
    AppGitRepoProdBranch: 'main'
    AppGitRepoStagingBranch: ''
    AppGitRepoPath: 'dotnet-functionapp-servicebus'
  }
}
