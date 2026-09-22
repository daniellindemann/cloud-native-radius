#!/usr/bin/env pwsh

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false,
        HelpMessage = "Template file")]
    [string]
    $TemplateFile = "$PSScriptRoot/main.bicep",

    [Parameter(Mandatory = $false,
        HelpMessage = "Parameters file")]
    [string]
    $ParametersFile = "$PSScriptRoot/parameters.default.bicepparam",

    [Parameter(Mandatory = $false,
        HelpMessage = "Location")]
    [string]
    $Location = "polandcentral"
)

# check if az cli is installed
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    exit 1;
}

# check if az cli is logged in
$loggedIn = (az account show --query "name" -o tsv)
if (!$loggedIn) {
    exit 1;
}

# set deployment parameters
$env:AZ_DEPLOY_LOCATION = $Location

$nameWithDate = "cloud-native-radius-$(Get-Date -Format 'yyyyMMddHHmmss')"
$stringCommand = "az deployment sub create --name $nameWithDate --location $Location --template-file '$TemplateFile' --parameters '$ParametersFile'"

Write-Host "Run: $stringCommand"
Invoke-Expression $stringCommand
