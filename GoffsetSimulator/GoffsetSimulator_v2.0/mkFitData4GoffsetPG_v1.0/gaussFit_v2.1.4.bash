#!/bin/bash -f

# gaussFit

# 2023.11.29 v2.1 by Yuma Aoki (Kindai Univ.)
#   誤差を出力する使用に変更
# 2023.12.14 v2.1.2 by Yuma Aoki (Kindai Univ.)
#   出力値にEを含んでいる場合に小数で出力する仕様に変更
# 2024.08.02 v2.1.3 by Yuma Aoki (Kindai Univ.)
#   リファクタリング
# 2024.08.23 v2.1.4 by Yuma Aoki (Kindai Univ.)
#   リファクタリング

VERSION='2.1.4'

### Arguments
if [ $# != 1 ] ; then
    echo "Usage : bash gaussFit_v${VERSION}.bash specfile"
    exit
else
    infile=$1
fi

### Variables
tmpfile_fwhmdata='tmpfile4gaussfit_1.tmp'
tmpfile_fitresult='tmpfile4gaussfit_2.tmp'

### Check files
if [ ! -e $infile ] ; then
    exit
fi
if [ -e $tmpfile_fwhmdata ] ; then
    rm -f $tmpfile_fwhmdata
fi
if [ -e $tmpfile_fitresult ] ; then
    rm -f $tmpfile_fitresult
fi


### Find FWHM
awk 'BEGIN {MAX_cnt=0} $2>=MAX_cnt {MAX_PHA=$1; MAX_cnt=$2} END {printf "C %d %d\n", MAX_PHA, MAX_cnt}' $infile >> $tmpfile_fwhmdata
MAX_PHA=$(awk '{print $2}' $tmpfile_fwhmdata)
MAX_cnt=$(awk '{print $3}' $tmpfile_fwhmdata)
FWHM_cnt=$(( $MAX_cnt / 2 ))
# Left
cat $infile | awk -v FWHM_cnt=$FWHM_cnt 'BEGIN {FIND=0} $2>=FWHM_cnt && FIND==0 {L_FWHM_PHA=$1; L_FWHM_cnt=$2; FIND=1} END {printf "L %d %d\n", L_FWHM_PHA, L_FWHM_cnt}' >> $tmpfile_fwhmdata
# Right
tac $infile | awk -v FWHM_cnt=$FWHM_cnt 'BEGIN {FIND=0} $2>=FWHM_cnt && FIND==0 {R_FWHM_PHA=$1; R_FWHM_cnt=$2; FIND=1} END {printf "R %d %d\n", R_FWHM_PHA, R_FWHM_cnt}' >> $tmpfile_fwhmdata
L_PHA=$(awk '$1=="L" {print $2}' $tmpfile_fwhmdata)
R_PHA=$(awk '$1=="R" {print $2}' $tmpfile_fwhmdata)


### Fit by Gaussian
qdp $infile << EOT > /dev/null
/null
SKip Sing
Rescale X $L_PHA $R_PHA
MOdel GAUS
$MAX_PHA
$GW
$MAX_cnt
Fit
Fit
Fit
Fit
Fit
Fit
Fit
Fit
Fit
Fit
WModel $tmpfile_fitresult
q
EOT

### Check files
if [ ! -e "$tmpfile_fitresult" ] ; then
    echo "*** Error"
    echo "fitresultfile does not exist!"
    echo "abort"
    exit
fi

### Output results
GC=$(awk 'NR==2 {print $1}' $tmpfile_fitresult | sed 's/E/e/g' | awk '{printf "%0.8f\n", $1}')
GW=$(awk 'NR==3 {print $1}' $tmpfile_fitresult | sed 's/E/e/g' | awk '{printf "%0.8f\n", $1}')
GN=$(awk 'NR==4 {print $1}' $tmpfile_fitresult | sed 's/E/e/g' | awk '{printf "%0.8f\n", $1}')
GC_ERR=$(awk 'NR==2 {print $2}' $tmpfile_fitresult | sed 's/E/e/g' | awk '{printf "%0.6f\n", $1}')
GW_ERR=$(awk 'NR==3 {print $2}' $tmpfile_fitresult | sed 's/E/e/g' | awk '{printf "%0.6f\n", $1}')
GN_ERR=$(awk 'NR==4 {print $2}' $tmpfile_fitresult | sed 's/E/e/g' | awk '{printf "%0.6f\n", $1}')

echo "${GC} ${GC_ERR}"
echo "${GW} ${GW_ERR}"
echo "${GN} ${GN_ERR}"

# Delete files
rm -f $tmpfile_fwhmdata
rm -f $tmpfile_fitresult

exit
