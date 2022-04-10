#!/bin/bash -f

# 2022.04.10

# yuma a


# args
if [ $# != 2 ] ; then
    echo "[inputFile] [outputFile(.csv)]"
    exit
fi

# input args
inputFile=$1
outputFile=$2

# var
EBL=306.5
EBH=2000

# input coeficient
a=$(awk 'NR==1 {print $1}' $inputFile)
b=$(awk 'NR==2 {print $1}' $inputFile)
c=$(awk 'NR==3 {print $1}' $inputFile)

# delete ","
a=${a%,*}
b=${b%,*}
c=${c%,*}

# check exp
if [ "$(echo $a | grep -E "e")" != "" ] ; then
    num=$(echo "${a/e*/}")
    exp=$(echo "${a/*e/}")
    a=$(echo "scale=20; ${num} * 10 ^ ${exp}" | bc | xargs printf "%.15f")
fi
if [ "$(echo $b | grep -E "e")" != "" ] ; then
    num=$(echo "${b/e*/}")
    exp=$(echo "${b/*e/}")
    b=$(echo "scale=20; ${num} * 10 ^ ${exp}" | bc | xargs printf "%.15f")
fi
if [ "$(echo $c | grep -E "e")" != "" ] ; then
    num=$(echo "${c/e*}")
    exp=$(echo "${c/*e/}")
    c=$(echo "scale=20; ${num} * 10 ^ ${exp}" | bc | xargs printf "%.15f")
fi

# set var
AL0=${c}
AL1=${b}
AL2=${a}
AL3=0
AM0=${c}
AM1=${b}
AM2=0
AM3=0
AH0=$(echo "scale=20; ${b} * (${EBH} - ${EBL}) + ${c}" | bc | xargs printf "%.15f")

# output
echo "${AL0}, ${AL2}, ${AL3}, ${AM1}, ${AM2}, ${AM3}, ${AL1}, ${AM0}, ${AH0}" >> $outputFile


exit
