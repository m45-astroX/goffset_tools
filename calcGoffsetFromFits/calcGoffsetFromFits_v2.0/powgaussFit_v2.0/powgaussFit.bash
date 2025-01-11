#!/bin/bash

# powgaussFit

# 2024.10.02 v1.0 by Yuma Aoki (Kindai Univ.)
# List of line colors
#     0=Backg,     1=Foreg,       2=Red,         3=Green,
#     4=Blue,      5=Light blue,  6=Magenta,     7=Yellow,
#     8=Orange,    9=Yel.+Green, 10=Green+Cyan, 11=Blue+Cyan,
#     12=Blue+Mag, 13=Red+Mag,    14=Dark Grey,  15=Light Grey
# 2025.01.11 v2.0 by Yuma Aoki (Kindai Univ.)
#   - fitting statistic を選択できる仕様に変更
#   - fit コマンドを 100 回イタレーションするように変更

VERSION='2.0'

if [ $# != 3 ] && [ $# != 4 ] && [ $# != 5 ] && [ $# != 6 ] ; then
    echo "Usage : bash powgaussFit.bash"
    echo "    \$1 : specfile"
    echo "    \$2 : phmin"
    echo "    \$3 : phmax"
    echo "    \$4 : fit_statistic(optional; Chi(default) or Ml)"
    echo "    \$5 : color(optional)"
    echo "    \$6 : figure(optional; postscript file)"
    echo ""
    echo "      ***** Fit result format *****"
    echo "    l1:  POWR_INDEX   POWR_INDEX_ERR"
    echo "    l2:  POWR_NORM    POWR_NORM_ERR"
    echo "    l3:  GAUS_CENTER  GAUS_CENTER_ERR"
    echo "    l4:  GAUS_WIDTH   GAUS_WIDTH_ERR"
    echo "    l5:  GAUS_NORM    GAUS_NORM_ERR"
    echo ""
    exit
elif [ $# = 3 ] ; then
    infile=$1
    phmin=$2
    phmax=$3
    fit_statistic='Chi'
    color='1'
    outfile=''
    flag='1'    # Whether file is created
elif [ $# = 4 ] ; then
    infile=$1
    phmin=$2
    phmax=$3
    fit_statistic=$4
    color='1'
    outfile=''
    flag='1'
elif [ $# = 5 ] ; then
    infile=$1
    phmin=$2
    phmax=$3
    fit_statistic=$4
    color=$5
    outfile=''
    flag='1'
elif [ $# = 6 ] ; then
    infile=$1
    phmin=$2
    phmax=$3
    fit_statistic=$4
    color=$5
    outfile=$6
    flag='0'
fi

### Files
TRASH='/dev/null'
spec_phcut='phcut_spec.tmp'
paramfile_tmp='param.tmp'
peakdata_tmp='peakdata.tmp'
fitcommand_tmp='fit_command_100.qdp'

### Variables
GAUS_width_init='10'

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
if [ -e $fitcommand_tmp ] ; then
    rm -f $fitcommand_tmp
fi
if [ -e $outfile ] ; then
    rm -f $outfile
fi

### Make fit command file
if [ "$(echo $fit_statistic | tr "[A-Z]" "[a-z]")" = 'ml' ] ; then
    for i in $(seq 1 100) ; do
        echo "Fit Stat Ml I 100" >> $fitcommand_tmp
    done
elif [ "$(echo $fit_statistic | tr "[A-Z]" "[a-z]")" = 'chi' ] ; then
    for i in $(seq 1 100) ; do
        echo "Fit Stat Chi I 100" >> $fitcommand_tmp
    done
else
    echo "fit_statistic (\$4) must be Chi or Ml!"
    exit
fi

### Cut spectrum
cat $infile | \
    awk -v phmin=$phmin -v phmax=$phmax ' \
    phmin<=$1 && $1<=phmax {printf "%d %d\n", $1, $2} \
    $1<phmin || phmax<$1 {printf "%d 0\n", $1} \
    ' > $spec_phcut

### Find peak (Use for Gaussian)
cat $spec_phcut | \
    awk ' \
    BEGIN {MAX_cnt=0} $2>=MAX_cnt {MAX_PHA=$1; MAX_cnt=$2} \
    END {printf "%d %d\n", MAX_PHA, MAX_cnt} \
    ' > $peakdata_tmp

MAX_PHA=$(awk '{print $1}' $peakdata_tmp)
MAX_cnt=$(awk '{print $2}' $peakdata_tmp)

### Calculate powerlaw index and powerlaw norm
# Model : Y=A*X^B
X1=$phmin
X2=$phmax
Y1=$(awk -v phmin=$phmin '$1==phmin{print $2}' $spec_phcut)
Y2=$(awk -v phmax=$phmax '$1==phmax{print $2}' $spec_phcut)
B=$(echo "scale=20; l(${Y1}/${Y2}) / l(${X1}/${X2})" | bc -l)
A=$(echo "scale=20; ${Y1}/e(l(${X1})*${B})" | bc -l)

### Find min count (Use for graph plotting)
MIN_cnt=$(cat $spec_phcut | awk -v phmin=$phmin -v phmax=$phmax 'BEGIN {MIN_cnt=10^10} phmin<=$1 && $1<=phmax && $2<=MIN_cnt {MIN_cnt=$2} END {printf "%d\n", MIN_cnt}')


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
R    X  $phmin $phmax
R    Y  $MIN_cnt $MAX_cnt
COlor   $color on 1
MOdel POWR GAUS
$B
$A
$MAX_PHA
$GAUS_width_init
$(echo "${MAX_cnt} - ${A}*e(l(${MAX_PHA})*${B})" | bc -l)
PL
@${fitcommand_tmp}
LAB PA OFF
PL
Hardcopy ${outfile}/cps
PL
WModel ${paramfile_tmp}
PL
quit
EOT

### Print Result
cat $paramfile_tmp | awk '2<=NR && NR<=6 {print $1, $2}'

### Delete files
if [ "$flag" = 1 ] && [ -e "pgplot.ps" ] ; then
    rm -f "pgplot.ps"
fi
rm -f $paramfile_tmp
rm -f $spec_phcut
rm -f $peakdata_tmp
rm -f $fitcommand_tmp

exit
