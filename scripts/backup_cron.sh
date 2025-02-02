#!/bin/bash

# Check if both arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <username> <password>"
    exit 1
fi

USERNAME="$1"
PASSWORD="$2"

# Securely store credentials in a hidden file
CREDENTIALS_FILE="$HOME/.secure_credentials"
echo "USERNAME=$USERNAME" > $CREDENTIALS_FILE
echo "PASSWORD=$PASSWORD" >> $CREDENTIALS_FILE
chmod 600 $CREDENTIALS_FILE

# Define the backup script
BACKUP_SCRIPT="$HOME/portainer_backup.sh"

# Create the backup script
cat <<EOF > $BACKUP_SCRIPT
#!/bin/bash

# Load stored credentials
source $CREDENTIALS_FILE

# Authenticate with Portainer to get JWT token
JWT_TOKEN=\$(curl -s -X POST "https://portainer.swiftroc.com/api/auth" \\
  -H "Content-Type: application/json" \\
  -d "{\"username\": \"\$USERNAME\", \"password\": \"\$PASSWORD\"}" | jq -r .jwt)

if [ "\$JWT_TOKEN" == "null" ] || [ -z "\$JWT_TOKEN" ]; then
  echo "Failed to authenticate with Portainer"
  exit 1
fi

# Perform the backup
curl -X POST "https://portainer.swiftroc.com/api/backup" \\
  -H "Authorization: Bearer \$JWT_TOKEN" \\
  -H "Accept: application/octet-stream" \\
  -d '{}' \\
  --output \$HOME/portainer-backup.tar.gz

echo "Backup completed: \$HOME/portainer-backup.tar.gz"
EOF

# Make the script executable
chmod +x $BACKUP_SCRIPT

# Add cron job to run the script daily at midnight
(crontab -l 2>/dev/null; echo "0 0 * * * $BACKUP_SCRIPT") | crontab -

echo "Portainer backup cron job created! It will run daily at midnight."

