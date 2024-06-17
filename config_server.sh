#!/bin/bash
cd $(dirname $0)

if [ "$(id -u)" != "0" ]; then  echo "Error:please use sudo" &&  exit 1 ; fi

if [ "$1" = "-nfsordma" ];then
	if [ $# -lt 2 ]; then
		echo "Error: Insufficient arguments provided."
		echo "Usage:sudo $0 -nfsordma <share_directory>"
		exit 1
	fi
        echo "config nfs server"
        # $2 shared  floder
	if [[ $2 == /* ]];then
		./scripts/conf_server_nfsordma.sh $2
	else
		echo "Please enter an absolute path"
	fi

elif [ "$1" = "-nfs" ];then
	if [ $# -lt 2 ]; then
		echo "Error: Insufficient arguments provided."
		echo "Usage:sudo $0 -nfs <share_directory>"
		exit 1
	fi
	echo "config nfs server"
	# $2 shared floder
	if [[ $2 == /* ]];then
		./scripts/conf_server_nfs.sh $2
	else
		echo "Please enter an absolute path"
	fi

elif [ "$1" = "-nis" ];then
	if [ $# -lt 2 ]; then
            echo "Error: Insufficient arguments provided."
            echo "Usage: $0 -nis  <nis_server_ip>"
            exit 1
        fi
        echo "config nis server"
        # $2 represents the IP address of the nis server
	ip_info=$(ip a | grep -E "inet\s$2\/[0-9]+")
        if [ -z "$ip_info" ]; then
            echo "Error: IP address $2 not found."
            exit 1
        fi
        ./scripts/conf_server_nis.sh $2

elif [ "$1" = "-ldap" ];then
	if [ $# -lt 3 ]; then
                echo "Error: Insufficient arguments provided."
                echo "Usage:sudo $0 -ldap <ldap_server_ip> <ldap_password>"
                exit 1
         fi
         echo "config ldap server"
         # $2 represents the IP address of the Openldap server
         ip_info=$(ip a | grep -A 1 $2)
         if [ -z "$ip_info" ]; then
            echo "Error: IP address $2 not found."
            exit 1
         fi
	 # $3 represents the password for Openldap
         ./scripts/conf_server_ldap.sh $2 $3
	
elif [ "$1" = "-pre" ];then
	if [ $# -gt 1 ]; then
              echo "Error: Too many arguments provided."
              echo "Usage: $0 -pre"
         exit 1
        fi
        if [ ! -f "workspace/iplist.txt" ]; then
             echo "Error: workspace/iplist.txt does not exist."
             exit 1
        fi
        if [ ! -f "hosts.txt" ]; then
             touch hosts.txt &&  chmod 777 hosts.txt
        else
             cat /dev/null > hosts.txt     
        fi
	mapfile -t mip_array < <(grep "manager_ip" config.yaml | cut -d ":" -f 2 | tr -d ' ')
        hosts=$(awk '{split($3, parts, "/"); print parts[1]}' workspace/iplist.txt | grep -v '^$' | grep -v -E "$(IFS=\| ; echo "${mip_array[*]}")")
        for host in ${hosts[*]}
        do
           grep -wqF "$host" hosts.txt || echo "$host" >> hosts.txt
        done

        if [ ! -f "hosts.txt" ]; then
            echo "Error: Generating hosts.txt failed"
            exit 1
        else
            echo "Generating hosts.txt successfully"
        fi
	# test SSH
        machines=()
        while IFS= read -r line; do
          machines+=("$line")
        done < hosts.txt

        for machine in "${machines[@]}"
        do  
	    sudo -u nexus ssh-keygen -f "/home/nexus/.ssh/known_hosts" -R "$machine" > /dev/null 2>&1
            sudo -u nexus ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "nexus@$machine" "echo 'SSH to $machine successful'" 2>/dev/null
            if [ $? -eq 0 ]; then
                sudo -u nexus ssh "nexus@$machine" "exit"
            else
                echo "Failed to SSH to $machine"
                sed -i "/$machine/d"  hosts.txt
            fi
        done
        # mkdir for client
        folder="podsys"
        sudo -u nexus pdsh -R ssh -w ^hosts.txt "[ -d $folder ] && echo 'Folder podsys already exists' || (mkdir -p $folder)"
        # transfer files to client
        sudo -u nexus pdcp -R ssh -w ^hosts.txt /home/nexus/.ssh/id_rsa     /home/nexus/.ssh/
        sudo -u nexus pdcp -R ssh -w ^hosts.txt /home/nexus/.ssh/id_rsa.pub /home/nexus/.ssh/
        sudo -u nexus pdcp -R ssh -w ^hosts.txt -r scripts  $folder
	sudo -u nexus pdsh -l root -R ssh -w ^hosts.txt  source /etc/profile
	#restart opensm service
#	systemctl restart opensmd
else
        echo "Invalid arguement: $1"
fi
