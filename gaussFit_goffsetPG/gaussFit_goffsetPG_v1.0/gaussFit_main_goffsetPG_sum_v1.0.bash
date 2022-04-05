#!/bin/bash -f

# 2022.03.29



# ref
noise_ref=( 5.8 6.0 )
PHA0_ref=( 958 )
grade_ref=( 0 2 3 4 6 8 9 )

# dir
d_dat='dat'
d_output='fittingResult'
fileType='corSpec'
#fileType='corSpec_sum'

# file
b_fit1='gaussFit_sub_goffsetPG_v1.0.bash'
b_fit2='qdpFit_v1.0.bash'
f_fitData='fitData.dat'

# check file and dir
if [ ! -e $b_fit1 ] ; then
    echo "${b_fit1} does not exist"
    exit
fi
if [ ! -e $b_fit2 ] ; then
    echo "${b_fit2} does not exist"
    exit
fi
if [ ! -d $d_dat ] ; then
    echo "${d_dat} does not exist"
    exit
fi
if [ -d $d_output ] ; then
    rm -rf $d_output
fi

# mkdir
mkdir $d_output

# fit
for PHA0 in ${PHA0_ref[@]} ; do

    for noise in ${noise_ref[@]} ; do
        
        for grade in ${grade_ref[@]} ; do
            
            bash $b_fit1 ${d_dat}/${fileType}_PHA${PHA0}_noise${noise}_G${grade}.dat
            
            # rename
            mv $f_fitData fitData_${fileType}_PHA${PHA0}_noise${noise}_G${grade}.dat
            
            # move
            mv fitData_${fileType}_PHA${PHA0}_noise${noise}_G${grade}.dat $d_output
            
        done
    
    done
    
done

exit
