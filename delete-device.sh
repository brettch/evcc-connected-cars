#!/usr/bin/env bash

set -euo pipefail

# Get the location of this script.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change to the script directory.
cd "$script_dir"

# Check if we have the correct number of arguments.
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <instance_domain> <organisation_namespace> <username> <device_name>" >&2
    exit 1
fi

# Get the arguments.
instance_domain="$1"
organisation_namespace="$2"
username="$3"
device_name="$4"

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

# Find devices with the given device name.
device_ids=$(curl -sS \
  -X GET \
  -H "X-Organization-Namespace: $organisation_namespace" \
  -H "Authorization: Bearer $access_token" \
  https://auth-api.${instance_domain}/user/devices \
  | jq -r --arg name "$device_name" '.[]? | select(.deviceName == $name) | .deviceToken // empty')

for device_id in $device_ids; do
  echo "Deleting device: $device_id"
  curl -sS \
    -X POST \
    -H "X-Organization-Namespace: $organisation_namespace" \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $access_token" \
    https://auth-api.${instance_domain}/user/deleteDevice \
    -d "{\"deviceExternalId\":\"$device_id\"}" \
    > /dev/null
done
