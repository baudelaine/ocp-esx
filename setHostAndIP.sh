#!/bin/sh

NEW_HOSTNAME=$1
DOMAIN="iicparis.fr.ibm.com"
DNS="172.16.160.100"
IFCFG="/etc/sysconfig/network-scripts/ifcfg-ens192"
HOSTNAME=$(hostname -f | awk -F"." '{print $1}')

changeHostname (){

if [ "$HOSTNAME" != "$NEW_HOSTNAME" ]; then

	echo "Change hostname to" $NEW_HOSTNAME.$DOMAIN
	hostnamectl set-hostname $NEW_HOSTNAME.$DOMAIN

fi
}


setStaticIPAddr (){

NEW_IPADDR=$(dig @$DNS $NEW_HOSTNAME.$DOMAIN +short)

DHCP=$(grep -cEi -m 1 '^bootproto="dhcp"' $IFCFG)

if [ "$DHCP" -eq 1 ] && [ ! -z "$NEW_IPADDR" ]; then

	echo "Set static address to" $NEW_IPADDR
	sed -i 's/\(^bootproto="dhcp"\)/#\1/gI' $IFCFG
	sed -i 's/^#\(bootproto="none"\)/\1/gI' $IFCFG
	sed -i 's/^#ipaddr.*$/IPADDR="'$NEW_IPADDR'"/gI' $IFCFG
	sed -i 's/^#\(prefix.*$\)/\1/gI' $IFCFG
	sed -i 's/^#\(gateway.*$\)/\1/gI' $IFCFG
	sed -i 's/^#\(dns1.*$\)/\1/gI' $IFCFG
	sed -i 's/^#\(domain.*$\)/\1/gI' $IFCFG

else

	echo "Change static address to" $NEW_IPADDR
	sed -i 's/^ipaddr.*$/IPADDR="'$NEW_IPADDR'"/gI' $IFCFG

fi

}

changeHostname
setStaticIPAddr

exit 0
