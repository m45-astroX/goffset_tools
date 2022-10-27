#!/bin/bash -f

# 2022.03.29

# yuma a


# ref
noise_ref=( 6.4 6.8 7.2 7.6 8.0 8.4 )
PHA0_ref=( 80 100 120 150 200 300 400 500 600 800 1000 1200 1600 2000 )

# var
sigma=0.13
trial=100000

# dir
d_master='step2_sigma0.13_2'
d_org="${d_master}/org/dat"
d_cor="${d_master}/cor/dat"
d_org_sum="${d_master}/org_sum/dat"
d_cor_sum="${d_master}/cor_sum/dat"

# file
c_simulate='FakeData_Goffset_PlusNoise_v0.10.2'
f_Event_o='Event_org.dat'
f_Event_c='Event_cor.dat'

# check files
if [ ! -e ${c_simulate}.c ] ; then
    echo "${c_simulate}.c does not exist"
    exit
fi
if [ -e $d_master ] ; then
    echo "${d_master} exists..."
    exit
fi

# remove files
rm -f $c_simulate
rm -f $f_Event_o
rm -f $f_Event_c
rm -f Spectrum_org_G*.dat
rm -f Spectrum_cor_G*.dat
rm -f Spectrum_PhasSum_org_G*.dat
rm -f Spectrum_PhasSum_cor_G*.dat

# make dir
mkdir -p $d_org
mkdir -p $d_cor
mkdir -p $d_org_sum
mkdir -p $d_cor_sum

# compile
gcc -o ${c_simulate} ${c_simulate}.c

# simulate
for PHA0 in ${PHA0_ref[@]} ; do
    
    for noise in ${noise_ref[@]} ; do
        
        # simulate
        ./${c_simulate} $PHA0 $sigma $noise $trial
        
        # rename org, cor
        for grade in $(seq 0 7) ; do
            mv Spectrum_org_G${grade}.dat orgSpec_PHA${PHA0}_noise${noise}_G${grade}.dat
            mv Spectrum_cor_G${grade}.dat corSpec_PHA${PHA0}_noise${noise}_G${grade}.dat
        done
         
        # rename org_sum, cor_sum
        for grade in $(seq 0 9) ; do
            mv Spectrum_PhasSum_org_G${grade}.dat orgSpec_sum_PHA${PHA0}_noise${noise}_G${grade}.dat
            mv Spectrum_PhasSum_cor_G${grade}.dat corSpec_sum_PHA${PHA0}_noise${noise}_G${grade}.dat
        done
        
        # move org
        for grade in $(seq 0 7) ; do
            mv orgSpec_PHA${PHA0}_noise${noise}_G${grade}.dat $d_org
            mv corSpec_PHA${PHA0}_noise${noise}_G${grade}.dat $d_cor
        done
        
        # move cor_sum
        for grade in $(seq 0 9) ; do
            mv orgSpec_sum_PHA${PHA0}_noise${noise}_G${grade}.dat $d_org_sum
            mv corSpec_sum_PHA${PHA0}_noise${noise}_G${grade}.dat $d_cor_sum
        done
        
    done
    
done

# remove
rm -f ${c_simulate}
rm -f $f_Event_o
rm -f $f_Event_c

exit
