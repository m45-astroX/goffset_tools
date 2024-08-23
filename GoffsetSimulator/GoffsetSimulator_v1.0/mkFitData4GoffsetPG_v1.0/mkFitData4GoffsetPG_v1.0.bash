#!/bin/bash

# mkFitData4GoffsetPG

# 2024.08.23 v1.0 by Yuma Aoki (Kindai Univ.)


VERSION='1.0'

if [ $# != 3 ] ; then
    echo "Usage : bash mkFitData4GoffsetPG_v${VERSION}.bash"
    echo "    \$1 : Data directory path of simulation spectra"
    echo "    \$2 : Noise list (Enclose in single or double quotation)"
    echo "    \$3 : PHA0_list (Enclose in single or double quotation)"
    exit
else
    d_specdata=$1
    noise_list=$2
    PHA0_list=$3
fi

### Variables
GRADE_list_for_normalspec=( 0 1 2 3 4 5 6 7 )
GRADE_list_for_PHASSUMspec=( 0 1 2 3 4 5 6 7 8 9 )

### Files, directories and scripts
d_fitdata='sim_fitdata'
fitresultfile='tmp_fitresult.tmp'
script_gaussfit="$(cd $(dirname $0) && pwd)/gaussFit_v2.1.4.bash"

### Check directories
if [ -e $d_fitdata ] ; then
    rm -f $d_fitdata/*
else
    mkdir $d_fitdata
fi

### Fitting (normal spectra) ###
for noise in ${noise_list[@]} ; do
for PHA0 in ${PHA0_list[@]} ; do
for GRADE in ${GRADE_list_for_normalspec[@]} ; do

    ### Files
    specfile="${d_specdata}/cor/dat/corSpec_PHA${PHA0}_noise${noise}_G${GRADE}.dat"
    outfile="${d_fitdata}/fitData_PHA${PHA0}_noise${noise}_G${GRADE}.dat"

    ### Gauss fitting
    bash $script_gaussfit $specfile > $outfile

done
done
done


### Fitting (PHAS SUM spectra) ###
for noise in ${noise_list[@]} ; do
for PHA0 in ${PHA0_list[@]} ; do
for GRADE in ${GRADE_list_for_PHASSUMspec[@]} ; do

    ### Files
    specfile="${d_specdata}/cor_sum/dat/corSpec_sum_PHA${PHA0}_noise${noise}_G${GRADE}.dat"
    outfile="${d_fitdata}/fitData_sum_PHA${PHA0}_noise${noise}_G${GRADE}.dat"

    ### Gauss fitting
    bash $script_gaussfit $specfile > $outfile
    
done
done
done

exit
