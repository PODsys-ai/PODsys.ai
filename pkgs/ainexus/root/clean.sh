cd $(dirname $0)
rm -f /etc/dnsmasq.conf
rm -f /srv/tftp/pxe_ubuntu2204/pxelinux.cfg/default
rm -f /srv/tftp/pxe_ubuntu2204/grub/grub.cfg
rm -f /srv/tftp/ipxe_ubuntu2204/ubuntu2204.cfg
rm -f /var/www/html/jammy/user-data
rm -f /var/www/html/jammy/vmlinuz
rm -f /var/www/html/jammy/initrd
rm -rf /root/__pycache__/
rm -f flask.log
rm -f monitor.txt
rm .viminfo
service apache2 stop
service dnsmasq stop
rm /var/log/apache2/access.log
rm /var/log/apache2/other_vhosts_access.log
rm /var/log/apache2/error.log
rm /log/other_vhosts_access.log
rm /log/error.log
rm /log/access.log
cat /dev/null > ~/.bash_history
ps aux | grep app.py