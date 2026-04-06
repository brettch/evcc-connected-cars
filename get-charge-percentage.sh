#!/usr/bin/env bash

set -euo pipefail

# Get the location of this script.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change to the script directory.
cd "$script_dir"

# Ensure we're working with fresh data.
./refresh-data.sh

# Return the field.
charge_percentage=$(jq -r .data.vehicle.chargePercentage.pct data/response.json)
echo "Charge percentage: $charge_percentage%" >&2
echo "$charge_percentage"
