#!/bin/bash
cd $(dirname $0)

# $1 represents the IP address of the Openldap server
# $2 represents the password for Openldap
server_ip=$1
pw=$2
organization=ldap
ldap_domain=ldap.com
# Set the information that needs to be entered during the installation process in advance
LDAP_ADMIN_PASSWORD=$pw
export DEBIAN_FRONTEND=noninteractive
echo "slapd slapd/password1 password $LDAP_ADMIN_PASSWORD" | debconf-set-selections
echo "slapd slapd/password2 password $LDAP_ADMIN_PASSWORD" | debconf-set-selections

# Install the Openldap server package and its dependencies
dpkg -i ./ldap-server/*.deb

# Verify whether the Openldap service has started
systemctl status slapd
unset DEBIAN_FRONTEND

# Configuring the Openldap server
# LDAP_ ADMIN_ PASSWORD represents the password for Openldap
# LDAP_DOMAIN represents the domain for Openldap
# LDAP_ORGANIZATION represents the organization for Openldap
LDAP_ADMIN_PASSWORD=$pw
LDAP_DOMAIN="$ldap_domain"
LDAP_ORGANIZATION="$organization"
echo "slapd slapd/password1 password $LDAP_ADMIN_PASSWORD" | sudo debconf-set-selections
echo "slapd slapd/domain string $LDAP_DOMAIN" | sudo debconf-set-selections
echo "slapd shared/organization string $LDAP_ORGANIZATION" | sudo debconf-set-selections
dpkg-reconfigure -f noninteractive slapd

# Installing the Openldap client
# Prohibit the appearance of interactive interfaces
export DEBIAN_FRONTEND=noninteractive

# Install the Openldap client package and its dependencies
dpkg -i  ldap-client/*.deb

# Configuring the Openldap client
# Modify /etc/nslcd.conf
nslcd=$(cat << EOF
# /etc/nslcd.conf
# nslcd configuration file. See nslcd.conf(5)
# for details.

# The user and group nslcd should run as.
uid nslcd
gid nslcd

# The location at which the LDAP server(s) should be reachable.
uri ldap://${server_ip}

# The search base that will be used for all queries.
base dc=ldap,dc=com

# The LDAP protocol version to use.
#ldap_version 3

# The DN to bind with for normal lookups.
#binddn cn=annonymous,dc=example,dc=net
#bindpw secret
binddn cn=admin,dc=ldap,dc=com
bindpw ${pw}

# The DN used for password modifications by root.
#rootpwmoddn cn=admin,dc=example,dc=com

# SSL options
#ssl off
#tls_reqcert never
tls_cacertfile /etc/ssl/certs/ca-certificates.crt

# The search scope.
#scope sub
EOF
)
echo "$nslcd" > /etc/nslcd.conf
chmod 600 /etc/nslcd.conf

# Modify /etc/pam.d/common-session
search_string1="session required pam_mkhomedir.so skel=/etc/skel/ umask=0077"
file_path1="/etc/pam.d/common-session"

if ! grep -qF "$search_string1" "$file_path1"; then
  echo "$search_string1" >> "$file_path1"
fi

# Modify /etc/nsswitch.conf
h=$(cat /etc/nsswitch.conf | grep -n passwd | awk -F ":" '{print $1}')
l=$(cat /etc/nsswitch.conf | grep -n group | awk -F ":" '{print $1}' | awk 'NR==1 {print}')
i=$(cat /etc/nsswitch.conf | grep -n shadow | awk -F ":" '{print $1}' | awk 'NR==1 {print}')

sed -i "${h}c passwd:         files systemd ldap"   /etc/nsswitch.conf
sed -i "${l}c group:          files systemd ldap"    /etc/nsswitch.conf
sed -i "${i}c shadow:         files ldap"  /etc/nsswitch.conf

# Restart service
systemctl enable nslcd.service
systemctl restart nslcd.service
systemctl enable oddjobd.service
systemctl restart oddjobd.service
systemctl enable nscd.service
systemctl restart nscd.service

unset DEBIAN_FRONTENDN_FRONTEND