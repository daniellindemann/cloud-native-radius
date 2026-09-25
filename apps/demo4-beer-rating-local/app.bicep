extension radius

@description('The Radius Application ID. Injected automatically by the rad CLI.')
param application string

@description('The Radius Environment ID. Injected automatically by the rad CLI.')
param environment string

// ---


// Get the plain environment name from the id
// Get last element from /planes/radius/local/resourceGroups/default/providers/Applications.Core/environments/default
@description('The name of the environment extracted from the environment ID.')
var environmentName = last(split(environment, '/'))

// Get the plain application name from the id
// Get last element from /planes/radius/local/resourcegroups/default/providers/Applications.Core/applications/demo4-beer-rating-local
@description('The name of the application extracted from the application ID.')
var applicationName = last(split(application, '/'))

@description('app version to run')
var version = 10

resource sqlDb 'Applications.Datastores/sqlDatabases@2023-10-01-preview' = {
  name: 'demo4-sqlDb'
  properties: {
    application: application
    environment: environment
  }
}

resource backend 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'demo4-backend'
  properties: {
    application: application
    environment: environment
    container: {
      image: 'daniellindemann/beer-rating-backend:${version}'
      env: {
        Database__UseInMemoryDatabase: {
          value: 'false'
        }
        ConnectionStrings__Beer: {
          value: sqlDb.listSecrets().connectionString
        }
      }
      ports: {
        backend: {
          containerPort: 5178
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
      sqlDb: {
        source: sqlDb.id
        disableDefaultEnvVars: true
      }
    }
  }
}

resource frontend 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'demo4-frontend'
  properties: {
    application: application
    environment: environment
    container: {
      image: 'daniellindemann/beer-rating-frontend:${version}'
      env: {
        Backend__HostUrl: {
          value: 'http://${backend.name}.${environmentName}-${applicationName}.svc.cluster.local:5178'  // TODO: is is possible to get the whole fqdn from radius?
        }
        Backend__HostUrl__Alternative: {
          value: 'http://${backend.name}:5178'
        }
      }
      ports: {
        frontend: {
          containerPort: 5179
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
      backend: {
        source: backend.id
        disableDefaultEnvVars: true
      }
    }
  }
}

resource consoleQuotes 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'demo4-consoleQuotes'
  properties: {
    application: application
    environment: environment
    container: {
      image: 'daniellindemann/beer-rating-console-beerquotes:${version}'
    }
  }
}

resource gateway 'Applications.Core/gateways@2023-10-01-preview' = {
  name: 'demo4-gateway'
  properties: {
    application: application
    environment: environment
    hostname: {
      fullyQualifiedHostname: 'demo4-gateway.beerrating.radius.local'
    }
    routes: [
      {
        path: '/'
        destination: 'http://${frontend.name}:5179'
      }
    ]
  }
}
