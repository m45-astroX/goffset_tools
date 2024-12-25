#!/bin/bash

# mkSIMDB

# 2024.08.24 v1.0 by Yuma Aoki (Kindai Univ.)
# 2024.12.13 v2.0 by Yuma Aoki (Kindai Univ.)
#   - GoffsetSimulatorの変更に伴う修正
# 2024.12.16 v2.1 by Yuma Aoki (Kindai Univ.)
#   - Goffset補正関数のオフセットを付加したSIMDBを作成できるように変更
# 2024.12.25 v2.2 by Yuma Aoki (Kindai Univ.)
#   - SIMDBディレクトリが既に存在する場合に上書きするかを尋ねる仕様に変更

VERSION='2.2'

if [ $# != 2 ] && [ $# != 3 ] ; then
    echo "Usage : bash mkSIMDB.bash goffsetParamDir noiselist offset(ch; optional)"
    exit
elif [ $# = 2 ] ; then
    goffsetparamdir=$1
    noise_list=$2
    offset='0.0'
    ### Variables
    d_simdb='sim_SIMDB'
elif [ $# = 3 ] ; then
    goffsetparamdir=$1
    noise_list=$2
    offset=$3
    ### Variables
    d_simdb="sim_SIMDB_offset_$(echo ${offset} | sed 's/\./p/g')ch"
    ### Print
    echo "*** Notice"
    echo "SIMDB is created by adding ${offset} ch offset."
fi

### Variable
grade_list=( 0 2 3 4 6 )
range_list=( 'LOW' 'MID' 'HIG' )
index_list=( 'CUBI' 'SQAR' 'LINR' 'CONS' )
if [ -e "$d_simdb" ] ; then
    printf "$d_simdb (\$d_simdb) already exists.\n"
    printf "Do you want to overwrite? (Y/N) "
    read yn
    yn=$(echo $yn | tr [a-z] [A-Z])
    if [ "${yn}" != "Y" ] && [ "${yn}" != "YE" ] && [ "${yn}" != "YES" ] ; then
        echo "abort."
        exit
    fi
else
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

        if [ "$index" = 'CONS' ] ; then
            cat $infile | awk -v v_range="$range" -v v_index="$index" -v v_offset="$offset" \
            '$1~v_range && $2~v_index {printf "%.10f %s ", $3+(v_offset), $4}' \
            >> $outfile
        else
            cat $infile | awk -v v_range="$range" -v v_index="$index" \
            '$1~v_range && $2~v_index {printf "%s %s ", $3, $4}' \
            >> $outfile
        fi

    done

    printf "\n" >> $outfile

    done

done
done

exit
