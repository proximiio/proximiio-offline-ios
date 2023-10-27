#!/bin/sh

TOKEN="INSERT_TOKEN_HERE"
AUTH_HEADER="Authorization: Bearer $TOKEN"

mkdir -p offline_data/core
mkdir -p offline_data/v5/geo/styles

echo "Downloading offline data"

wget --header="$AUTH_HEADER" https://api.proximi.fi/core/package -O offline_data/core/package
wget --header="$AUTH_HEADER" https://api.proximi.fi/core/current_user -O offline_data/core/current_user
wget --header="$AUTH_HEADER" https://api.proximi.fi/core/campuses -O offline_data/core/campuses
wget --header="$AUTH_HEADER" https://api.proximi.fi/v5/geo/styles/default -O offline_data/v5/geo/styles/default
wget --header="$AUTH_HEADER" https://api.proximi.fi/v5/geo/amenities -O offline_data/v5/geo/amenities
wget --header="$AUTH_HEADER" https://api.proximi.fi/v5/geo/features -O offline_data/v5/geo/features





