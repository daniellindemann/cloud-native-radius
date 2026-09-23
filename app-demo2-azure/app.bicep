extension radius

@description('The Radius Application ID. Injected automatically by the rad CLI.')
param application string

resource demo 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'demo'
  properties: {
    application: application
    extensions: [
      {
        kind: 'manualScaling'
        replicas: 3
      }
    ]
    container: {
      image: 'ghcr.io/radius-project/samples/demo:latest'
      ports: {
        web: {
          containerPort: 3000
        }
      }
    }
  }
}

resource gateway 'Applications.Core/gateways@2023-10-01-preview' = {
  name: 'gateway'
  properties: {
    application: application
    hostname: {
      fullyQualifiedHostname: 'gateway.todolist.radius.local'
    }
    routes: [
      {
        path: '/'
        destination: 'http://${demo.name}:3000'
      }
    ]
  }
}

