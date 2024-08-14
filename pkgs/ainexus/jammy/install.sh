#!/bin/bash
cd $(dirname $0)

conf_ip() {
    if [ -f "/iplist.txt" ]; then
        SN=`dmidecode -t 1|grep Serial|awk -F : '{print $2}'|awk -F ' ' '{print $1}'`
        IP=`grep $SN /iplist.txt|awk '{print $3}'`
        GATEWAY=`grep $SN /iplist.txt|awk  '{print $4}'`
        DNS=`grep $SN /iplist.txt|awk '{print $5}'`
        docker0_ip=`grep $SN /iplist.txt|awk '{print $7}'`
        cp /etc/netplan/00-installer-config.yaml /etc/netplan/00-installer-config.yaml.bak
        if [ -n "$IP" ];then
                h=$(cat /etc/netplan/00-installer-config.yaml | grep -n dhcp | awk -F ":" '{print $1}' | awk 'NR==1 {print}')
                sed -i ${h}s/true/false/ /etc/netplan/00-installer-config.yaml
                h=$[$h+1]
                sed -i "${h}i \      addresses: [$IP]"   /etc/netplan/00-installer-config.yaml

                if [ -n "$GATEWAY" ] && [ "$GATEWAY" != "none" ]; then
                        h=$[$h+1]
                        sed -i "${h}i \      routes:"               /etc/netplan/00-installer-config.yaml
                        h=$[$h+1]
                        sed -i "${h}i \        - to: default"       /etc/netplan/00-installer-config.yaml
                        h=$[$h+1]
                        sed -i "${h}i \          via: $GATEWAY"     /etc/netplan/00-installer-config.yaml
                else
                        echo "$SN NO GATEWAY" >> /podsys/conf_ip.log
                fi

                if [ -n "$DNS" ] && [ "$DNS" != "none" ];then
                        h=$[$h+1]
                        sed -i "${h}i \      nameservers:"          /etc/netplan/00-installer-config.yaml
                        h=$[$h+1]
                        sed -i "${h}i \        addresses: [${DNS}]" /etc/netplan/00-installer-config.yaml
                else
                        echo "$SN NO DNS" >> /podsys/conf_ip.log
                fi
                netplan apply
        else
                echo "$SN IP is Empty" >> /podsys/conf_ip.log
        fi

        if [ -n "$docker0_ip" ] && [ "$docker0_ip" != "none" ]; then
             mkdir -p /etc/docker
             if [ ! -f /etc/docker/daemon.json ]; then
                 echo '{"bip": "'"$docker0_ip"'"}' > /etc/docker/daemon.json
             else
                 if grep -q "bip" "/etc/docker/daemon.json"; then
                       sed -i "2c \    \"bip\": \"$docker0_ip\"," /etc/docker/daemon.json
                 else
                       sed -i "1a \    \"bip\": \"$docker0_ip\"," /etc/docker/daemon.json
                 fi
             fi
        fi
    else
        echo "$SN No iplist file" >> /podsys/conf_ip.log
    fi
}

install_compute(){
    SN=`dmidecode -t 1|grep Serial|awk -F : '{print $2}'|awk -F ' ' '{print $1}'`
    HOSTNAME=`grep $SN /iplist.txt|awk  '{print $2}'`
    if [ -z "$HOSTNAME" ];then
            HOSTNAME=$SN
    fi
    timestamp=$(date +%Y-%m-%d_%H-%M-%S)
    install_log="/podsys/${HOSTNAME}_install_${timestamp}.log"
    log_name="${HOSTNAME}_install_${timestamp}.log"
    curl -X POST -d "serial=$SN&log=$log_name" "http://$1:5000/updatelog"

    CUDA=cuda_12.2.2_535.104.05_linux.run
    IB=MLNX_OFED_LINUX-23.10-3.2.2.0-ubuntu22.04-ext
    NVIDIA_DRIVER=NVIDIA-Linux-x86_64-535.183.06.run

    # install deb
    echo -e "\e[32m$(date +%Y-%m-%d_%H-%M-%S) Start install deb------\e[0m"  >> $install_log
    apt purge -y unattended-upgrades    >> $install_log
    dpkg -i ./common/lib/*.deb >> $install_log
    dpkg -i ./common/tools/*.deb >> $install_log
    dpkg -i ./common/docker/*.deb >> $install_log
    dpkg -i ./common/nfs/*.deb >> $install_log
    dpkg -i ./common/updates/*.deb >> $install_log
    echo -e "\e[32m$(date +%Y-%m-%d_%H-%M-%S) Finish install deb------\e[0m"  >> $install_log

    # install MLNX
    if lspci | grep -i "Mellanox"; then
            curl -X POST -d "serial=$SN&ibstate=ok" "http://$1:5000/ibstate"
            echo -e "\e[32m$(date +%Y-%m-%d_%H-%M-%S) Start install MLNX------\e[0m"  >> $install_log
            tar -xzf ib.tgz
            ./ib/${IB}/mlnxofedinstall --without-fw-update --with-nfsrdma --all --force >> $install_log
            echo -e "\e[32m$(date +%Y-%m-%d_%H-%M-%S) Finish install MLNX------\e[0m"  >> $install_log
            rm -rf ib/
            rm -rf ib.tgz
            systemctl enable openibd >> $install_log
    else
            curl -X POST -d "serial=$SN&ibstate=0" "http://$1:5000/ibstate"
            echo -e "\e[32m$(date +%Y-%m-%d_%H-%M-%S) No MLNX Infiniband Device\e[0m"  >> $install_log
    fi

    if lspci | grep -i nvidia; then
          curl -X POST -d "serial=$SN&gpustate=ok" "http://$1:5000/gpustate"
          # install GPU driver
          tar -xzf nvidia.tgz
          echo -e "\e[32m$(date +%Y-%m-%d_%H-%M-%S) Start install GPU driver------\e[0m"  >> $install_log
          touch /etc/modprobe.d/nouveau-blacklist.conf
          echo "blacklist nouveau" |  tee /etc/modprobe.d/nouveau-blacklist.conf
          echo "options nouveau modeset=0" | tee -a /etc/modprobe.d/nouveau-blacklist.conf
          #update-initramfs -u
          ./nvidia/${NVIDIA_DRIVER} --accept-license --no-questions --no-install-compat32-libs --ui=none --disable-nouveau >> $install_log

          # Load nvidia_peermem module
          echo -e "\e[32m$(date +%Y-%m-%d_%H-%M-%S) Start Load nvidia_peermem module------\e[0m"  >> $install_log
          touch /etc/systemd/system/load-nvidia-peermem.service
          echo '[Unit]' >> /etc/systemd/system/load-nvidia-peermem.service
          echo 'Description=Load nvidia_peermem Module' >> /etc/systemd/system/load-nvidia-peermem.service
          echo 'After=network.target' >> /etc/systemd/system/load-nvidia-peermem.service
          echo "" >> /etc/systemd/system/load-nvidia-peermem.service
          echo '[Service]' >> /etc/systemd/system/load-nvidia-peermem.service
          echo 'ExecStart=/sbin/modprobe nvidia_peermem' >> /etc/systemd/system/load-nvidia-peermem.service
          echo "" >> /etc/systemd/system/load-nvidia-peermem.service
          echo '[Install]' >> /etc/systemd/system/load-nvidia-peermem.service
          echo 'WantedBy=multi-user.target' >> /etc/systemd/system/load-nvidia-peermem.service

          # Enable nvidia-persistenced
          echo -e  "\033[32m---Enable nvidia-persistenced---\033[0m"
          echo -e "\e[32m$(date +%Y-%m-%d_%H-%M-%S) Enable nvidia-persistenced------\e[0m"  >> $install_log
          touch /etc/systemd/system/nvidia-persistenced.service
          echo '[Unit]' >> /etc/systemd/system/nvidia-persistenced.service
          echo 'Description=Enable nvidia-persistenced' >> /etc/systemd/system/nvidia-persistenced.service
          echo "" >> /etc/systemd/system/nvidia-persistenced.service
          echo '[Service]' >> /etc/systemd/system/nvidia-persistenced.service
          echo 'Type=oneshot' >> /etc/systemd/system/nvidia-persistenced.service
          echo 'ExecStart=/usr/bin/nvidia-smi -pm 1' >> /etc/systemd/system/nvidia-persistenced.service
          echo 'RemainAfterExit=yes' >> /etc/systemd/system/nvidia-persistenced.service
          echo "" >> /etc/systemd/system/nvidia-persistenced.service
          echo '[Install]' >> /etc/systemd/system/nvidia-persistenced.service
          echo 'WantedBy=default.target' >> /etc/systemd/system/nvidia-persistenced.service

          systemctl daemon-reload  >> $install_log
          systemctl enable load-nvidia-peermem >> $install_log
          systemctl start load-nvidia-peermem >> $install_log
          systemctl enable nvidia-persistenced.service >> $install_log
          systemctl start nvidia-persistenced.service >> $install_log

          # Install nv docker
          dpkg -i ./nvidia/docker/*.deb >> $install_log
          nvidia-ctk runtime configure --runtime=docker >> $install_log
          echo -e "\e[32m$(date +%Y-%m-%d_%H-%M-%S) Finish install nv docker------\e[0m" >> $install_log

          # Install NVIDIA fabricmanager
          echo -e "\e[32m$(date +%Y-%m-%d_%H-%M-%S) Start install NVIDIA fabricmanager------\e[0m"  >> $install_log
          device_id=$(lspci | grep -i nvidia | head -n 1 | awk '{print $7}')
          if [ "$device_id" = "26b9" ]; then
             echo "Does not support NVIDIA fabricmanager" >> $install_log
          else
              dpkg -i ./nvidia/nv-fm/*.deb >> $install_log
              systemctl enable nvidia-fabricmanager.service >> $install_log
              systemctl start nvidia-fabricmanager.service  >> $install_log
          fi

          # Install CUDA
          echo -e "\e[32m$(date +%Y-%m-%d_%H-%M-%S) Start install cuda------\e[0m"  >> $install_log
          ./${CUDA} --silent --toolkit  >> $install_log
          echo 'export PATH=$PATH:/usr/local/cuda/bin' >> /etc/profile
          echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64' >> /etc/profile
          source /etc/profile

          # Install DCGM
          echo -e "\e[32m$(date +%Y-%m-%d_%H-%M-%S) Install NVIDIA DCGM------\e[0m"  >> $install_log
          dpkg -i ./nvidia/dcgm/*.deb >> $install_log
          systemctl --now enable nvidia-dcgm >> $install_log

          # Install NCCL
          echo -e "\e[32m$(date +%Y-%m-%d_%H-%M-%S) Install NVIDIA NCCL------\e[0m"  >> $install_log
          dpkg -i ./nvidia/nccl/*.deb >> $install_log

          # Install cudnn
          echo -e "\e[32m$(date +%Y-%m-%d_%H-%M-%S) Install NVIDIA cuDNN------\e[0m"  >> $install_log
          dpkg -i ./nvidia/cudnn/*.deb >> $install_log


          rm -rf nvidia/
          rm -rf nvidia.tgz
    else
            curl -X POST -d "serial=$SN&gpustate=0" "http://$1:5000/gpustate"
            echo -e "\e[32m$(date +%Y-%m-%d_%H-%M-%S) No NVIDIA GPU Device\e[0m"  >> $install_log

    fi

    systemctl restart docker >> $install_log
    echo -e "\e[32m$(date +%Y-%m-%d_%H-%M-%S) Finish ALL------\e[0m" >> $install_log



}

install_compute "$1"
SN=`dmidecode -t 1|grep Serial|awk -F : '{print $2}'|awk -F ' ' '{print $1}'`
curl -X POST -d "serial=$SN" http://"$1":5000/receive_serial_e

# Limit
content=$(<"/etc/security/limits.conf")
append_if_not_found() {
    local pattern="$1"
    if ! echo "$content" | grep -qF "$pattern"; then
        echo "$pattern" >> /etc/security/limits.conf
    fi
}
append_if_not_found "root soft nofile 65536"
append_if_not_found "root hard nofile 65536"
append_if_not_found "* soft nofile 65536"
append_if_not_found "* hard nofile 65536"
append_if_not_found "* soft stack unlimited"
append_if_not_found "* soft nproc unlimited"
append_if_not_found "* hard stack unlimited"
append_if_not_found "* hard nproc unlimited"

# conf_ip
conf_ip
