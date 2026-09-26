extension radius

@description('The Radius Application ID. Injected automatically by the rad CLI.')
param application string

@description('The Radius Environment ID. Injected automatically by the rad CLI.')
param environment string

resource demo 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'demo3-with-db-and-gw'
  properties: {
    application: application
    environment: environment
    container: {
      image: 'ghcr.io/radius-project/samples/demo:latest'
      ports: {
        web: {
          containerPort: 3000
        }
      }
    }
    extensions: [
      {
        kind: 'manualScaling'
        replicas: 3
      }
    ]
    connections: {
      redis:{
        source: redis.id
      }
    }
  }
}

resource gateway 'Applications.Core/gateways@2023-10-01-preview' = {
  name: 'demo3-demo3-with-db-and-gw-gateway'
  properties: {
    application: application
    environment: environment
    routes: [
      {
        path: '/'
        destination: 'http://${demo.name}:3000'
      }
    ]
  }
}

// Define the Redis resource
resource redis 'Applications.Datastores/redisCaches@2023-10-01-preview' = {
  name: 'redis'
  properties: {
    environment: environment
    application: application
  }
}
