#!/bin/bash
cd $(dirname $0)

G_SERVER_IP="$1"
G_DOWNLOAD_MODE="$2"

setup_nfs() {
    wget http://${G_SERVER_IP}:8800/workspace/nfs.tgz
    tar -xzf nfs.tgz
    dpkg -i nfs/*.deb || true
    rm /lib/systemd/system/nfs-common.service || true
    systemctl daemon-reload || true
    systemctl start nfs-common || true
    mkdir -p /target/podsys
    mount -t nfs -o vers=3 ${G_SERVER_IP}:/home/nexus/podsys/workspace /target/podsys || true
}

setup_nfs

if [ "$G_DOWNLOAD_MODE" == "p2p" ]; then
    wget http://${G_SERVER_IP}:8800/workspace/transmission.tgz
    tar -xzf transmission.tgz
    dpkg -i transmission/*.deb || true
    echo "net.core.rmem_max = 4194304" >>/etc/sysctl.conf
    echo "net.core.wmem_max = 1048576" >>/etc/sysctl.conf
    sysctl -p
    systemctl stop transmission-daemon.service
    sed -i 's/"rpc-authentication-required": true,/"rpc-authentication-required": false,/g' "/etc/transmission-daemon/settings.json"
    systemctl start transmission-daemon.service
    sleep 5
    transmission-remote -a /target/podsys/torrents/drivers.torrent -w /tmp/

    declare -a files=("common.tgz" "ib.tgz" "nvidia.tgz" "cuda_12.2.2_535.104.05_linux.run")

    check_files_downloaded() {
        for file in "${files[@]}"; do
            if [ ! -f "/tmp/drivers/$file" ]; then
                return 1
            fi
        done
        return 0
    }

    while true; do
        if check_files_downloaded; then
            break
        else
            sleep 10
        fi
    done
    sleep 1
    tar -xzf /tmp/drivers/common.tgz -C /target/
    tar -xzf /tmp/drivers/ib.tgz -C /target/
    tar -xzf /tmp/drivers/nvidia.tgz -C /target/
    cp /tmp/drivers/cuda_12.2.2_535.104.05_linux.run /target/cuda_12.2.2_535.104.05_linux.run
fi

