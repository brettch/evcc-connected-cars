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

# Find the next available device name (evcc1, evcc2, ...).
existing_numbers=$(curl -sS \
  -X GET \
  -H "X-Organization-Namespace: $organisation_namespace" \
  -H "Authorization: Bearer $access_token" \
  https://auth-api.${instance_domain}/user/devices \
  | jq -r '[.[]? | .deviceName | select(test("^evcc[0-9]+$")) | ltrimstr("evcc") | tonumber] | sort | .[]')

n=1
for num in $existing_numbers; do
  if [ "$num" -eq "$n" ]; then
    n=$((n + 1))
  else
    break
  fi
done
device_name="evcc${n}"

# Register the new device and get the device token.
device_token=$(curl -sS \
  -X POST \
  -H "X-Organization-Namespace: $organisation_namespace" \
  -H "Authorization: Bearer $access_token" \
  -H 'Content-Type: application/json' \
  https://auth-api.${instance_domain}/user/registerDevice \
  -d "{\"deviceName\":\"$device_name\",\"deviceModel\":\"evcc.io\"}" \
  | jq -r '.deviceToken')

echo "Registered device: $device_name"

# Query the GraphQL API for available vehicles.
vehicles_response=$(curl -sS \
  -X POST \
  -H "X-Organization-Namespace: $organisation_namespace" \
  -H "Authorization: Bearer $access_token" \
  -H 'Content-Type: application/json' \
  "https://api.${instance_domain}/graphql" \
  -d '{"query":"{ vehicles(first:100) { items { id licensePlate vin } } }"}')

vehicle_count=$(echo "$vehicles_response" | jq '.data.vehicles.items | length')

if [ "$vehicle_count" -eq 0 ]; then
  echo "Error: No vehicles found on this account." >&2
  exit 1
fi

vehicle_id=$(echo "$vehicles_response" | jq -r '.data.vehicles.items[0].id')

echo "Vehicles found:"
echo "$vehicles_response" | jq -r '.data.vehicles.items[] | "  ID: \(.id)  Plate: \(.licensePlate)  VIN: \(.vin)"'
echo "Selected vehicle ID: $vehicle_id"

if [ "$vehicle_count" -gt 1 ]; then
  echo "To use a different vehicle, update vehicle_id in data/config.json."
fi

# Create the config.json file with the instance domain, organisation namespace, and device token.
mkdir -p data
jq -n \
  --arg instance_domain "$instance_domain" \
  --arg organisation_namespace "$organisation_namespace" \
  --arg device_token "$device_token" \
  --arg vehicle_id "$vehicle_id" \
  '{"instance_domain": $instance_domain, "organisation_namespace": $organisation_namespace, "device_token": $device_token, "vehicle_id": $vehicle_id}' \
  > data/config.json

echo "Configuration saved: $script_dir/data/config.json"
