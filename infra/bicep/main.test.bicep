// This file is for doing static analysis and contains sensible defaults 
// for PSRule to minimise false-positives and provide the best results. 

// This file is not intended to be used as a runtime configuration file. 

targetScope = 'subscription'

param location string = 'swedencentral'

module main 'main.bicep' = { 
  name: 'main' 
  params: { 
    currentUserObjectId: '00000000-0000-0000-0000-000000000000'
    location: location
    appEnvironment: 'test'
    currentIpAddress: '1.1.1.1'
  }
}
