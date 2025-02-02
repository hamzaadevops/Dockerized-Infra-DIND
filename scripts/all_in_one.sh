#!/bin/bash

# Check if the required arguments are provided
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <DOMAIN> <PUBLIC_IP> <CLOUDFLARE_API_TOKEN>"
  exit 1
fi

# Assign arguments to variables
DOMAIN=$1
CLOUDFLARE_API_TOKEN=$3
PUBLIC_IP=$2
TARGET_DIR="/app"

setup_environment() {
  echo "Setting up the environment..."

  # Create the Docker network
  echo "Ensuring Docker network 'traefik' creating"
  echo "value is: ${CLOUDFLARE_API_TOKEN}  Done"

  if ! docker network ls | grep -q traefik; then
    docker network create traefik
    echo "Docker network 'traefik' created."
  else
    echo "Docker network 'traefik' already exists."
  fi

  echo "Environment setup complete."
}

add_subdomains() {
  echo "Adding subdomains for $DOMAIN with IP $PUBLIC_IP..."

  # Add subdomains
  /app/scripts/add_subdomain.sh "traefik.$DOMAIN" "$PUBLIC_IP"
  sleep 5
  /app/scripts/add_subdomain.sh "portainer.$DOMAIN" "$PUBLIC_IP"
  sleep 5
  /app/scripts/add_subdomain.sh "dashboard.$DOMAIN" "$PUBLIC_IP"

  echo "Subdomains added: traefik.$DOMAIN, portainer.$DOMAIN, dashboard.$DOMAIN"
}

# Function to run npm install and start the app using pm2
setup_and_run_app() {
  echo "Setting up the app in $TARGET_DIR..."

  # Navigate to the target directory
  cd "$TARGET_DIR" || { echo "Failed to navigate to $TARGET_DIR. Check if the directory exists."; exit 1; }

  echo "Replacing occurrences of 'swiftroc.com' with '$DOMAIN' in all files..."
  grep -rl 'swiftroc.com' /app/ | xargs sed -i "s/swiftroc.com/$DOMAIN/g"
  
  echo "Installing dependencies..."
  #npm i
  #npm i -g pm2 || npm i
  echo "Starting the app with pm2..."
  #pm2 start index.js --name "$DOMAIN"

  echo "Starting docker-compose"
  # DOcker Setup
  docker-compose -f /app/docker-compose.local.yml up -d --build
  echo "docker-compose is now up"

  # Navigate back to the original directory
  cd /app/scripts || exit
}

# Function to get Zone ID
get_zone_id() {
  echo "Fetching Zone ID for domain: $DOMAIN"

  # Make API call to fetch Zone ID
  RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    -H "Content-Type: application/json")
  echo "Authorization: Bearer $CLOUDFLARE_API_TOKEN"
  # Check if the API call was successful
  if echo "$RESPONSE" | grep -q '"success":true'; then
    ZONE_ID=$(echo "$RESPONSE" | jq -r '.result[0].id')
    if [ "$ZONE_ID" != "null" ]; then
      echo "Zone ID for $DOMAIN: $ZONE_ID"
    else
      echo "Error: Zone ID not found for $DOMAIN."
      exit 1
    fi
  else
    echo "Error fetching Zone ID. Response: $RESPONSE"
    exit 1
  fi
}

# Function to update other scripts with the new values
update_scripts() {
  echo "Updating other scripts in the directory with new values..."
  cd /app/scripts
   if [[ -z "$DOMAIN" || -z "$CLOUDFLARE_API_TOKEN" || -z "$ZONE_ID" ]]; then
    echo "Error: DOMAIN, CLOUDFLARE_API_TOKEN, or ZONE_ID is not set."
    exit 1
  fi

  sh_files=(*.sh)
  if [[ ! -e "${sh_files[0]}" ]]; then
    echo "No .sh files found in the directory."
    return
  fi

  # Loop through all .sh files in the current directory
  for file in *.sh; do
    # Skip updating itself
    if [[ "$file" == "$(basename "$0")" ]]; then
      continue
    fi

    # Replace the values in the target script
    sed -i "s/^DOMAIN=.*/DOMAIN=\"$DOMAIN\"/" "$file"
    sed -i "s/^CLOUDFLARE_API_TOKEN=.*/CLOUDFLARE_API_TOKEN=\"$CLOUDFLARE_API_TOKEN\"/" "$file"
    sed -i "s/^ZONE_ID=.*/ZONE_ID=\"$ZONE_ID\"/" "$file"


    echo "Updated: $file"
  done
}

# Main Script
if [ $# -lt 3 ]; then
  echo "Usage: $0 <DOMAIN> <PUBLIC_IP> <CLOUDFLARE_API_TOKEN>"
  exit 1
fi

setup_environment

# Update Zone ID
get_zone_id

# Update other scripts
update_scripts

setup_and_run_app

add_subdomains

# Store token and Zone ID in variables
echo "Cloudflare API Token: $CLOUDFLARE_API_TOKEN"
echo "Zone ID: $ZONE_ID"

# Optional: Export the variables for use in the current shell session
export DOMAIN
export CLOUDFLARE_API_TOKEN
export ZONE_ID

# Confirmation
echo "Environment variables set and scripts updated:
  DOMAIN=$DOMAIN
  CLOUDFLARE_API_TOKEN=$CLOUDFLARE_API_TOKEN
  ZONE_ID=$ZONE_ID"

