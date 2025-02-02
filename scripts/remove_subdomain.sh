#!/bin/bash

# Check if subdomain argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <subdomain.domain.com>"
    exit 1
fi

CLOUDFLARE_API_TOKEN="n09G2qYKmfs8PtDXQAXiJL52G8SUm_w_mBLIWTGn"
ZONE_ID="59814c95835d432a8bd4007f32616d2e"
SUBDOMAIN=$1

# Validate subdomain format
if ! [[ "$SUBDOMAIN" =~ ^[a-zA-Z0-9.-]+$ ]]; then
    echo "Error: Invalid subdomain format. Use a valid subdomain (e.g., sub.domain.com)."
    exit 1
fi

# Get the DNS record ID of the subdomain
RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$SUBDOMAIN" \
     -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
     -H "Content-Type: application/json")

RECORD_ID=$(echo "$RESPONSE" | jq -r '.result[0].id')

if [ "$RECORD_ID" == "null" ]; then
    echo "Error: Subdomain $SUBDOMAIN not found in Cloudflare."
    exit 1
fi

# Delete the DNS record
DELETE_RESPONSE=$(curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
     -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
     -H "Content-Type: application/json")

# Check if deletion was successful
SUCCESS=$(echo "$DELETE_RESPONSE" | jq -r '.success')

if [ "$SUCCESS" == "true" ]; then
    echo "Subdomain $SUBDOMAIN successfully removed from Cloudflare."
else
    echo "Failed to remove subdomain. Response from Cloudflare: $DELETE_RESPONSE"
fi

