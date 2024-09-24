#!/bin/bash
bmc_ips=("192.168.1.1"  "192.168.1.2"   "192.168.1.3"   "192.168.1.4"  "192.168.1.5"  "192.168.1.6"  "192.168.1.7"  "192.168.1.8"   "192.168.1.9"   "192.168.1.10"  "192.168.1.11")
user="admin"
passwd="admin"

case "$1" in
"-pxe")
    for bmc_ip in "${bmc_ips[@]}"; do
        echo -n "Setting PXE boot for $bmc_ip:"
        ipmitool -I lanplus -H $bmc_ip -U $user -P $passwd chassis bootdev pxe
        ipmitool -I lanplus -H $bmc_ip -U $user -P $passwd power reset

    done
    ;;
"-poweroff")
    for bmc_ip in "${bmc_ips[@]}"; do
        echo -n "Powering off $bmc_ip:"
        ipmitool -I lanplus -H $bmc_ip -U $user -P $passwd power off
    done
    ;;
"-reboot")
    for bmc_ip in "${bmc_ips[@]}"; do
        echo -n "Rebooting $bmc_ip:"
        ipmitool -I lanplus -H $bmc_ip -U $user -P $passwd power reset
    done
    ;;
"-poweron")
    for bmc_ip in "${bmc_ips[@]}"; do
        echo -n "Powering on $bmc_ip:"
        ipmitool -I lanplus -H $bmc_ip -U $user -P $passwd power on
    done
    ;;
"-status")
    for bmc_ip in "${bmc_ips[@]}"; do
        echo -n "Status of $bmc_ip:"
        ipmitool -I lanplus -H $bmc_ip -U $user -P $passwd power status

    done
    ;;

"-serial")
    for bmc_ip in "${bmc_ips[@]}"; do
        echo -n "SN of $bmc_ip:"
        ipmitool -I lanplus -H $bmc_ip -U $user -P $passwd fru print 0 | grep 'Product Serial'

    done
    ;;

*)
    echo "Usage: $0 [-poweroff | -reboot | -poweron | -status | -pxe | -serial]"
    exit 1
    ;;
esac
