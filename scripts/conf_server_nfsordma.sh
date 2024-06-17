#!/bin/bash
cd "$(dirname "$0")"
directory=$1
if [ ! -d "$directory" ];then
	mkdir -p "$directory"
fi

chmod 777 "$directory"

if dpkg -l | grep -w -q nfs-kernel-server; then
	echo
else
	dpkg -i ./nfs-server/*.deb
fi

# Modify /etc/exports
search_string1="$directory  *(rw,async,insecure,no_root_squash)"
file_path1="/etc/exports"

if ! grep -qF "$search_string1" "$file_path1"; then
  echo "$search_string1" >> "$file_path1"
fi

# Load RDMA module
modprobe svcrdma
if lsmod | grep svcrdma > /dev/null; then
    echo "svcrdma load success"
else
    echo "svcrdma load fail"
fi


# Restarting the nfs service
service nfs-kernel-server restart

# Instruct the server to listen to RDMA transmission ports
echo rdma 20049 > /proc/fs/nfsd/portlist
echo "Config Finished"
