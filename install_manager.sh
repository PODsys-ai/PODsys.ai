#!/bin/bash
cd $(dirname $0)

if [ "$(id -u)" != "0" ]; then echo "Error:please use sudo" &&  exit 1 ;fi
if [ ! -d "log" ]; then mkdir log; fi

hostname=$(hostname)
timestamp=$(date +%Y-%m-%d_%H-%M-%S)
install_log="./log/${hostname}_install_${timestamp}.log"

# install common deb
echo -e "\033[32m---Install deb---\033[0m"
tar -xzf workspace/common.tgz > /dev/null &
pid=$!
while ps -p $pid > /dev/null; do
    echo -n "*"
    sleep 2
done
echo
echo -e "\e[32m$(date +%Y-%m-%d_%H-%M-%S) Start install deb------\e[0m"  >> $install_log
apt purge -y unattended-upgrades                        >> $install_log
dpkg -i ./common/lib/*.deb                              >> $install_log
dpkg -i ./common/tools/*.deb                              >> $install_log
dpkg -i ./common/docker/*.deb                           >> $install_log
dpkg -i ./scripts/nfs-server/*.deb                      >> $install_log
echo -e "\e[32m$(date +%Y-%m-%d_%H-%M-%S) Finish install deb------\e[0m"  >> $install_log
rm -rf common/

# install MLNX
if lspci | grep -i "Mellanox"; then
        echo -e  "\033[32m---Install MLNX---\033[0m"
        echo -e "\e[32m$(date +%Y-%m-%d_%H-%M-%S) Start install MLNX------\e[0m"  >> $install_log
        tar -xzf workspace/ib.tgz > /dev/null &
        pid=$!
        while ps -p $pid > /dev/null; do
            echo -n "*"
            sleep 2
        done
        echo    
        ./ib/MLNX_OFED_LINUX-23.10-2.1.3.1-ubuntu22.04-ext/mlnxofedinstall \
        --without-fw-update  --with-nfsrdma --all --force >> $install_log
	systemctl enable openibd    >> $install_log
        systemctl enable opensmd     >> $install_log
        echo -e "\e[32m$(date +%Y-%m-%d_%H-%M-%S) Finish install MLNX------\e[0m"  >> $install_log
        rm -rf ib/
else
        echo -e "\033[31m\033[1mno Infiniband controller device\033[0m"  >> $install_log
fi

# Install NVIDIA Driver
if lspci | grep -i "3D controller: NVIDIA"; then
        tar -xzf workspace/nvidia.tgz > /dev/null &
        pid=$!
        while ps -p $pid > /dev/null; do
            echo -n "*"
            sleep 2
        done
        echo  
        echo -e  "\033[32m---Install NVIDIA 3D controller Driver---\033[0m"
        echo -e "\e[32m$(date +%Y-%m-%d_%H-%M-%S) Start install NVIDIA 3D controller Driver------\e[0m"  >> $install_log
        touch /etc/modprobe.d/nouveau-blacklist.conf
        echo "blacklist nouveau" |  tee /etc/modprobe.d/nouveau-blacklist.conf
        echo "options nouveau modeset=0" |  tee -a /etc/modprobe.d/nouveau-blacklist.conf
        update-initramfs -u >> $install_log
        ./nvidia/NVIDIA-Linux-x86_64-535.161.08.run --accept-license --no-questions \
        --no-install-compat32-libs --ui=none --disable-nouveau >> $install_log
	nvidia-smi -pm 1 >> $install_log
        echo -e "\e[32m$(date +%Y-%m-%d_%H-%M-%S) Finish install NVIDIA 3D controller Driver------\e[0m"  >> $install_log

        # Load nvidia_peermem module
        echo -e  "\033[32m---Load nvidia_peermem module---\033[0m"
        echo -e "\e[32m$(date +%Y-%m-%d_%H-%M-%S) Load nvidia_peermem module------\e[0m"  >> $install_log
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
        systemctl daemon-reload             >> $install_log
        systemctl enable load-nvidia-peermem
        systemctl start load-nvidia-peermem >> $install_log

        # Install CUDA-12.2.2
        echo -e "\033[32m---Install CUDA-12.2.2---\033[0m"
        echo -e "\e[32m$(date +%Y-%m-%d_%H-%M-%S) Start install CUDA-12.2.2------\e[0m"  >> $install_log
        ./workspace/cuda_12.2.2_535.104.05_linux.run --silent --toolkit >> $install_log
        echo 'export PATH=$PATH:/usr/local/cuda/bin' >> /etc/profile
        echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64' >> /etc/profile
        source  /etc/profile
        echo -e "\e[32m$(date +%Y-%m-%d_%H-%M-%S) Finish install CUDA-12.2.2------\e[0m"  >> $install_log
        
        # Install nv docker
        echo -e "\033[32m---Install nv docker---\033[0m"
        echo -e "\e[32m$(date +%Y-%m-%d_%H-%M-%S) Start Install nv docker------\e[0m"  >> $install_log
        dpkg -i ./nvidia/docker/*.deb >> $install_log
        nvidia-ctk runtime configure --runtime=docker >> $install_log
        echo -e "\e[32m$(date +%Y-%m-%d_%H-%M-%S) Finish Install nv docker------\e[0m"  >> $install_log

        # Install NVIDIA fabricmanager
        
        echo -e "\e[32m$(date +%Y-%m-%d_%H-%M-%S) Install NVIDIA fabricmanager------\e[0m"  >> $install_log
        device_id=$(lspci | grep -i nvidia | head -n 1 | awk '{print $7}')
        if [ "$device_id" = "26b9" ]; then
           echo "Does not support NVIDIA fabricmanager" >> $install_log
        else
            echo -e "\033[32m---Install NVIDIA fabricmanager---\033[0m"
            dpkg -i ./nvidia/nv-fm/*.deb >> $install_log
            systemctl enable nvidia-fabricmanager.service >> $install_log
            systemctl start nvidia-fabricmanager.service  >> $install_log
        fi
        
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
else
        echo  "no nvidia 3D controller device" >> $install_log
fi

systemctl restart docker >> $install_log

# end
# Check if user entered yes
read -p "Do you want to reboot now? Enter yes or no: " choice
if [ "$choice" = "yes" ]; then
    reboot
else
    echo "Please restart to apply the IB driver."
fi
