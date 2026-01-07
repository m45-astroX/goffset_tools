#!/bin/bash

# searchBestSimData

# 2024.08.24 v1.0 by Yuma Aoki (Kindai Univ.)


VERSION='1.0'
VERSION_SEARCHBESTSIM='1.0'

PYTHON=$PYTHON

if [ $# != 4 ] && [ $# != 5 ] ; then
    echo "Usage : bash mkGoffsetCALDB_v${VERSION}.bash"
    echo "    \$1 : SIMDB directory"
    echo "    \$2 : OBS data directory"
    echo "    \$3 : cticaldbfile(in)"
    echo "    \$4 : cticaldbfile(out)"
    echo "    \$5 : clobber (Y/N; optional)"
    exit
elif [ $# = '4' ] ; then

    d_simdb=$1
    d_obsdata=$2
    cticaldbfile_in=$3
    cticaldbfile_out=$4

    # Check files
    if [ ! -e $cticaldbfile_in ] ; then
        echo "*** Error"
        echo "$cticaldbfile_in does not exist!"
        echo "abort"
        exit
    fi
    if [ -e $cticaldbfile_out ] ; then
        echo "$cticaldbfile_out already exists"
        printf "Do you want to overwrite? (Y/N) "
        read YN
        if [ "$YN" != y ] && [ "$YN" != Y ] && [ "$YN" != yes ] && [ "$YN" != YES ] ; then
            echo "abort"
            exit
        fi
    fi

elif [ $# = '5' ] ; then

    d_simdb=$1
    d_obsdata=$2
    cticaldbfile_in=$3
    cticaldbfile_out=$4
    clobber=$5
    
    # Check files
    if [ ! -e $cticaldbfile_in ] ; then
        echo "*** Error"
        echo "$cticaldbfile_in does not exist!"
        echo "abort"
        exit
    fi
    if [ -e $cticaldbfile_out ] ; then
        if [ "$clobber" != y ] || [ "$clobber" != Y ] || [ "$clobber" != yes ] || [ "$clobber" != YES ] ; then
            rm -f $cticaldbfile_out
        fi
    fi

fi

### Files and directories
SCRIPT_SEARCHBESTSIM="$(cd $(dirname $0) && pwd)/searchBestSimulation_v${VERSION_SEARCHBESTSIM}.c"
BIN_SEARCHBESTSIM="bin_searchbestsim"
SCRIPT_MKCALDB="$(cd $(dirname $0) && pwd)/add_goffset.py"
d_bestsim='sim_bestsimdata'
goffsetparamfile='goffsetParam4mkGoffsetCALDB.csv'

### Variables
cid_list=( 0 1 2 3 )
sid_list=( 0 1 )
grade_list=( 0 2 3 4 6 )
readnode_list=( 0 1 )
FM_ccdname_list=( 'FM02-05' 'FM02-03' 'FM02-06' 'FM02-08' )
FM_segname_list=( 'AB' 'CD' )

GOFFSET_EBL='306.5'
GOFFSET_EBH='2000.0'
GOFFSET_PHCUT='67'

### Compile
gcc -o $BIN_SEARCHBESTSIM $SCRIPT_SEARCHBESTSIM
status=$?
if [ "$status" != 0 ] ; then
    echo "*** Error"
    echo "Compile missed!"
    echo "source file : $SCRIPT_SEARCHBESTSIM"
    echo "abort"
    exit
fi

### Make directory
if [ -e $d_bestsim ] ; then
    rm -f $d_bestsim/*
else
    mkdir $d_bestsim
fi

### Check files
if [ -e $goffsetparamfile ] ; then
    rm -f $goffsetparamfile
fi

### Search best simulation data set
for cid in ${cid_list[@]} ; do
for sid in ${sid_list[@]} ; do
for grade in ${grade_list[@]} ; do

    ### Print status
    echo "Search best simulation data set..."
    echo "CCD_ID  = ${cid}, SEGMENT = ${sid}, GRADE = ${grade}"

    simdbfile="${d_simdb}/simdb_G${grade}.dat"
    simdbfile_linenum=$(cat $simdbfile | wc -l | awk '{print $1}')
    obsdatafile="${d_obsdata}/obsdata_goffset_c${cid}s${sid}_g${grade}.dat"
    obsdatafile_linenum=$(cat $obsdatafile | wc -l | awk '{print $1}')
    best_simdatafile="${d_bestsim}/goffsetParam_c${cid}s${sid}_g${grade}.dat"

    ./$BIN_SEARCHBESTSIM $simdbfile $simdbfile_linenum $obsdatafile $obsdatafile_linenum $best_simdatafile

    echo ""
    
done
done
done


### Make caldb
echo "GOFFSET_FM_NAME, GOFFSET_SEGMENT, GOFFSET_CID, GOFFSET_SEG, GOFFSET_READNODE, GOFFSET_GRADE, GOFFSET_AL0, GOFFSET_AL1, GOFFSET_AL2, GOFFSET_AL3, GOFFSET_AM0, GOFFSET_AM1, GOFFSET_AM2, GOFFSET_AM3, GOFFSET_AH0, GOFFSET_EBL, GOFFSET_EBH, GOFFSET_PHCUT" >> $goffsetparamfile

for cid in ${cid_list[@]} ; do
for sid in ${sid_list[@]} ; do
for readnode in ${readnode_list[@]} ; do
for grade in ${grade_list[@]} ; do

    infile="${d_bestsim}/goffsetParam_c${cid}s${sid}_g${grade}.dat"
    
    a=$(cat $infile | awk 'NR==1{print $2}')
    b=$(cat $infile | awk 'NR==1{print $3}')
    c=$(cat $infile | awk 'NR==1{print $4}')

    GOFFSET_AL0=$c
    GOFFSET_AL1=$b
    GOFFSET_AL2=$a
    GOFFSET_AL3='0.0'
    GOFFSET_AM0=$c
    GOFFSET_AM1=$b
    GOFFSET_AM2='0.0'
    GOFFSET_AM3='0.0'
    GOFFSET_AH0=$(echo "scale=20; ${b} * (${GOFFSET_EBH} - ${GOFFSET_EBL}) + ${c}" | bc | xargs printf "%.20f")

    if [ "$grade" = '3' ] ; then
        grade="34"
    elif [ "$grade" = '4' ] ; then
        continue
    fi

    echo "${FM_ccdname_list[$cid]}, ${FM_segname_list[$sid]}, ${cid}, ${sid}, ${readnode}, ${grade}, ${GOFFSET_AL0}, ${GOFFSET_AL1}, ${GOFFSET_AL2}, ${GOFFSET_AL3}, ${GOFFSET_AM0}, ${GOFFSET_AM1}, ${GOFFSET_AM2}, ${GOFFSET_AM3}, ${GOFFSET_AH0}, ${GOFFSET_EBL}, ${GOFFSET_EBH}, ${GOFFSET_PHCUT}" >> $goffsetparamfile

done
done
done
done

$PYTHON $SCRIPT_MKCALDB $cticaldbfile_in $cticaldbfile_out $goffsetparamfile

### Delete files
rm -f $BIN_SEARCHBESTSIM

exit
