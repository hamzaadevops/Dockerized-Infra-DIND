#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <subdomain.domain.com> <Public_IP>"
    exit 1
fi


CLOUDFLARE_API_TOKEN="n09G2qYKmfs8PtDXQAXiJL52G8SUm_w_mBLIWTGn"
ZONE_ID="59814c95835d432a8bd4007f32616d2e"
SUBDOMAIN=$1
TARGET_IP=$2

curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
     -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
     -H "Content-Type: application/json" \
     --data '{
       "type":"A",
       "name":"'"$SUBDOMAIN"'",
       "content":"'"$TARGET_IP"'",
       "ttl":1,
       "proxied":false
     }'

