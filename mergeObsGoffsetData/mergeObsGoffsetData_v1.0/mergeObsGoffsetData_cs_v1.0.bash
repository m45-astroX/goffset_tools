#!/bin/bash 

# mergeObsGoffsetData_cs

VERSION='1.0'

if [ $# != 2 ] ; then
    echo "Usage : bash mergeObsGoffsetData_cs_v${VERSION}.bash indir outdir"
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

### Merge all grade data
for cid in ${cid_list[@]} ; do
for sid in ${sid_list[@]} ; do

outfile="${outdir}/goffsetResult_c${cid}s${sid}.dat"
echo "SKIP SING" > $outfile
echo "READ SERR 1 2" >> $outfile

for grade in ${grade_list[@]} ; do

    infile="${indir}/goffsetResult_c${cid}s${sid}_g${grade}.dat"
    
    echo "! Grade ${grade}" >> $outfile
    cat $infile | awk '{print $3, $4, $5, $6}' >> $outfile
    echo "NO" >> $outfile
    
done

done
done

exit
