#!/bin/bash

# consgaussFit

# 2024.08.30 v1.0 by Yuma Aoki (Kindai Univ.)


VERSION='1.0'

if [ $# != 4 ] && [ $# != 3 ] ; then
    echo "Usage : bash consgaussFit_v${VERSION}.bash specfile phmin phmax figure(optional, postscript file)"
    exit
elif [ $# = 3 ] ; then
    infile=$1
    phmin=$2
    phmax=$3
    outfile=''
    flag='1'
elif [ $# = 4 ] ; then
    infile=$1
    phmin=$2
    phmax=$3
    outfile=$4
    flag='0'
fi

### Files
TRASH='/dev/null'
spec_phcut='phcut_spec.tmp'
paramfile_tmp='param.tmp'
peakdata_tmp='consgausfit.tmp'

### Check files
if [ -e $paramfile_tmp ] ; then
    rm -f $paramfile_tmp
fi
if [ -e $spec_phcut ] ; then
    rm -f $spec_phcut
fi
if [ -e $peakdata_tmp ] ; then
    rm -f $peakdata_tmp
fi
if [ -e $outfile ] ; then
    rm -f $outfile
fi

### Cut spectrum
cat $infile | \
    awk -v phmin=$phmin -v phmax=$phmax ' \
    phmin<=$1 && $1<=phmax {printf "%d %d\n", $1, $2} \
    $1<phmin || phmax<$1 {printf "%d 0\n", $1} \
    ' > $spec_phcut

### Find peak
cat $spec_phcut | \
    awk ' \
    BEGIN {MAX_cnt=0} $2>=MAX_cnt {MAX_PHA=$1; MAX_cnt=$2} \
    END {printf "%d %d\n", MAX_PHA, MAX_cnt} \
    ' > $peakdata_tmp

MAX_PHA=$(awk '{print $1}' $peakdata_tmp)
MAX_cnt=$(awk '{print $2}' $peakdata_tmp)
BASE_L=$(awk -v phmin=$phmin '$1==phmin{print $2}' $spec_phcut)
BASE_R=$(awk -v phmax=$phmax '$1==phmax{print $2}' $spec_phcut)
BASE=$(echo "scale=5; (${BASE_L} + ${BASE_R}) / 2" | bc | xargs printf "%.5f")

qdp $infile << EOT 1> $TRASH 2> $TRASH
/null
SKIP SING
CSIZ  2.0
LWIDTH   5.
TIME OFF
LOC 0.05 0.05 1.05 1.
LAB F
LAB  X  PHA (ch)
LAB  Y  Counts (/ch)
R    X $phmin $phmax
MOdel CONS GAUS
$BASE
$MAX_PHA
1
$MAX_cnt
PL
FIT
FIT
FIT
FIT
FIT
FIT
FIT
FIT
FIT
FIT
LAB PA OFF
PL
Hardcopy ${outfile}/cps
PL
WModel ${paramfile_tmp}
PL
quit
EOT

### Print Result
cat $paramfile_tmp | awk '2<=NR && NR<=5 {print $1, $2}'

### Delete files
if [ "$flag" = 1 ] && [ -e "pgplot.ps" ] ; then
    rm -f "pgplot.ps"
fi
rm -f $paramfile_tmp
rm -f $spec_phcut
rm -f $peakdata_tmp

exit
