using './main.bicep'

param location = readEnvironmentVariable('AZ_DEPLOY_LOCATION', 'polandcentral')
param tags = {
  'auto-aks-start-at-utc': '08:00'
  'auto-aks-stop-at-utc': '18:00'
}
