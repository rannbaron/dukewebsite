#!/bin/bash
LOCALWEBDIR=~/src/Dukewebsite/
CURDIR=$PWD

cd $LOCALWEBDIR
~/go/bin/hugo
sed -i -e "s/('\/img\/portrait\.jpg/('\.\/img\/portrait\.jpg/" $LOCALWEBDIR/public/index.html
rsync -ravz $LOCALWEBDIR/public/ math:~/public_html/testsite/
cd $PWD
