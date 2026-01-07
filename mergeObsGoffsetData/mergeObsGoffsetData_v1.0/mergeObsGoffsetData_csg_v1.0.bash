#!/bin/bash 

# mergeObsGoffsetData_csg

VERSION='1.0'

if [ $# != 2 ] ; then
    echo "Usage : bash mergeObsGoffsetData_csg_v${VERSION}.bash indir outdir"
    exit
else
    indir=$1
    outdir=$2
fi

cid_list=( 0 1 2 3 )
sid_list=( 0 1 )
grade_list=( 0 2 3 4 6 )

### Check directories
if [ ! -e $indir ] ; then
    echo "$indir does not exist!!"
    echo "abort"
    exit
fi
if [ ! -e $outdir ] ; then
    echo "$outdir does not exist!!"
    echo "abort"
    exit
fi

for cid in ${cid_list[@]} ; do
for sid in ${sid_list[@]} ; do
for grade in ${grade_list[@]} ; do

    infile="${indir}/$(/bin/ls -1 ${indir} | grep "goffsetResult_c${cid}s${sid}_g${grade}")"
    outfile="${outdir}/goffsetResult_c${cid}s${sid}_g${grade}.dat"
    
    if [ ! -e $infile ] ; then
        echo "*** Warning"
        echo "$infile does not exist!"
        echo "continue..."
        continue
    fi

    cat $infile >> $outfile
    
done
done
done

exit
