#!/bin/bash

# mkSpecData4GoffsetPG

# 2024.05.18 v1.0 by Yuma Aoki (Kindai Univ.)


VERSION='1.0'

if [ $# != 4 ] ; then
    echo "Usage : bash mkSpecData4GoffsetPG_v${VERSION}.bash"
    echo "    \$1 : The sigma value of electron cloud"
    echo "    \$2 : Event number"
    echo "    \$3 : Noise list (Enclose in single or double quotation)"
    echo "    \$4 : PHA0_list (Enclose in single or double quotation)"
    exit
else
    # Variables
    sigma=$1
    trial=$2
    noise_list=$3
    PHA0_list=$4
fi

# Directories
d_master='sim_specdata'
d_master_evt='sim_evtdata'
d_org="${d_master}/org/dat"
d_cor="${d_master}/cor/dat"
d_org_sum="${d_master}/org_sum/dat"
d_cor_sum="${d_master}/cor_sum/dat"

# Files
f_simulate="$(cd $(dirname $0) && pwd)/eventGen4GoffsetPG_v1.0.c"
f_Event_org='Event_org.dat'
f_Event_cor='Event_cor.dat'
bin_simulate='bin_eventGen4GoffsetPG'

# Check directories and files
if [ ! -e $f_simulate ] ; then
    echo "\$f_simulate ($f_simulate) does not exist!"
    echo "abort"
    exit
fi
if [ -d $d_master ] ; then
    echo "\$d_master ($d_master) already exists!"
    printf "Do you want to overwrite? (Y/N) : "
    read yn
    if [ "$yn" != 'Y' ] && [ "$yn" != 'y' ] && [ "$yn" != 'YES' ] && [ "$yn" != 'yes' ] ; then
        echo "abort"
        exit
    else
        rm -rf $d_master
    fi
fi
if [ -d $d_master_evt ] ; then
    rm -rf $d_master_evt
fi


### Remove files ###
# イベントファイル
if [ -e $f_Event_org ] ; then
    rm -f $f_Event_org
fi
if [ -e $f_Event_cor ] ; then
    rm -f $f_Event_cor
fi
# スペクトルファイル(PHA)
for i in $(seq 0 7) ; do
    # ノイズなし
    file="Spectrum_org_G${i}.dat"
    if [ -e $file ] ; then
        rm -f $file
    fi
    # ノイズあり
    file="Spectrum_cor_G${i}.dat"
    if [ -e $file ] ; then
        rm -f $file
    fi
done
# スペクトルファイル(PHAS_SUM)
for i in $(seq 0 9) ; do
    # ノイズなし
    file="Spectrum_PhasSum_org_G${i}.dat"
    if [ -e $file ] ; then
        rm -f $file
    fi
    # ノイズあり
    file="Spectrum_PhasSum_cor_G${i}.dat"
    if [ -e $file ] ; then
        rm -f $file
    fi
done


### Make dir ###
mkdir $d_master
mkdir $d_master_evt
mkdir -p $d_org
mkdir -p $d_cor
mkdir -p $d_org_sum
mkdir -p $d_cor_sum


# Compile
gcc -o $bin_simulate $f_simulate


# Simulate
for PHA0 in ${PHA0_list[@]} ; do
    
    for noise in ${noise_list[@]} ; do
        
        # Print date
        echo "BEGIN simulation ($(date '+%Y.%m.%d %H:%M:%S'))"
        
        # simulate
        ./${bin_simulate} $PHA0 $sigma $noise $trial
        
        # Rename (org, cor)
        for grade in $(seq 0 7) ; do
            mv Spectrum_org_G${grade}.dat orgSpec_PHA${PHA0}_noise${noise}_G${grade}.dat
            mv Spectrum_cor_G${grade}.dat corSpec_PHA${PHA0}_noise${noise}_G${grade}.dat
        done

        # Rename (org_sum, cor_sum)
        for grade in $(seq 0 9) ; do
            mv Spectrum_PhasSum_org_G${grade}.dat orgSpec_sum_PHA${PHA0}_noise${noise}_G${grade}.dat
            mv Spectrum_PhasSum_cor_G${grade}.dat corSpec_sum_PHA${PHA0}_noise${noise}_G${grade}.dat
        done
        
        # Move files (org, cor)
        for grade in $(seq 0 7) ; do
            mv orgSpec_PHA${PHA0}_noise${noise}_G${grade}.dat $d_org
            mv corSpec_PHA${PHA0}_noise${noise}_G${grade}.dat $d_cor
        done
        
        # Move files (org_sum, cor_sum)
        for grade in $(seq 0 9) ; do
            mv orgSpec_sum_PHA${PHA0}_noise${noise}_G${grade}.dat $d_org_sum
            mv corSpec_sum_PHA${PHA0}_noise${noise}_G${grade}.dat $d_cor_sum
        done

        # Rename and move evtfiles
        # ノイズなし
        f_Event_org_rename="Event_org_PHA${PHA0}_noise_${noise}.dat"
        mv $f_Event_org $f_Event_org_rename
        mv $f_Event_org_rename $d_master_evt/
        gzip "$d_master_evt/$f_Event_org_rename"
        # ノイズあり
        f_Event_cor_rename="Event_cor_PHA${PHA0}_noise_${noise}.dat"
        mv $f_Event_cor $f_Event_cor_rename
        mv $f_Event_cor_rename $d_master_evt/
        gzip "$d_master_evt/$f_Event_cor_rename"
        
    done
    
done

# Delete files
rm -f $bin_simulate
