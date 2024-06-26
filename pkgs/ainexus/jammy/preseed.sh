#!/bin/bash
cd $(dirname $0)

SN=`dmidecode -t 1|grep Serial|awk -F : '{print $2}'|awk -F ' ' '{print $1}'`
curl -X POST -d "serial=$SN" http://"$1":5000/receive_serial_s
HOSTNAME=`grep $SN ./iplist.txt|awk  '{print $2}'`
network_interface=$(ip route | grep default | awk 'NR==1 {print $5}')

if [ -n "$HOSTNAME" ];then
        sed -i "s/hostname:\ nexus/hostname:\ $HOSTNAME/g"  /autoinstall.yaml
else
        echo "HOSTNAME is Empty"
fi
sed -i "s/nic/$network_interface/g"  /autoinstall.yaml

storage=
sata_list=$(lsblk -o NAME,TRAN | grep "sata" | awk '{print $1}')
nvme_list=$(lsblk -o NAME,TRAN | grep "nvme" | awk '{print $1}')

if ! echo "$sata_list $nvme_list" | grep -qw "$storage"; then
        if [ -n "$nvme_list" ]; then
                newst=nvme0n1
                #sed -i "s/$storage/$newst/g"  /autoinstall.yaml
        else
                newst=sda
                #sed -i "s/$storage/$newst/g"  /autoinstall.yaml
        fi
fi


disk_list=$(lsblk -dno TYPE,NAME | grep -w disk)

if [ -z "$disk_list" ]; then
    curl -X POST -d "serial=$SN&diskstate=none" "http://$1:5000/diskstate"
else
    curl -X POST -d "serial=$SN&diskstate=ok" "http://$1:5000/diskstate"
fi