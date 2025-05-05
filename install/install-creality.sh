#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Smokeyk00
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/CrealityOfficial/CrealityPrint

# Import Functions und Setup
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/install.func)  # Länka till install.func
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# Installing Dependencies
msg_info "Installing Dependencies"
$STD apt-get update -y
$STD apt-get install -y \
  wget \
  unzip \
  curl \
  libfuse2
msg_ok "Installed Dependencies"

# Template: MySQL Database (optional, if required by your app)
msg_info "Setting up Database (if needed)"
DB_NAME=crealityprint_db
DB_USER=creality
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD mysql -u root -e "CREATE DATABASE $DB_NAME;"
$STD mysql -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED WITH mysql_native_password AS PASSWORD('$DB_PASS');"
$STD mysql -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
    echo "CrealityPrint Credentials"
    echo "Database User: $DB_USER"
    echo "Database Password: $DB_PASS"
    echo "Database Name: $DB_NAME"
} >> ~/crealityprint.creds
msg_ok "Set up Database"

# Setup Application
msg_info "Setting up CrealityPrint"
RELEASE=$(curl -fsSL https://api.github.com/repos/CrealityOfficial/CrealityPrint/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
curl -fsSL -o "CrealityPrint_${RELEASE}.zip" "https://github.com/CrealityOfficial/CrealityPrint/releases/download/${RELEASE}/Creality_Print_Linux.zip"
unzip -q "CrealityPrint_${RELEASE}.zip"
mv "CrealityPrint-${RELEASE}/" "/opt/crealityprint"
echo "${RELEASE}" >/opt/crealityprint_version.txt
msg_ok "Setup CrealityPrint"

# Creating Service (if needed)
msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/crealityprint.service
[Unit]
Description=CrealityPrint Service
After=network.target

[Service]
ExecStart=/opt/crealityprint/CrealityPrint.AppImage
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now crealityprint
msg_ok "Created Service"

motd_ssh
customize

# Cleanup
msg_info "Cleaning up"
rm -f "CrealityPrint_${RELEASE}.zip"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"