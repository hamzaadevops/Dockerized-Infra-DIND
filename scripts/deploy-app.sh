#!/bin/bash
echo "Started"
# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --appName=*) appName="${1#*=}" ;;
        --subDomain=*) subDomain="${1#*=}" ;;
        --appPort=*) appPort="${1#*=}" ;;
        --imageName=*) imageName="${1#*=}" ;;
        --addChatApp) addChatApp="true" ;;
        *) echo "Unknown parameter passed: $1" ;;
    esac
    shift
done

# Default value for addChatApp if not set
addChatApp=${addChatApp:-"false"}

# Variables
APP_NAME=$appName           # Application name (e.g., app3000)
SUBDOMAIN=$subDomain        # Subdomain for the app (e.g., app3.ewanc.com)
PORT=$appPort               # Internal app port (e.g., 3000)
IMAGE=$imageName            # Docker image for the app (e.g., nginx:latest)
CHAT_APP=$addChatApp        # Chat app flag (true/false)
CHAT_SUBDOMAIN="chat.$SUBDOMAIN"  # Chat service subdomain
ROCKET_CHAT_PORT=3000       # Rocket.Chat port (example value)

# Log all variables for debugging
echo "Application Name: $APP_NAME"
echo "Subdomain: $SUBDOMAIN"
echo "Internal Port: $PORT"
echo "Docker Image: $IMAGE"
echo "Add Chat App: $CHAT_APP"
echo "Chat Subdomain: $CHAT_SUBDOMAIN"
echo "Rocket.Chat Port: $ROCKET_CHAT_PORT"

CLOUDFLARE_API_TOKEN="n09G2qYKmfs8PtDXQAXiJL52G8SUm_w_mBLIWTGn"
ZONE_ID="59814c95835d432a8bd4007f32616d2e"

SERVER_IP="20.244.35.253"  # Replace with your server's public IP
DDCLIENT_CONF="/etc/ddclient.conf"  # Path to ddclient.conf

# Function to update Cloudflare DNS
update_cloudflare_dns() {
  local dns_subdomain=$1

  # List of subdomains to update
  local subdomains_to_update=("$dns_subdomain" "chat.$dns_subdomain")

  for subdomain in "${subdomains_to_update[@]}"; do
    echo "Updating Cloudflare DNS for $subdomain..."
    RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
         -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
         -H "Content-Type: application/json" \
         --data '{
           "type": "A",
           "name": "'"$subdomain"'",
           "content": "'"$SERVER_IP"'",
           "ttl": 120,
           "proxied": false
         }')
  done
}


# Function to deploy the app with Traefik labels
deploy_app() {
  local app_name=$1
  local subdomain=$2
  local port=$3
  local image=$4

  echo "Deploying $app_name on subdomain $subdomain..."
  docker run -d --name "$app_name" --network traefik \
    -e PORT="$port" \
    -l "traefik.enable=true" \
    -l "traefik.http.routers.${app_name}.rule=Host(\`$subdomain\`)" \
    -l "traefik.http.routers.${app_name}.entrypoints=websecure" \
    -l "traefik.http.routers.${app_name}.tls.certresolver=myresolver" \
    -l "traefik.http.services.${app_name}.loadbalancer.server.port=$port" \
    "$image"
}

# Function to deploy Rocket.Chat for the app
deploy_rocketchat() {
  echo "Deploying MongoDB for Rocket.Chat..."

  # Deploy MongoDB container
  docker run -d --name "mongodb-$APP_NAME" --network traefik \
    -v "mongodb_data_$APP_NAME:/bitnami/mongodb" \
    -e MONGODB_REPLICA_SET_MODE=primary \
    -e MONGODB_REPLICA_SET_NAME=rs0 \
    -e MONGODB_ADVERTISED_HOSTNAME="mongodb-$APP_NAME" \
    -e ALLOW_EMPTY_PASSWORD=yes \
    bitnami/mongodb:6.0

  echo "Waiting for MongoDB to be ready..."
  until [ "$(docker inspect --format='{{json .State.Status}}' "mongodb-$APP_NAME")" == "\"running\"" ]; do
    echo "MongoDB is not ready yet. Waiting..."
    sleep 5
  done

  echo "MongoDB is ready. Deploying Rocket.Chat on subdomain $CHAT_SUBDOMAIN..."

  # Deploy Rocket.Chat container
  docker run -d --name "rocketchat-$APP_NAME" --network traefik \
    -e ROOT_URL="https://$CHAT_SUBDOMAIN" \
    -e MONGO_URL="mongodb://mongodb-$APP_NAME:27017/rocketchat-$APP_NAME" \
    -e MONGO_OPLOG_URL="mongodb://mongodb-$APP_NAME:27017/local" \
    -l "traefik.enable=true" \
    -l "traefik.http.routers.rocketchat-$APP_NAME.rule=Host(\`$CHAT_SUBDOMAIN\`)" \
    -l "traefik.http.routers.rocketchat-$APP_NAME.entrypoints=websecure" \
    -l "traefik.http.routers.rocketchat-$APP_NAME.tls.certresolver=myresolver" \
    -l "traefik.http.services.rocketchat-$APP_NAME.loadbalancer.server.port=$ROCKET_CHAT_PORT" \
    rocketchat/rocket.chat:latest
}

# Function to update ddclient.conf
update_ddclient_conf() {
  local dns_subdomain=$1
  local chat_subdomain="chat.$dns_subdomain"
  echo "Updating $DDCLIENT_CONF with $dns_subdomain and $chat_subdomain..."

  # Check and add the main subdomain if not already present
  if grep -q "$dns_subdomain" "$DDCLIENT_CONF"; then
    echo "$dns_subdomain is already in $DDCLIENT_CONF."
  else
    # Append the main subdomain to the list
    sed -i "s/zone=ewanc.com/zone=ewanc.com\n$dns_subdomain,/" "$DDCLIENT_CONF"
    echo "Added $dns_subdomain to $DDCLIENT_CONF."
  fi

  # Check and add the chat subdomain if not already present
  if grep -q "$chat_subdomain" "$DDCLIENT_CONF"; then
    echo "$chat_subdomain is already in $DDCLIENT_CONF."
  else
    # Append the chat subdomain to the list
    sed -i "s/zone=ewanc.com/zone=ewanc.com\n$chat_subdomain,/" "$DDCLIENT_CONF"
    echo "Added $chat_subdomain to $DDCLIENT_CONF."
  fi
}

# Main Script

# Update DNS and ddclient for main app and chat service
update_cloudflare_dns "$SUBDOMAIN"

#update_ddclient_conf "$SUBDOMAIN"

# Deploy main app and chat service
deploy_app "$APP_NAME" "$SUBDOMAIN" "$PORT" "$IMAGE"
deploy_rocketchat

echo "Deployment complete."
echo "App URL: https://$SUBDOMAIN"
echo "Chat URL: https://$CHAT_SUBDOMAIN"

