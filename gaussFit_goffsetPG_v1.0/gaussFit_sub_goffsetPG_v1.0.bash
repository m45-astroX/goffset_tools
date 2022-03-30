#!/bin/bash -f

# 2022.03.14

# yuma a

# inputFile : normal spec file


# args
if [ $# != 1 ] ; then
    echo "[inputFile]"
    exit
fi

# input args
inputFile=$1
outputFile='fitData.dat'

# var
file_FWHMDATA='MIDFILE_FOR_GAUSFIT_1.DAT'
file_model='MODEL_PARAM_FOR_GAUSSFIT.mod'
x_gaussfit='qdpFit_v1.0.bash'

# check files
if [ ! -e $x_gaussFit ] ; then
    echo "${x_gaussFit} does not exist..."
    exit
fi
if [ -e $file_FWHMDATA ] ; then
    rm -f $file_FWHMDATA
fi
if [ -e $file_model ] ; then
    rm -f $file_model
fi
if [ -e $outputFile ] ; then
    rm -f $outputFile
fi

# find FWHM
awk '$2>=MAX_cnt {MAX_PHA=$1; MAX_cnt=$2} END {printf "C %d %d\n", MAX_PHA, MAX_cnt}' $inputFile >> $file_FWHMDATA
MAX_PHA=$(awk '{print $2}' $file_FWHMDATA)
MAX_cnt=$(awk '{print $3}' $file_FWHMDATA)
FWHM_cnt=$(($MAX_cnt / 2))
# Left
cat $inputFile | awk -v FWHM_cnt=$FWHM_cnt 'BEGIN {FIND=0} $2>=FWHM_cnt && FIND==0 {L_FWHM_PHA=$1; L_FWHM_cnt=$2; FIND=1} END {printf "L %d %d\n", L_FWHM_PHA, L_FWHM_cnt}' >> $file_FWHMDATA
# Right
tac $inputFile | awk -v FWHM_cnt=$FWHM_cnt 'BEGIN {FIND=0} $2>=FWHM_cnt && FIND==0 {R_FWHM_PHA=$1; R_FWHM_cnt=$2; FIND=1} END {printf "R %d %d\n", R_FWHM_PHA, R_FWHM_cnt}' >> $file_FWHMDATA
L_PHA=$(awk '$1=="L" {print $2}' $file_FWHMDATA)
R_PHA=$(awk '$1=="R" {print $2}' $file_FWHMDATA)

# fit
bash $x_gaussfit $inputFile $MAX_PHA $MAX_cnt $L_PHA $R_PHA > /dev/null

# output result
GC=$(awk 'NR==2 {print $1}' $file_model)
GW=$(awk 'NR==3 {print $1}' $file_model)
GN=$(awk 'NR==4 {print $1}' $file_model)

echo "${GC} ${GW} ${GN}" > $outputFile

# remove files
rm -f $file_FWHMDATA
rm -f $file_model

exit

