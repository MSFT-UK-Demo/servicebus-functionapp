
param location string = resourceGroup().location

module doIt 'archetype/functionapp-servicebus.bicep' = {
  name: 'demoapp'
  params: {
    appName: 'myapp'
    resNameSeed: 'myproj'
    location: location
    
    //We're not wanting source control binding... yet.
    AppGitRepoUrl: ''
    AppGitRepoProdBranch: ''
    AppGitRepoStagingBranch: ''
  }
}
