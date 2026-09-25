extension radius

@description('The Radius Application ID. Injected automatically by the rad CLI.')
param application string

// 
// Add environment parameter,
// so radius can inject it automatically
//
@description('The Radius Environment ID. Injected automatically by the rad CLI.')
param environment string

resource demo 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'demo2'
  properties: {
    application: application
    environment: environment  // pass environment
    container: {
      image: 'ghcr.io/radius-project/samples/demo:latest'
      ports: {
        web: {
          containerPort: 3000
        }
      }
    }
    // define connections to other resources
    connections: {
      redis: {
        source: redis.id
      }
    }
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
