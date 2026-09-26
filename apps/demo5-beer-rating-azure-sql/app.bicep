extension radius

/*

This app uses the Beer Rating demo application: https://github.com/daniellindemann/beer-rating-standalone
Prebuild images can be found on Docker Hub:
- Backend: https://hub.docker.com/r/daniellindemann/beer-rating-backend
- Frontend: https://hub.docker.com/r/daniellindemann/beer-rating-frontend
- Console Beer Quotes: https://hub.docker.com/r/daniellindemann/beer-rating-console-beerquotes

----------------------------

Ensure to register the Azure SQL recipe first:

rad recipe register default \
  --environment azure \
  --group azure \
  --template-kind bicep \
  --template-path "acrcnrhiqgue-hkevf9ergae4bfbv.azurecr.io/radius-recipes/sqldatabase:0.60.2" \
  --resource-type "Applications.Datastores/sqlDatabases" \
  --parameters skuName=Basic \
  --parameters skuTier=Basic \
  --parameters backupStorageRedundancy=Local

Unregister with, if required:

rad recipe unregister default \
  --resource-type "Applications.Datastores/sqlDatabases"

*/

@description('The Radius Application ID. Injected automatically by the rad CLI.')
param application string

@description('The Radius Environment ID. Injected automatically by the rad CLI.')
param environment string

@description('The name of the environment extracted from the environment ID.')
var environmentName = last(split(environment, '/'))

@description('The name of the application extracted from the application ID.')
var applicationName = last(split(application, '/'))

@description('app version to run')
var version = 10

resource sqlDb 'Applications.Datastores/sqlDatabases@2023-10-01-preview' = {
  name: 'demo5-sqlDb'
  properties: {
    application: application
    environment: environment
  }
}

resource backend 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'demo5-backend'
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
  name: 'demo5-frontend'
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
  name: 'demo5-consoleQuotes'
  properties: {
    application: application
    environment: environment
    container: {
      image: 'daniellindemann/beer-rating-console-beerquotes:${version}'
    }
  }
}

resource gateway 'Applications.Core/gateways@2023-10-01-preview' = {
  name: 'demo5-gateway'
  properties: {
    application: application
    environment: environment
    hostname: {
      fullyQualifiedHostname: 'demo5-gateway.beerrating.radius.local'
    }
    routes: [
      {
        path: '/'
        destination: 'http://${frontend.name}:5179'
      }
    ]
  }
}

