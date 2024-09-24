#!/bin/bash
cd $(dirname $0)

system_version=$(lsb_release -ds)
kernel_version=$(uname -r)
gpu_driver_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -n 1)
cuda_version=$(/usr/local/cuda/bin/nvcc --version 2>/dev/null | grep "release" | awk '{print $5}' | tr -d ',')
docker_version=$(docker version --format '{{.Server.Version}}' 2>/dev/null)
nvidia_container_version=$(nvidia-container-cli --version 2>/dev/null | awk '{print $2}' | head -n 1)
ofed_info=$(ofed_info -s 2>/dev/null)
pdsh=$(pdsh -V 2>/dev/null | head -n 1)
nfs_version=$(dpkg-query -W -f='${Version}' nfs-kernel-server 2>/dev/null)
nfs_status=$(systemctl is-active nfs-server 2>/dev/null)

# expected
expected_system_version="Ubuntu 22.04.4 LTS"
expected_kernel_version="5.15.0-94-generic"
expected_gpu_driver_version="535.183.06"
expected_cuda_version="12.2"
expected_docker_version="27.2.1"
expected_nvidia_container_version="1.16.1"
expected_ofed_info="MLNX_OFED_LINUX-23.10-3.2.2.0:"
expected_pdsh="pdsh-2.31 (+debug)"
expected_nfs_version="1:2.6.1-1ubuntu1.2"
expected_nfs_status="active"

all_conditions_met=true

# check system_version
if [ "$system_version" != "$expected_system_version" ]; then
    echo -n "System mismatch: Expected '$expected_system_version', got '$system_version';"
    all_conditions_met=false
fi

#
if [ "$kernel_version" != "$expected_kernel_version" ]; then
    echo -n "Kernel mismatch: Expected '$expected_kernel_version', got '$kernel_version';"
    all_conditions_met=false
fi

#
if [ "$gpu_driver_version" != "$expected_gpu_driver_version" ]; then
    echo -n "GPU Driver mismatch: Expected '$expected_gpu_driver_version', got '$gpu_driver_version';"
    all_conditions_met=false
fi

#
if [ "$cuda_version" != "$expected_cuda_version" ]; then
    echo -n "CUDA mismatch: Expected '$expected_cuda_version', got '$cuda_version';"
    all_conditions_met=false
fi

#
if [ "$docker_version" != "$expected_docker_version" ]; then
    echo -n "Docker mismatch: Expected '$expected_docker_version', got '$docker_version';"
    all_conditions_met=false
fi

#
if [ "$nvidia_container_version" != "$expected_nvidia_container_version" ]; then
    echo -n "NVIDIA Container mismatch: Expected '$expected_nvidia_container_version', got '$nvidia_container_version';"
    all_conditions_met=false
fi

#
if [ "$ofed_info" != "$expected_ofed_info" ]; then
    echo -n "OFED mismatch: Expected '$expected_ofed_info', got '$ofed_info';"
    all_conditions_met=false
fi

#
if [ "$pdsh" != "$expected_pdsh" ]; then
    echo -n "PDSH mismatch: Expected '$expected_pdsh', got '$pdsh';"
    all_conditions_met=false
fi

#
if [ "$nfs_version" != "$expected_nfs_version" ]; then
    echo -n "NFS mismatch: Expected '$expected_nfs_version', got '$nfs_version';"
    all_conditions_met=false
fi

#
if [ "$nfs_status" != "$expected_nfs_status" ]; then
    echo -n "NFS status : Expected '$expected_nfs_status', got '$nfs_status';"
    all_conditions_met=false
fi

#
if $all_conditions_met; then
    echo "PODsys deployment successful"
else
    echo ""
fi

#sleep 10s

#total_mem=$(free -m | awk 'NR==2{print $2}')
#free_mem=$(free -m | awk 'NR==2{print $7}')
#used_mem=$((total_mem - free_mem))
#mem_usage=$((used_mem * 100 / total_mem))
#echo "Total Memory: ${total_mem} MB, Free Memory: ${free_mem} MB, Used Memory: ${used_mem} MB, Memory Usage: ${mem_usage}%"
