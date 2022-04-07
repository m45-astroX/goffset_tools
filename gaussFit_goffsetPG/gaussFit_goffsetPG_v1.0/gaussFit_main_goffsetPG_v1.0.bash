#!/bin/bash -f

# 2022.03.29
# 2022.04.07

# yuma a


# args
if [ $# != 2 ] ; then
    echo "[specType] [phType]"
    echo "specType : org / cor"
    echo "phType : PHA / PHAS_SUM"
    exit
fi

# ref
noise_ref=( 5.8 6.0 )
PHA0_ref=( 958 )
grade_ref=( 0 2 3 4 6 )

# spec dir
d_dat='dat'

# args
specType=$1
phType=$2

# file
b_fit1='gaussFit_sub_goffsetPG_v1.0.bash'
b_fit2='qdpFit_v1.0.bash'
f_fitData='fitData.dat'

# set fileType and dir
if [ "${specType}" = "org" ] && [ "${phType}" = "PHA" ] ; then
    fileType="orgSpec"
    d_output="fittingResult_org"
elif [ "${specType}" = "org" ] && [ "${phType}" = "PHAS_SUM" ] ; then
    fileType="orgSpec_sum"
    d_output="fittingResult_org_sum"
    grade_ref+=8; grade_ref+=9
elif [ "${specType}" = "cor" ] && [ "${phType}" = "PHA" ] ; then
    fileType="corSpec"
    d_output="fittingResult_cor"
elif [ "${specType}" = "cor" ] && [ "${phType}" = "PHAS_SUM" ] ; then
    fileType="corSpec_sum"
    d_output="fittingResult_cor_sum"
    grade_ref+=8; grade_ref+=9
else
    echo "incollect args"
    exit
fi

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
            
            # read file
            readFile="${d_dat}/${fileType}_PHA${PHA0}_noise${noise}_G${grade}.dat"
            
            # check file
            if [ ! -e $readFile ] ; then
                echo "${readFile} does not exist"
                continue
            fi
            
            # fit
            bash $b_fit1 $readFile
            
            # rename
            mv $f_fitData fitData_${fileType}_PHA${PHA0}_noise${noise}_G${grade}.dat
            
            # move
            mv fitData_${fileType}_PHA${PHA0}_noise${noise}_G${grade}.dat $d_output
            
        done
    
    done
    
done

exit
