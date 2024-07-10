#!/bin/bash
cd "$(dirname "$0")"
directory=$1
if [ ! -d "$directory" ];then
        mkdir -p "$directory"
fi

chmod 755 "$directory"


# Modify /etc/exports
search_string1="$directory  *(rw,async,insecure,no_root_squash)"
file_path1="/etc/exports"

if ! grep -qF "$search_string1" "$file_path1"; then
  echo "$search_string1" >> "$file_path1"
fi

# Restarting the nfs service
service nfs-kernel-server restart

echo "Config Finished"