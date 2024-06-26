#!/bin/bash
cd $(dirname $0)

if [ ! -f "workspace/iplist.txt" ]; then
      echo "Error: workspace/iplist.txt does not exist."
      exit 1
fi

if [ "$(id -u)" != "0" ]; then
   if [ ! -f "hosts.txt" ]; then
        touch hosts.txt
   else
        cat /dev/null > hosts.txt
   fi
else
   if [ ! -f "hosts.txt" ]; then
      touch hosts.txt &&  chmod 666 hosts.txt
   else
      cat /dev/null > hosts.txt
   fi
fi

hosts=$(awk '{split($3, parts, "/"); print parts[1]}' workspace/iplist.txt | grep -v '^$')
for host in ${hosts[*]}
do
   grep -wqF "$host" hosts.txt || echo "$host" >> hosts.txt
done

username="nexus"
machines=()
while IFS= read -r line; do
      machines+=("$line")
done < hosts.txt

for machine in "${machines[@]}"
do
     sudo -u $username ssh-keygen -f "/home/${username}/.ssh/known_hosts" -R "$machine" > /dev/null 2>&1
     sudo -u $username ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "nexus@$machine" "echo 'SSH to $machine successful'" 2>/dev/null
     if [ $? -eq 0 ]; then
        sudo -u $username ssh "nexus@$machine" "date"
        sudo -u $username ssh "nexus@$machine" "exit"
        echo
     else
         echo "Failed to SSH to $machine"
         sed -i "/$machine/d"  hosts.txt
         echo
     fi
done

# ssh localhost
manager_ip=$(cat config.yaml | grep "manager_ip" | cut -d ":" -f 2 | tr -d ' ')
sudo -u $username ssh-keygen -f "/home/${username}/.ssh/known_hosts" -R "manager_ip" > /dev/null 2>&1
sudo -u $username ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "nexus@$manager_ip" "echo 'SSH to $manager_ip successful'" 2>/dev/null
if [ $? -eq 0 ]; then
        sudo -u $username ssh "nexus@$manager_ip" "date"
        sudo -u $username ssh "nexus@$manager_ip" "exit"
        echo
fi
