#!/bin/bash -f

# cutSpec
# yuma aoki

# 2023.01.19 (v1.0)


# args
if [ $# != 4 ] ; then
    echo "[infile] [outfile] [lower] [upper]"
    exit
fi

# file
infile=$1
outfile=$2
lower=$3
upper=$4

if [ ! -e $infile ] ; then
    echo "${infile} does not exist..."
    exit
fi
if [ -e $outfile ] ; then
    rm -f $outfile
fi

# filter
awk -v lower=$lower -v upper=$upper '$1<lower || upper<$1 {printf "%d %d\n", $1, 0} lower<=$1 && $1<=upper {printf "%d %d\n", $1, $2}' $infile > $outfile

exit
