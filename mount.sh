#!/bin/bash

BASE_SHARE_USER="//SRV-INF-001/rep_base_users$"
BASE_SHARE_COMMUNS="//SRV-INF-001/rep_base_communs$"
BASE_SHARE_INFRA="//SRV-INF-001/rep_base_communs$/Infrastructure"

log_message() {
    logger -t mount_shares "$1"
}

verify_commands() {
    local required_cmds=("smbclient" "mount" "grep" "awk" "id")
    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_message "Commande requise non trouvée : $cmd"
            return 1
        fi
    done
}

create_and_mount() {
    local share_path="$1"
    local mount_point="$2"
    mkdir -p "$mount_point" || { log_message "Échec de la création du répertoire : $mount_point"; return 1; }
    if mount | grep -q " $mount_point "; then
        log_message "Montage déjà existant pour $mount_point"
        return
    fi
    sudo mount -t cifs "$share_path" "$mount_point" -o "sec=krb5,uid=$(id -u),gid=$(id -g),vers=3.0" && \
        log_message "Montage réussi de $share_path à $mount_point" || \
        log_message "Échec du montage de $share_path à $mount_point"
}

is_admin() {
    id -Gn "$(whoami)" | grep -o "admins du domaine" > /dev/null
}

if ! verify_commands; then
    exit 1
fi

create_and_mount "$BASE_SHARE_USER/$(whoami)" "$HOME/$(whoami)"

if is_admin; then
    create_and_mount "$BASE_SHARE_INFRA" "$HOME/Communs/Infrastructure"
else
    communs_shares=$(smbclient --use-kerberos=required -N -c 'ls' "$BASE_SHARE_COMMUNS" 2>&1 | awk '/ D / {print $1}' | grep -v '^\.')
    for dir in $communs_shares; do
        create_and_mount "$BASE_SHARE_COMMUNS/$dir" "$HOME/Communs/$dir"
    done
fi
