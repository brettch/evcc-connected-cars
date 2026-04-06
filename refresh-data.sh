#!/usr/bin/env bash

set -euo pipefail

# Get the location of this script.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change to the script directory.
cd "$script_dir"

# Work in the data directory.
cd data

# Load config.
instance_domain=$(jq -r .instance_domain "config.json")
organisation_namespace=$(jq -r .organisation_namespace "config.json")
device_token=$(jq -r .device_token "config.json")

# Check the expiry time of the token. If we're within 5 minutes of expiry, get a new token.
if [ -f token_expiry.txt ]; then
  expiry_time=$(cat token_expiry.txt)
  current_time=$(date +%s)
  time_diff=$((expiry_time - current_time))
  if [ $time_diff -le 300 ]; then
    echo "Token is expiring in $time_diff seconds. Getting a new token." >&2
    rm -f token_expiry.txt
  else
    echo "Token is still valid for $time_diff seconds." >&2
  fi
else
  echo "No token expiry information found. Getting a new token." >&2
fi

# If we don't have a token, get one.
if [ ! -f token_expiry.txt ]; then
  curl \
    -s -S \
    -X POST \
    -H "X-Organization-Namespace: $organisation_namespace" \
    -H 'Content-Type: application/json' \
    "https://auth-api.${instance_domain}/auth/login/deviceToken" \
    -d "{\"deviceToken\":\"$device_token\"}" \
    --output auth.json

  expires_in=$(jq -r .expires auth.json)

  # Calculate the expiration time and write it to a file for future reference
  current_time=$(date +%s)
  expiry_time=$((current_time + expires_in))
  echo "$expiry_time" > token_expiry.txt
fi

# Load the API token
token=$(jq -r .token auth.json)

# Check if data has expired.
if [ -f data_timestamp.txt ]; then
  data_timestamp=$(cat data_timestamp.txt)
  current_time=$(date +%s)
  time_diff=$((current_time - data_timestamp))
  if [ $time_diff -le 60 ]; then
    echo "Data is still fresh (last updated $time_diff seconds ago)." >&2
  else
    echo "Data is stale (last updated $time_diff seconds ago). Refreshing data." >&2
    rm -f data_timestamp.txt
  fi
else
  echo "No data timestamp found. Fetching new data." >&2
fi

if [ ! -f data_timestamp.txt ]; then
  echo "Fetching new data from API." >&2

  curl "https://api.${instance_domain}/graphql" \
    -s -S \
    -X POST \
    -H "Authorization: Bearer $token" \
    -H "x-organization-namespace: $organisation_namespace" \
    -H 'Content-Type: application/json' \
    --data-raw '{"variables":{"id":"17907"},"query":"query($id: ID!) { vehicle(id: $id) { id chargePercentage { pct } highVoltageBatteryTotalCapacityKwh { kwh } highVoltageBatteryUsableCapacityKwh { kwh } totalEstimatedBatteryCapacity { dashboardRangeKm } odometer { odometer } }}"}' \
    --output response.json

    # Update the data timestamp
    current_time=$(date +%s)
    echo "$current_time" > data_timestamp.txt

else
  echo "Using cached data." >&2
fi
