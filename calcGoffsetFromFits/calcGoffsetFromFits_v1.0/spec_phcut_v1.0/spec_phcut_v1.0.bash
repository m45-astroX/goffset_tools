#!/bin/bash

# spec_phcut

# 2024.08.02 v1.0 by Yuma Aoki (Kindai Univ.)


VERSION='1.0'

# Variables
UNIT='ch'

if [ $# != 3 ] ; then
    echo "Usage : bash spec_phcut_v${VERSION}.bash specfile phmin phmax"
    exit
else
    infile=$1
    phmin=$2
    phmax=$3
    ext=$(basename $infile | sed 's/.*\.//g')
    outfile="$(basename $infile | sed 's/\..*$//g')_PHCUT_${phmin}-${phmax}${UNIT}.${ext}"
fi

# Check files
if [ ! -e $infile ] ; then
    echo "$infile does not exist"
    echo "abort"
    exit
fi

cat $infile | \
    awk -v phmin=$phmin -v phmax=$phmax ' \
    phmin<=$1 && $1<=phmax {printf "%d %d\n", $1, $2} \
    $1<phmin || phmax<$1 {printf "%d 0\n", $1} \
    ' > $outfile

exit
