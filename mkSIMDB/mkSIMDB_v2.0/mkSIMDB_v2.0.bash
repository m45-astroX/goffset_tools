#!/bin/bash

# mkSIMDB

# 2024.08.24 v1.0 by Yuma Aoki (Kindai Univ.)
# 2024.12.13 v2.0 by Yuma Aoki (Kindai Univ.)
#   - GoffsetSimulatorの変更に伴う修正

VERSION='2.0'

if [ $# != 2 ] ; then
    echo "Usage : bash mkSIMDB_v${VERSION}.bash goffsetParamDir noiselist"
    exit
else
    goffsetparamdir=$1
    noise_list=$2
fi

### Variable
grade_list=( 0 2 3 4 6 )
range_list=( 'LOW' 'MID' 'HIG' )
index_list=( 'CUBI' 'SQAR' 'LINR' 'CONS' )
d_simdb='sim_SIMDB'
if [ ! -e $d_simdb ] ; then
    mkdir $d_simdb
fi

### Make simdb file
for grade in ${grade_list[@]} ; do
for noise in ${noise_list[@]} ; do

    infile="${goffsetparamdir}/goffsetParam_noise${noise}_G${grade}.csv"
    outfile="${d_simdb}/simdb_G${grade}.dat"
    
    # SIMDB format : noise range a a_err b b_err c c_err
    #   noise : N of simulation
    #   range : (LOW, MID or HIG)

    for range in ${range_list[@]} ; do

    printf "${noise} ${range} " >> $outfile

    for index in ${index_list[@]} ; do

        cat $infile | awk -v v_range="$range" -v v_index="$index" \
            '$1~v_range && $2~v_index {printf "%s %s ", $3, $4}' \
            >> $outfile

    done

    printf "\n" >> $outfile

    done

done
done

exit
