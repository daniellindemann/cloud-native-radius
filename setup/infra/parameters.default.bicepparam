using './main.bicep'

param location = readEnvironmentVariable('AZ_DEPLOY_LOCATION', 'polandcentral')
param tags = {
  Maintainer: 'Daniel Lindemann'
  Owner: 'Daniel Lindemann'
  Project: 'https://github.com/daniel-lindemann/cloud-native-radius'
  Visit: 'https://dlindemann.de'
  'auto-aks-days': 'Mon,Tue,Wed,Thu,Fri,Sat,Sun'
  'auto-aks-start-at-utc': '07:00'
  'auto-aks-stop-at-utc': '19:00'
}
