#!/bin/bash -f

# 2022.12.20
# 2023.02.01 (v2.0)
# yuma aoki


if [ $# != 2 ] ; then
    printf "[specfile] [masterSpecFile]\n"
    exit
fi

specfile=$1
masterfile=$2

b_margespec='bin_margespec'

if [ ! -e $specfile ] ; then
    echo "${specfile} does not exist.."
fi
if [ ! -e $masterfile ] ; then
    echo "${masterfile} does not exist.."
fi

gcc -o $b_margespec "$(cd $(dirname $0); pwd)/margeSpec_v2.0.c"

./$b_margespec $specfile $masterfile

rm -f $b_margespec

exit
