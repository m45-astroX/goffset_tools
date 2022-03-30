#!/bin/bash -f

# 2022.03.14

# yuma a

# inputFile : normal spec file


# args
if [ $# != 5 ] ; then
    echo "[inputFile] [MAX_PHA] [MAX_cnt] [L_PHA] [R_PHA]"
    exit
fi

# args
inputFile=$1
MAX_PHA=$2
MAX_cnt=$3
L_PHA=$4
R_PHA=$5

# var
file_model='MODEL_PARAM_FOR_GAUSSFIT'

# qdp
qdp $inputFile << __EOF__
/null
SKIP SINGLE
r x $L_PHA $R_PHA
MOdel GAUS
$MAX_PHA
$GW
$MAX_cnt
pl
fit on 1
fit
fit
fit
fit
fit
fit
fit
fit
fit
fit
fit
fit
fit
pl
WModel $file_model
__EOF__
exit


