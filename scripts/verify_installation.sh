#!/bin/bash
cd $(dirname $0)
log="../log/verify_installation.log"
if [ ! -d "../log" ]; then mkdir ../log; fi
if [ -f "$log" ]; then rm "$log" ; fi
system_version=$(lsb_release -ds)
kernel_version=$(uname -r)
gpu_driver_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n 1)
cuda_version=$(/usr/local/cuda/bin/nvcc --version | grep "release" | awk '{print $5}' | tr -d ',')
docker_version=$(docker version --format '{{.Server.Version}}')
nvidia_container_version=$(nvidia-container-cli --version | awk '{print $2}' | head -n 1)
ofed_info=$(ofed_info -s)

echo "System Version: $system_version"
echo "Kernel Version: $kernel_version"
echo "GPU Driver Version: $gpu_driver_version"
echo "CUDA Version: $cuda_version"
echo "Docker Engine Version: $docker_version"
echo "NVIDIA Container Toolkit Version: $nvidia_container_version"
echo "OFED_INFO: $ofed_info"

echo "System Version: $system_version"         >> "$log"
echo "Kernel Version: $kernel_version"         >> "$log"
echo "GPU Driver Version: $gpu_driver_version" >> "$log"
echo "CUDA Version: $cuda_version"             >> "$log"
echo "Docker Engine Version: $docker_version"  >> "$log"
echo "NVIDIA Container Toolkit Version: $nvidia_container_version" >> "$log"
echo "OFED_INFO: $ofed_info" >> "$log"

lsmod |  grep nvidia_peermem  && lsmod |  grep nvidia_peermem >> "$log"

# PDSH
if command -v pdsh &> /dev/null; then
  echo "pdsh install success" >> "$log"  &&  pdsh -V
else
  echo "pdsh install fail"  && echo "pdsh install fail" >> "$log"
fi

# NIS
if command -v ypbind &> /dev/null && dpkg -s "nis" >/dev/null 2>&1; then
  echo "nis install success" && echo "nis install success" >> "$log"
else
  echo "nis install fail"    && echo "nis install fail"    >> "$log"
fi

# NFS
nfs_installed=$(dpkg-query -W -f='${Status}' nfs-kernel-server 2>/dev/null | grep -c "ok installed")
if [ $nfs_installed -eq 0 ]; then
  echo "nfs install fail" && echo "nfs install fail" >> "$log"
else
  echo "nfs install success"  && echo "nfs install success"  >> "$log"
  nfs_version=$(dpkg-query -W -f='${Version}' nfs-kernel-server)
  nfs_status=$(systemctl is-active nfs-server)
  echo "NFS version: $nfs_version" >> "$log"
  echo "NFS status:  $nfs_status"  >> "$log"
fi

# IB
if ibstat -l | grep mlx5 > /dev/null; then
  echo "IB driver has been installed" >> "$log"
else
  echo "IB driver is not installed" >> "$log"
fi
