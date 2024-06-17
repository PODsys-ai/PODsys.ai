#!/bin/bash
cd $(dirname $0)

if [ "$(id -u)" != "0" ]; then  echo "Error:please use sudo" &&  exit 1 ; fi

if [ "$1" = "-nfsordma" ]; then
  if [ $# -lt 3 ]; then
	echo "Error: Insufficient arguements provided."
	echo "Usage:sudo $0 -nfsordma <nfs_server_ip> <server_directory> <client_directory>"
	exit 1
  fi
  echo "config nfsordma client"
  # $2 represents the IP addresses of the NFSoRDMA server
  ip_info=$(ip a | grep -E "inet\s$2\/[0-9]+")
  if [ -z "$ip_info" ]; then
       echo "Error: IP address $2 not found."
       exit 1
  fi
  # $3 represents the directory to be shared by the server
  # $4 represents the client being mounted to the local directory
  server_directory=$3
  client_directory=$4
  if [[ ${server_directory} == /* && ${client_directory} == /* ]];then
	  sudo -u nexus pdsh -l root -R ssh -w ^hosts.txt /home/nexus/podsys/scripts/conf_client_nfsordma.sh $2 $3 $4
  else
	  echo "Please enter an absolute path"
  fi

elif [ "$1" = "-nfs" ]; then
	if [ $# -lt 3 ]; then
		echo "Error: Insufficient arguements provided."
		echo "Usage:sudo $0 -nfs <nfs_server_ip> <server_directory> <client_directory>"
		exit 1
	fi
	echo "config nfs client"
	ip_info=$(ip a | grep -E "inet\s$2\/[0-9]+")
        if [ -z "$ip_info" ]; then
             echo "Error: IP address $2 not found."
             exit 1
        fi
	server_directory=$3
	client_directory=$4
	if [[ ${server_directory} == /* && ${client_directory} == /* ]];then
		sudo -u nexus pdsh -l root -R ssh -w ^hosts.txt /home/nexus/podsys/scripts/conf_client_nfs.sh $2 $3 $4
	else
		echo "Please enter an absolute path"
	fi

elif [ "$1" = "-nis" ]; then
  echo "config nis client"
  #$2 nis server IP
  ip_info=$(ip a | grep -E "inet\s$2\/[0-9]+")
  if [ -z "$ip_info" ]; then
       echo "Error: IP address $2 not found."
       exit 1
  fi
  sudo -u nexus pdsh -l root -R ssh -w ^hosts.txt /home/nexus/podsys/scripts/conf_client_nis.sh $2

elif [ "$1" = "-IPoIB" ];then
  echo "config IPoIB"
  sudo -u nexus pdsh -l root -R ssh -w ^hosts.txt /home/nexus/podsys/scripts/set_client_IPoIB.sh

elif [ "$1" = "-ldap" ];then
  if [ $# -lt 3 ]; then
          echo "Error: Insufficient arguments provided."
          echo "Usage:sudo $0 -ldap <ldap_server_ip> <ldap_password>"
          exit 1
  fi
  echo "config ldap client"
  # $2 represents the IP address of the Openldap server
  ip_info=$(ip a | grep -E "inet\s$2\/[0-9]+")
  if [ -z "$ip_info" ]; then
       echo "Error: IP address $2 not found."
       exit 1
  fi
  # $3 represents the password of Openldap
  sudo -u nexus pdsh -l root -R ssh -w ^hosts.txt /home/nexus/podsys/scripts/conf_client_ldap.sh $2 $3

elif  [ "$1" = "-stress" ];then
        if [ "$2" = "-k" ];then
              sudo -u nexus pdsh -l root -R ssh -w ^hosts.txt pkill stress
        else
              sudo -u nexus pdsh -l root -R ssh -w ^hosts.txt /home/nexus/podsys/scripts/stress_client.sh
        fi
elif  [ "$1" = "-ntp" ];then
    if [ $# -lt 2 ]; then
          echo "Error: Insufficient arguments provided."
          echo "Usage:sudo $0 -ntp server_ip"
          exit 1
    fi
    sudo -u nexus pdsh -l root -R ssh -w ^hosts.txt /home/nexus/podsys/scripts/ntp.sh $2
else
  echo "Invalid argument: $1"
fi
