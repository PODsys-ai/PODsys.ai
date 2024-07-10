#!/bin/bash
bmc_ips=("192.168.1.1"  "192.168.1.2"   "192.168.1.3"   "192.168.1.4"  "192.168.1.5"  "192.168.1.6"  "192.168.1.7"  "192.168.1.8"   "192.168.1.9"   "192.168.1.10"  "192.168.1.11")
user="admin"
passwd="admin"

case "$1" in
    "")
        for bmc_ip in "${bmc_ips[@]}"
        do
            echo "Setting PXE boot for $bmc_ip"
            ipmitool -I lanplus -H $bmc_ip -U $user -P $passwd chassis bootdev pxe
            ipmitool -I lanplus -H $bmc_ip -U $user -P $passwd power reset
            echo
        done
        ;;
    "-poweroff")
        for bmc_ip in "${bmc_ips[@]}"
        do
            echo "Powering off $bmc_ip"
            ipmitool -I lanplus -H $bmc_ip -U $user -P $passwd power off
        done
        ;;
    "-reboot")
        for bmc_ip in "${bmc_ips[@]}"
        do
            echo "Rebooting $bmc_ip"
            ipmitool -I lanplus -H $bmc_ip -U $user -P $passwd power reset
        done
        ;;
    "-poweron")
        for bmc_ip in "${bmc_ips[@]}"
        do
            echo "Powering on $bmc_ip"
            ipmitool -I lanplus -H $bmc_ip -U $user -P $passwd power on
        done
        ;;
    *)
        echo "Usage: $0 [-poweroff | -reboot | -poweron]"
        exit 1
        ;;
esac