#!/usr/bin/env bash

set -euo pipefail

# Get the location of this script.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change to the script directory.
cd "$script_dir"

# Check if we have the correct number of arguments.
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <instance_domain> <organisation_namespace> <username>" >&2
    exit 1
fi

# Get the arguments.
instance_domain="$1"
organisation_namespace="$2"
username="$3"

# Get the password from the user.
read -s -p "Password: " password
echo

# Authenticate to the API and get the access token from the token json field.
access_token=$(curl -sS \
  -X POST \
  -H "X-Organization-Namespace: vwaustralia:app" \
  -H 'Content-Type: application/json' \
  https://auth-api.${instance_domain}/auth/login/email/password \
  -d "{\"email\":\"$username\",\"password\":\"$password\"}" \
  | jq -r '.token')

# List all registered evcc devices.
curl -sS \
  -X GET \
  -H "X-Organization-Namespace: $organisation_namespace" \
  -H "Authorization: Bearer $access_token" \
  https://auth-api.${instance_domain}/user/devices \
  | jq -r '.[]? | select(.deviceName | test("^evcc")) | .deviceName'
