#!/bin/bash
cd $(dirname $0)

if [ "$(id -u)" = "0" ]; then
   # configuration nfs-server
   file="/etc/exports"
   text="$(pwd)/log *(rw,async,insecure,no_root_squash)"
   if ! grep -qF "$text" "$file"; then
           echo $text  >> $file
   fi
   systemctl restart nfs-kernel-server
fi

source scripts/func_podsys.sh
delete_logs
get_rsa
check_iplist_format "workspace/iplist.txt"

manager_ip=$(cat config.yaml | grep "manager_ip" | cut -d ":" -f 2 | tr -d ' ')
manager_nic=$(cat config.yaml | grep "manager_nic" | cut -d ":" -f 2 | tr -d ' ')
compute_storage=$(cat config.yaml | grep "compute_storage" | cut -d ":" -f 2 | tr -d ' ')
compute_passwd=$(cat config.yaml | grep "compute_passwd" | cut -d ":" -f 2 | tr -d ' ')
dhcp_s=$(cat config.yaml | grep "dhcp_s" | cut -d ":" -f 2 | tr -d ' ')
dhcp_e=$(cat config.yaml | grep "dhcp_e" | cut -d ":" -f 2 | tr -d ' ')
is_valid_storage "$compute_storage"
subnet_mask=$(get_subnet_mask ${manager_ip})

if docker ps -a --format '{{.Image}}' | grep -q "ainexus:v2.0"; then
    docker stop $(docker ps -a -q --filter ancestor=ainexus:v2.0) > /dev/null
    docker rm $(docker ps -a -q --filter ancestor=ainexus:v2.0) > /dev/null
    docker rmi ainexus:v2.0 > /dev/null
fi

docker import pkgs/ainexus-2.4c ainexus:v2.0 > /dev/null &
pid=$!
while ps -p $pid > /dev/null; do
    echo -n "*"
    sleep 2
done
echo

docker run -e "manager_nic=$manager_nic" -e "manager_ip=$manager_ip" -e "mode=ipxe_ubuntu2204" -e "dhcp_s=$dhcp_s" -e "dhcp_e=$dhcp_e" -e "compute_passwd=$compute_passwd" -e "compute_storage=$compute_storage" -e "NEW_PUB_KEY=$new_pub_key" --name podsys1 --privileged=true -it --network=host -v $PWD/workspace:/var/www/html/workspace -v $PWD/log:/log ainexus:v2.0 /bin/bash

sleep 1
if docker ps -a --format '{{.Image}}' | grep -q "ainexus:v2.0"; then
    docker stop $(docker ps -a -q --filter ancestor=ainexus:v2.0) > /dev/null
    docker rm $(docker ps -a -q --filter ancestor=ainexus:v2.0) > /dev/null
    docker rmi ainexus:v2.0 > /dev/null
fi

if [ "$(id -u)" = "0" ]; then
   # del configuration nfs-server
   file="/etc/exports"
   text="$(pwd)/log *(rw,async,insecure,no_root_squash)"
   if  grep -qF "$text" "$file"; then
          sed -i "/$(sed 's/[^^]/[&]/g' <<< "$text")/d" "$file"
   fi
fi