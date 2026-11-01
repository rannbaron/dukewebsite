#!/bin/bash
LOCALWEBDIR=~/src/Dukewebsite/
CURDIR=$PWD

DATE=`date -I`
VPN=DukeVPN

cd $LOCALWEBDIR

# replace date with current date in all project pages
for fn in `ls content/project/*.md`; do
	sed -i -r s/[0-9]{4}-[0-9]{2}-[0-9]{2}/$DATE/ $fn
done

#/snap/hugo/current/bin/hugo
hugo
sed -i -e "s/('\/img\/portrait\.jpg/('\.\/img\/portrait\.jpg/" $LOCALWEBDIR/public/index.html


#while [[ -z `nmcli -t -f NAME c show --active | grep $VPN` ]]; do
#    echo "Not Connected to Duke VPN. Connecting..."
#    nmcli connection up $VPN
#done

#echo "Check Duo to approve login!"

# Are we at Duke?
DUKE=`curl -s ipinfo.io/org | cut -d ' ' -f 2`

# If not, connect to VPN
if [[ $DUKE != Duke ]]; then
	if ! systemctl is-active --quiet vpnagentd; then
		echo "Cisco VPN daemon (vpnagentd) is inactive. Starting service..."
		sudo systemctl start vpnagentd
		sleep 1
	fi

	STATE=`/opt/cisco/secureclient/bin/vpn state | grep state | head -1 | cut -d' ' -f5`
	ATTEMPTS=0
	while [[ $STATE != Connected ]]; do
		if [[ $ATTEMPTS -ge 3 ]]; then
			echo "Error: Failed to connect to Duke VPN after 3 attempts. Please check Cisco Secure Client."
			exit 1
		fi
		echo "Not Connected to Duke VPN. Connecting..."
		/opt/cisco/secureclient/bin/vpn con vpn.duke.edu
		STATE=`/opt/cisco/secureclient/bin/vpn state | grep state | tail -1 | cut -d' ' -f5`
		ATTEMPTS=$((ATTEMPTS + 1))
	done

	echo "Connected to Duke VPN. Proceeding..."
fi

echo "Connecting to math server...Check Duo to approve login!"

rsync -Pravz $LOCALWEBDIR/public/ cauchy.math.duke.edu:~/public_html/ --delete
cd $CURDIR

if [[ $STATE = Connected ]]; then
	while true; do
	    read -p "Disconnect from Duke VPN? " yn
	    case $yn in
	        [Yy]* ) /opt/cisco/secureclient/bin/vpn disconnect; break;;
	        * ) echo "Staying connected!"; break;;
	    esac
	done
fi
#nmcli connection down $VPN
