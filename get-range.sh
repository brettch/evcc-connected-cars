#!/usr/bin/env bash

set -euo pipefail

# Get the location of this script.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change to the script directory.
cd "$script_dir"

# Ensure we're working with fresh data.
./refresh-data.sh

# Return the field.
range_km=$(jq -r .data.vehicle.rangeTotalKm.km data/response.json)
echo "Range: $range_km km" >&2
echo "$range_km"
