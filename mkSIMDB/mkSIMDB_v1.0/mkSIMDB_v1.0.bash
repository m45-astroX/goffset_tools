#!/bin/bash

# mkSIMDB

# 2024.08.24 v1.0 by Yuma Aoki (Kindai Univ.)


VERSION='1.0'

if [ $# != 2 ] ; then
    echo "Usage : bash mkSIMDB_v${VERSION}.bash goffsetParamDir noiselist"
    exit
else
    goffsetparamdir=$1
    noise_list=$2
fi

### Variable
grade_list=( 0 2 3 4 6 )
d_simdb='sim_SIMDB'
if [ ! -e $d_simdb ] ; then
    mkdir $d_simdb
fi

### Make simdb file
for grade in ${grade_list[@]} ; do
for noise in ${noise_list[@]} ; do

    infile="${goffsetparamdir}/goffsetParam_noise${noise}_G${grade}.csv"
    outfile="${d_simdb}/simdb_G${grade}.dat"
    
    # SIMDB format : noise a a_err b b_err c c_err
    printf "${noise} " >> $outfile
    for i in $(seq 1 3) ; do
        
        awk -v i=$i 'NR==i{printf "%s", $1}' $infile | sed 's/,//g; s/e/E/g' | xargs printf "%0.20f " >> $outfile
        awk -v i=$i 'NR==i{printf "%s", $2}' $infile | sed 's/,//g; s/e/E/g' | xargs printf "%0.20f " >> $outfile

        if [ "$i" = 3 ] ; then
            printf "\n" >> $outfile
        fi

    done

done
done

exit
