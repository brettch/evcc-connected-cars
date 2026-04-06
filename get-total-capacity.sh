#!/usr/bin/env bash

set -euo pipefail

# Get the location of this script.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change to the script directory.
cd "$script_dir"

# Ensure we're working with fresh data.
./refresh-data.sh

# Return the field.
total_capacity=$(jq -r .data.vehicle.highVoltageBatteryTotalCapacityKwh.kwh data/response.json)
echo "Total capacity: $total_capacity kWh" >&2
echo "$total_capacity"
