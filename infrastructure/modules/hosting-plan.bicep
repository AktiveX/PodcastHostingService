@description('The name of the hosting plan')
param name string

@description('The location for the hosting plan')
param location string

@description('The environment name')
param environment string

resource hostingPlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: name
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
    size: 'Y1'
    family: 'Y'
    capacity: 0
  }
  properties: {
    computeMode: 'Dynamic'
    reserved: false
  }
  tags: {
    Environment: environment
    Project: 'PodcastHostingService'
  }
}

// Outputs
output name string = hostingPlan.name
output id string = hostingPlan.id
