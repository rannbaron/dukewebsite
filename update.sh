#!/bin/bash
set -e

LOCALWEBDIR=~/src/Dukewebsite
MAINWEBDIR=~/src/website/mainwebsite
CURDIR=$PWD

DATE=`date -I`
VPN=DukeVPN

cd $LOCALWEBDIR

echo "==> [1/6] Updating date stamps on course project pages..."
for fn in `ls content/project/*.md`; do
	sed -i -r s/[0-9]{4}-[0-9]{2}-[0-9]{2}/$DATE/ $fn
done

echo "==> [2/6] Building modern Hugo website..."
hugo

echo "==> [3/6] Committing & pushing Duke website source to GitHub and GitLab..."
git add -A
if ! git diff-index --quiet HEAD --; then
	git commit -m "auto: update Duke website content ($DATE)"
	git push github master
	git push origin master
fi

echo "==> [4/6] Deploying compiled Duke website to rannbar-on.com/duke/..."
mkdir -p $MAINWEBDIR/duke
rsync -av --delete $LOCALWEBDIR/public/ $MAINWEBDIR/duke/

cd $MAINWEBDIR
git add duke/ classworksheets105Lpdfs classworksheets106Lpdfs labs105.2018pdfs labs106.2018pdfs 105Lmaterials 106Lmaterials 218pdfs 105lmaterials 106lmaterials project
if ! git diff-index --quiet HEAD --; then
	git commit -m "feat(duke): update Duke site on rannbar-on.com ($DATE)"
	git push origin main
fi

cd $LOCALWEBDIR

echo "==> [5/6] Generating Duke server forwarding & embed layer..."
python3 build_cauchy_forwarder.py

echo "==> [6/6] Syncing forwarder layer to Duke cauchy server..."
DUKE=`curl -s ipinfo.io/org | cut -d ' ' -f 2`
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
rsync -Pravz $LOCALWEBDIR/public_cauchy/ cauchy.math.duke.edu:~/public_html/ --delete
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

echo "==> Duke website update complete!"
