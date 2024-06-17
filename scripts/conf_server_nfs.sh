#!/bin/bash
cd "$(dirname "$0")"
directory=$1
if [ ! -d "$directory" ];then
	mkdir -p "$directory"
fi

chmod 777 "$directory"

if dpkg -l keyutils libnfsidmap1 nfs-common rpcbind nfs-kernel-server | grep -q "^ii"; then
    echo "All required packages are already installed."
else
        dpkg -i nfs-server/*.deb
fi

# Modify /etc/exports
search_string1="$directory  *(rw,async,insecure,no_root_squash)"
file_path1="/etc/exports"

if ! grep -qF "$search_string1" "$file_path1"; then
  echo "$search_string1" >> "$file_path1"
fi

# Restarting the nfs service
service nfs-kernel-server restart

echo "Config Finished"
