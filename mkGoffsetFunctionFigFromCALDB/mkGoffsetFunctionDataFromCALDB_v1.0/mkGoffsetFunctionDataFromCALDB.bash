#!/bin/bash

# mkGoffsetFunctionDataFromCALDB

# 2024.12.20 v1.0 by Yuma Aoki (Kindai Univ.)

if [ $# = 6 ] ; then
    cticaldb=$1
    outfile=$2
    ccd_id=$3
    segment=$4
    readnode=$5
    ext=$6
elif [ $# = 5 ] ; then
    cticaldb=$1
    outfile=$2
    ccd_id=$3
    segment=$4
    readnode=$5
    ext='1'
elif [ $# = 4 ] ; then
    cticaldb=$1
    outfile=$2
    ccd_id=$3
    segment=$4
    readnode='0'
    ext='1'
else
    echo "Usage : bash mkGoffsetFunctionDataFromCALDB.bash"
    echo "    \$1 : CTI CALDB (infile)"
    echo "    \$2 : outfile"
    echo "    \$3 : CCD_ID"
    echo "    \$4 : SEGMENT"
    echo "    \$5 : READNODE (Optional; Default=0)"
    echo "    \$6 : FITS file extention (Optional; Default=1)"
    exit
fi

### Variables
n_row='16'

### Print information ###
echo "*** Information"
echo "  CCD_ID   : $ccd_id"
echo "  SEGMENT  : $segment"
echo "  READNODE : $readnode"

if [ ! -e "$cticaldb" ] ; then
    echo "*** Error"
    echo "CTI-CALDB(\$1) does not exist."
    echo "$cticaldb"
    exit
fi
if [ "$ccd_id" != '0' ] && [ "$ccd_id" != '1' ] && [ "$ccd_id" != '2' ] && [ "$ccd_id" != '3' ] ; then
    echo "*** Error"
    echo "CCD_ID(\$2) must be 0, 1, 2 or 3."
    exit
fi
if [ "$segment" != '0' ] && [ "$segment" != '1' ] ; then
    echo "*** Error"
    echo "SEGMENT(\$3) must be 0, 1, 2 or 3."
    exit
fi
if [ "$readnode" != '0' ] && [ "$readnode" != '1' ] ; then
    echo "*** Error"
    echo "READNODE(\$4) must be 0 or 1."
    exit
fi
if [ -e "$outfile" ] ; then
    rm -f $outfile
fi

FDUMP_OPT="page=no pagewidth=256 prhead=no showcol=no showunit=no showrow=no rows=-${n_row} outfile=STDOUT"

### 低エネルギー帯の関数 (PHA < GOFFSET_EBL) ###
FDUMP_COLUMNS='CCD_ID,SEGMENT,READNODE,GOFFSET_AL3,GOFFSET_AL2,GOFFSET_AL1,GOFFSET_AL0'
fdump $FDUMP_OPT columns="${FDUMP_COLUMNS}" infile=${cticaldb}+${ext} | \
    sed 's/E/e/g' | \
    awk -v ccd_id=$ccd_id -v segment=$segment -v readnode=$readnode ' \
        BEGIN \
            {flag=0; count=0} \
        NF==4 && flag==1 && count==3 \
            {printf "low_3_g6=%0.20f\nlow_2_g6=%0.20f\nlow_1_g6=%0.20f\nlow_0_g6=%0.20f\n", $1, $2, $3, $4; count++} \
        NF==4 && flag==1 && count==2 \
            {printf "low_3_g3=%0.20f\nlow_2_g3=%0.20f\nlow_1_g3=%0.20f\nlow_0_g3=%0.20f\n", $1, $2, $3, $4; count++} \
        NF==4 && flag==1 && count==1 \
            {printf "low_3_g2=%0.20f\nlow_2_g2=%0.20f\nlow_1_g2=%0.20f\nlow_0_g2=%0.20f\n", $1, $2, $3, $4; count++} \
        NF==7 && flag==0 && $1==ccd_id && $2==segment && $3==readnode \
            {printf "low_3_g0=%0.20f\nlow_2_g0=%0.20f\nlow_1_g0=%0.20f\nlow_0_g0=%0.20f\n", $4, $5, $6, $7; flag=1; count++} \
        count>=4 \
            {flag=0; count=0} \
        ' \
        >> $outfile

### 中エネルギー帯の関数 (GOFFSET_EBL < PHA < GOFFSET_EBH) ###
FDUMP_COLUMNS='CCD_ID,SEGMENT,READNODE,GOFFSET_AM3,GOFFSET_AM2,GOFFSET_AM1,GOFFSET_AM0'
fdump $FDUMP_OPT columns="${FDUMP_COLUMNS}" infile=${cticaldb}+${ext} | \
    sed 's/E/e/g' | \
    awk -v ccd_id=$ccd_id -v segment=$segment -v readnode=$readnode ' \
        BEGIN \
            {flag=0; count=0} \
        NF==4 && flag==1 && count==3 \
            {printf "mid_3_g6=%0.20f\nmid_2_g6=%0.20f\nmid_1_g6=%0.20f\nmid_0_g6=%0.20f\n", $1, $2, $3, $4; count++} \
        NF==4 && flag==1 && count==2 \
            {printf "mid_3_g3=%0.20f\nmid_2_g3=%0.20f\nmid_1_g3=%0.20f\nmid_0_g3=%0.20f\n", $1, $2, $3, $4; count++} \
        NF==4 && flag==1 && count==1 \
            {printf "mid_3_g2=%0.20f\nmid_2_g2=%0.20f\nmid_1_g2=%0.20f\nmid_0_g2=%0.20f\n", $1, $2, $3, $4; count++} \
        NF==7 && flag==0 && $1==ccd_id && $2==segment && $3==readnode \
            {printf "mid_3_g0=%0.20f\nmid_2_g0=%0.20f\nmid_1_g0=%0.20f\nmid_0_g0=%0.20f\n", $4, $5, $6, $7; flag=1; count++} \
        count>=4 \
            {flag=0; count=0} \
        ' \
        >> $outfile

### 高エネルギー帯の関数 (GOFFSET_EBH < PHA) ###
FDUMP_COLUMNS='CCD_ID,SEGMENT,READNODE,GOFFSET_AH0'
fdump $FDUMP_OPT columns="${FDUMP_COLUMNS}" infile=${cticaldb}+${ext} | \
    sed 's/E/e/g' | \
    awk -v ccd_id=$ccd_id -v segment=$segment -v readnode=$readnode ' \
        BEGIN \
            {flag=0; count=0} \
        NF==1 && flag==1 && count==3 \
            {printf "hig_3_g6=%0.20f\nhig_2_g6=%0.20f\nhig_1_g6=%0.20f\nhig_0_g6=%0.20f\n", 0.0, 0.0, 0.0, $1; count++} \
        NF==1 && flag==1 && count==2 \
            {printf "hig_3_g3=%0.20f\nhig_2_g3=%0.20f\nhig_1_g3=%0.20f\nhig_0_g3=%0.20f\n", 0.0, 0.0, 0.0, $1; count++} \
        NF==1 && flag==1 && count==1 \
            {printf "hig_3_g2=%0.20f\nhig_2_g2=%0.20f\nhig_1_g2=%0.20f\nhig_0_g2=%0.20f\n", 0.0, 0.0, 0.0, $1; count++} \
        NF==4 && flag==0 && $1==ccd_id && $2==segment && $3==readnode \
            {printf "hig_3_g0=%0.20f\nhig_2_g0=%0.20f\nhig_1_g0=%0.20f\nhig_0_g0=%0.20f\n", 0.0, 0.0, 0.0, $4; flag=1; count++} \
        count>=4 \
            {flag=0; count=0} \
        ' \
        >> $outfile

for grade in 0 2 3 6 ; do
for range in 'low' 'mid' 'hig' ; do
    echo "${range}_g${grade}(x) = ${range}_3_g${grade} * x**3 + ${range}_2_g${grade} * x**2 + ${range}_1_g${grade} * x**1 + ${range}_0_g${grade}" >> $outfile
done
done
