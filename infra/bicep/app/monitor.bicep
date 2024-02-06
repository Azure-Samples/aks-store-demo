param name string
param location string
param tags object = {}

resource monitor 'Microsoft.Monitor/accounts@2023-04-03' = {
  name: name
  location: location
  tags: tags
}

output id string = monitor.id
output name string = monitor.name
