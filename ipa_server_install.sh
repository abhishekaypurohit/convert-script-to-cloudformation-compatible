#!/usr/bin/env bash

yum -y install rng-tools

systemctl start rngd
systemctl enable rngd
yum update -y 
echo "#################### Installing wget and pip ###################"
yum -y install wget
wget https://pypi.python.org/packages/source/s/setuptools/setuptools-7.0.tar.gz --no-check-certificate
tar xzf setuptools-7.0.tar.gz
cd setuptools-7.0
python setup.py install
wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py
pip --version

echo "#################### yum install ipa packages ###################"
yum -y install ntp ipa-server ipa-server-dns
systemctl enable ntpd
systemctl start ntpd

out="$(systemctl restart  dbus.service)"
out="$(systemctl restart systemd-logind)"

admin_username=admin
password=asdQWE123
NEW_DOMAIN=cldr.site
uses="Uses: ipaserver_config.sh [admin_username] [admin user password] [domain name for ipa server].
This will install ipa server with provided domain. Hostname of the server will be server.<domain>"

( [[ -z "$admin_username" ]] || [[ -z "$password" ]] || [[ -z "$NEW_DOMAIN" ]] ) && echo $uses && exit 1
export NEW_HOSTNAME=server.$NEW_DOMAIN
export PRIVATE_IP=`hostname -i`
REALM=$(echo $NEW_DOMAIN | awk '{print toupper($0)}')
echo "Starting to install and configure ipa server"
echo "Changing hostname to $NEW_HOSTNAME"

echo ######################## Changing hostname #####################
out="$(hostnamectl set-hostname $NEW_HOSTNAME)"

if [[ "$?" -ne "0" ]]; then
   echo "Error: cannot change hostname"
   exit 1
fi
echo "##################### Updating /etc/cloud/cloud.cfg ################"
out="$(echo "preserve_hostname: true" >> /etc/cloud/cloud.cfg)"

echo "################## updating /etc/resolve.conf #################"
echo "New Domain=$NEW_DOMAIN"
out="$(sed -n "/$NEW_DOMAIN/p" /etc/resolv.conf)"
echo "out=[$out]"
len=${#out}
if [[ "$len" -gt  "0" ]]; then
   echo "found $NEW_DOMAIN in /etc/resolv.conf"
else
   echo "not found, therefore adding, $NEW_DOMAIN in /etc/resolv.conf"
   sed -i '/^search/ s|$|',"${NEW_DOMAIN}"'|' /etc/resolv.conf
   echo "" >> /etc/resolv.conf
   echo "nameserver $PRIVATE_IP" >> /etc/resolv.conf
fi

echo "################## updating /etc/hosts #################"
out="$(sed -n "/server.$NEW_DOMAIN/p" /etc/hosts)"
echo "out=[$out]"
len=${#out}
if [[ "$len" -gt  "0" ]]; then
   echo "found ipa server entry in /etc/hosts file"
else
   echo "adding ipa server entry in /etc/hosts file"
   echo "" >> /etc/hosts
   echo "$PRIVATE_IP server.$NEW_DOMAIN" >> /etc/hosts
fi

echo "################## Installing ipa server #################"

out="$(ipa-server-install \
--realm $REALM \
--domain $NEW_DOMAIN \
--hostname $NEW_HOSTNAME \
-a $password \
-p $password \
--setup-dns \
--forwarder=8.8.8.8 \
--auto-reverse \
--ssh-trust-dns \
--mkhomedir \
--unattended)"
out="$(echo $password | kinit admin )"
echo "################### Adding secondary admin user #######################"
secondAdmin=admin2

out=$(ipa user-add  $secondAdmin --first=ipa --last=admin2 --shell=/bin/bash)
out=$(printf "changeme\nchangeme" | ipa passwd $secondAdmin)
out=$(printf "changeme\n$password\n$password"| kinit $secondAdmin)
out="$(echo $password | kinit admin )"
out=$(ipa group-add-member admins --users=$secondAdmin)
echo "################### Adding ldap bind user #######################"
out=$(ipa user-add ldapbind --first=ldap --last=bind)
out=$(printf "changeme\nchangeme" | ipa passwd ldapbind)
out=$(printf "changeme\n$password\n$password"| kinit ldapbind)
out="$(echo $password | kinit admin )"
out=$(ipa group-add ldap-bind-group --desc="ldap bind user group")
out=$(ipa group-add-member ldap-bind-group --users=ldapbind)

out="$(ipa pwpolicy-add ldap-bind-group \
--maxlife=3650 \
--minlife=1 \
--history=15 \
--maxfail=100000 \
--failinterval=1 \
--lockouttime=1 \
--minclasses=0 \
--minlength=6 \
--priority=999)"

out="$(ipa pwpolicy-add admins \
--maxlife=3650 \
--minlife=1 \
--history=15 \
--maxfail=100000 \
--failinterval=1 \
--lockouttime=1 \
--minclasses=0 \
--minlength=6 \
--priority=10)"



ipa role-add hadoopadminrole
ipa role-add-privilege hadoopadminrole --privileges="User Administrators"
ipa role-add-privilege hadoopadminrole --privileges="Service Administrators"
ipa sudorule-add admin_all_rule
ipa sudorule-mod admin_all_rule --cmdcat=all --hostcat=all
ipa sudorule-add-user admin_all_rule --groups=sudoers
echo -n '!authenticate' | ipa sudorule-add-option admin_all_rule

ipa group-add ambari-managed-principals

ipa group-add sudoers

ip=`hostname -i`
IFS=. read i1 i2 i3 i4 <<< "$ip".
read thparts <<< $i3.$i2.$i1
ipa dnszone-add $thparts.in-addr.arpa.
ipa dnsrecord-add  $thparts.in-addr.arpa. $i4 --ptr-rec=`hostname -f`.
ipa dnszone-show $thparts.in-addr.arpa.
ipa dnsrecord-show $thparts.in-addr.arpa. $i4
ipa config-mod --maxusername=255

echo "################### Finished #######################"
