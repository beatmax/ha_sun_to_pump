#!/bin/bash

# Read SunToPump's power tables from Home Assistant's API.
# Requires an API access token.
#
# Usage: read_power_table.sh [--defaults | --record] <url> <token>"
#
# Reads the actual power table by default, which contains a combination of
# recorded and default values. Use --defaults or --record to read only default
# or recorded values.

set -e

suffix=""
if [[ "$1" == "--defaults" ]]; then
  suffix="_defaults"
  shift
elif [[ "$1" == "--record" ]]; then
  suffix="_record"
  shift
fi

if [[ $# != 2 ]]; then
  echo >&2 "Usage: $(basename $0) [--defaults | --record] <url> <token>"
  exit 1
fi

url="$1"
token="$2"

if ! which curl >& /dev/null; then
  echo >&2 "Please install 'curl'."
  exit 1
fi

if ! data=$(curl --silent --fail --show-error \
  -H "Authorization: Bearer $token" \
  -H "Content-Type: application/json" \
  "$url/api/states/sensor.suntopump_power_table$suffix");
then
  exit 1
fi

python -c 'import json, sys; json.dump(json.load(sys.stdin)["attributes"]["table"], sys.stdout)' \
  <<< "$data" | sed 's/],/],\n/g;s/$/\n/'
