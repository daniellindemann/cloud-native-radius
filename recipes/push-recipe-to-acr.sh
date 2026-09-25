#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage: push-recipe-to-acr.sh -a <acr-name> -f <recipe-file> -t <recipe-target>

Options:
  -a, --acr       Azure Container Registry login server (for example: myregistry.azurecr.io)
  -f, --file      Path to the recipe file
  -t, --target    Target reference (for example: br:myregistry.azurecr.io/radius-recipes/sqldatabase:0.60.2)
  -h, --help      Show this help
EOF
}

acrName=""
recipePath=""
recipeTargetName=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--acr)
            [[ $# -ge 2 ]] || { echo "Missing value for $1" >&2; usage; exit 2; }
            acrName="$2"
            shift 2
            ;;
        -f|--file)
            [[ $# -ge 2 ]] || { echo "Missing value for $1" >&2; usage; exit 2; }
            recipePath="$2"
            shift 2
            ;;
        -t|--target)
            [[ $# -ge 2 ]] || { echo "Missing value for $1" >&2; usage; exit 2; }
            recipeTargetName="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage
            exit 2
            ;;
    esac
done

# check if required arguments are provided
if [[ -z "$acrName" || -z "$recipePath" || -z "$recipeTargetName" ]]; then
    echo "Arguments --acr, --file and --target are required" >&2
    usage
    exit 2
fi

# check acr contains '.azurecr.io'
if [[ "$acrName" != *.azurecr.io ]]; then
    echo "Invalid ACR login server. It should contain '.azurecr.io'"
    echo "Provided ACR login server: $acrName"
    exit 1
fi

# check if the recipe file exists
if [[ ! -f "$recipePath" ]]; then
    echo "Recipe file not found: $recipePath" >&2
    exit 1
fi

# check azure cli installed
if ! command -v az &> /dev/null
then
    echo "Azure CLI could not be found"
    exit 1
fi

# check user is logged in
if ! az account show &> /dev/null
then
    echo "User is not logged in to Azure CLI"
    exit 1
fi

# check if rad cli is installed
if ! command -v rad &> /dev/null
then
    echo "Rad CLI could not be found"
    exit 1
fi

# check if recipe target starts with "br:"
# also ensure that the recipe target name includes the ACR name
if [[ "$recipeTargetName" != br:* ]]; then
    echo "Recipe target name must start with 'br:'"
    echo "Provided recipe target name: $recipeTargetName"
    echo "Example of a valid recipe target name: br:myregistry.azurecr.io/radius-recipes/sqldatabase:0.60.2"
    exit 1
fi

if [[ "$recipeTargetName" != *"$acrName"* ]]; then
    echo "Recipe target name must include the ACR name"
    echo "Provided recipe target name: $recipeTargetName"
    echo "Example of a valid recipe target name: br:$acrName/radius-recipes/sqldatabase:0.60.2"
    exit 1
fi

# login to acr
az acr login --name "$acrName"

# push the recipe to the ACR using rad CLI
rad bicep publish \
  --file "$recipePath" \
  --target "$recipeTargetName"
