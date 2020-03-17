#!/bin/bash
LOCALWEBDIR=~/src/Dukewebsite/
CURDIR=$PWD

DATE=`date -I`

cd $LOCALWEBDIR

# replace date with current date in all project pages
for fn in `ls content/project/*.md`; do
	sed -i -r s/[0-9]{4}-[0-9]{2}-[0-9]{2}/$DATE/ $fn
done

#/snap/hugo/current/bin/hugo
hugo
sed -i -e "s/('\/img\/portrait\.jpg/('\.\/img\/portrait\.jpg/" $LOCALWEBDIR/public/index.html
rsync -ravz $LOCALWEBDIR/public/ math:~/public_html/ --delete
cd $PWD
