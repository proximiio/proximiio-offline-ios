TOKEN="INSERT-TOKEN-HERE"
AUTH_HEADER="Authorization: Bearer $TOKEN"


mkdir -p offline_data/core
mkdir -p offline_data/v5/geo/styles

curl https://fra1.digitaloceanspaces.com/proximiio-tiles/fonts/fonts.tgz --output offline_data/fonts.tgz
tar zxvf offline_data/fonts.tgz -C offline_data
rm -rf offline_data/fonts.tgz

curl --header "$AUTH_HEADER" https://api.proximi.fi/core/package --output offline_data/core/package
curl --header "$AUTH_HEADER" https://api.proximi.fi/core/current_user --output offline_data/core/current_user
curl --header "$AUTH_HEADER" https://api.proximi.fi/core/campuses --output offline_data/core/campuses
curl --header "$AUTH_HEADER" https://api.proximi.fi/v5/geo/styles/default --output offline_data/v5/geo/styles/default
curl --header "$AUTH_HEADER" https://api.proximi.fi/v5/geo/amenities --output offline_data/v5/geo/amenities
curl --header "$AUTH_HEADER" https://api.proximi.fi/v5/geo/amenity_categories --output offline_data/v5/geo/amenity_categories
curl --header "$AUTH_HEADER" https://api.proximi.fi/v5/geo/features --output offline_data/v5/geo/features

