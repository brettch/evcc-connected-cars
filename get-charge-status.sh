#!/usr/bin/env bash

set -euo pipefail

# Get the location of this script.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change to the script directory.
cd "$script_dir"

# Ensure we're working with fresh data.
./refresh-data.sh

# Return the field.
enabled=$(jq -r .data.vehicle.chargingState.enabled data/response.json)
if [ "$enabled" = "true" ]; then
  echo "C"
else
  echo "A"
fi
