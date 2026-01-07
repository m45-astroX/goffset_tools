#!/bin/bash 

# mergeObsGoffsetData_cs

VERSION='1.0'

if [ $# != 2 ] ; then
    echo "Usage : bash mergeObsGoffsetData_cs_v${VERSION}.bash indir_list outdir"
    echo "    indir : A list of obs_GoffsetResults"
    exit
else
    indir_list="$1"
    outdir=$2
fi

cid_list=( 0 1 2 3 )
sid_list=( 0 1 )
grade_list=( 0 2 3 4 6 )

### Check directories
if [ ! -e $outdir ] ; then
    echo "$outdir does not exist!!"
    echo "abort"
    exit
fi

### Merge all grade data
for cid in ${cid_list[@]} ; do
for sid in ${sid_list[@]} ; do

    outfile="${outdir}/goffsetResult_c${cid}s${sid}.dat"

    if [ ! -e "${outfile}" ] ; then
        echo "SKIP SING" >> $outfile
        echo "READ SERR 1 2" >> $outfile
    fi

    for grade in ${grade_list[@]} ; do

        echo "! Grade ${grade}" >> $outfile

        for indir in ${indir_list[@]} ; do

            infile="${indir}/$(/bin/ls -1 ${indir} | grep "c${cid}s${sid}_g${grade}")"
            cat $infile | awk '{print $3, $4, $5, $6}' >> $outfile
        
        done

        echo "NO" >> $outfile

    done

done
done

exit
