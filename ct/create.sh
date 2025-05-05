#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Smokeyk00
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/CrealityOfficial/CrealityPrint

# App Default Values
APP="CrealityPrint"
var_tags="3dprint;creality"
var_cpu="2"
var_ram="2048"
var_disk="8"
var_os="debian"
var_version="12"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources

    if [[ ! -f /home/creality/squashfs-root/AppRun ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    RELEASE=$(curl -fsSL https://api.github.com/repos/CrealityOfficial/CrealityPrint/releases/latest | grep "tag_name" | awk -F'"' '{print $4}')
    if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
        msg_info "Stopping $APP"
        pkill -f CrealityPrint || true
        msg_ok "Stopped $APP"

        msg_info "Creating Backup"
        tar -czf "/opt/${APP}_backup_$(date +%F).tar.gz" /home/creality/
        msg_ok "Backup Created"

        msg_info "Updating $APP to v${RELEASE}"
        pct exec $CTID -- bash -c "
            cd /home/creality &&
            wget -q https://github.com/CrealityOfficial/CrealityPrint/releases/latest/download/Creality_Print_Linux.zip &&
            unzip -q -o Creality_Print_Linux.zip &&
            chmod +x ./CrealityPrint.AppImage &&
            ./CrealityPrint.AppImage --appimage-extract &&
            ln -sf /home/creality/squashfs-root/AppRun /usr/local/bin/crealityprint &&
            chown -R creality:creality /home/creality
        "
        msg_ok "Updated $APP to v${RELEASE}"

        msg_info "Cleaning Up"
        rm -f /home/creality/Creality_Print_Linux.zip
        msg_ok "Cleanup Completed"

        echo "${RELEASE}" >/opt/${APP}_version.txt
        msg_ok "Update Successful"
    else
        msg_ok "No update required. ${APP} is already at v${RELEASE}"
    fi
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:6901${CL}"