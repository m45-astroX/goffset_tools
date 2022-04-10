#!/bin/bash -f

# 2022.03.29

# yuma a

# Goffset = PHAS_SUM[GoodGrade] - PHA


# args
if [ $# != 1 ] ; then
    echo "[specType]"
    echo "specType : org / cor"
    exit
fi

# ref
noise_ref=( 5 6 )
PHA0_ref=( 100 200 500 1000 )
grade_ref=( 0 2 3 4 6 )

# args
specType=$1

# set fileType and dir
if [ "${specType}" = "org" ] ; then
    fit_fileType="orgSpec"
    sum_fit_fileType="orgSpec_sum"
    d_fit='fittingResult_org'
    d_sum_fit='fittingResult_org_sum'
elif [ "${specType}" = "cor" ] ; then
    fit_fileType="corSpec"
    sum_fit_fileType="corSpec_sum"
    d_fit='fittingResult_cor'
    d_sum_fit='fittingResult_cor_sum'
else
    echo "incollect args"
    exit
fi

# dir
d_master='goffsetResult'

# check dir
if [ -d $tempDir ] ; then
    rm -rf $tempDir
fi
if [ -d $d_master ] ; then
    echo "${d_master} exists"
    exit
fi
if [ ! -d $d_fit ] ; then
    echo "${d_fit} does not exists"
    exit
fi
if [ ! -d $d_sum_fit ] ; then
    echo "${d_sum_fit} does not exists"
    exit
fi

# make dir
mkdir $d_master

# calc goffset
for noise in ${noise_ref[@]} ; do
    
    for grade in ${grade_ref[@]} ; do
        
        for PHA0 in ${PHA0_ref[@]} ; do
            
            # file
            f_fit="${d_fit}/fitData_${fit_fileType}_PHA${PHA0}_noise${noise}_G${grade}.dat"
            f_sum_fit="${d_sum_fit}/fitData_${sum_fit_fileType}_PHA${PHA0}_noise${noise}_G8.dat"
            
            # check file
            if [ ! -e $f_fit ] ; then
                echo "${f_fit} does not exists"
                continue
            fi
            if [ ! -e $f_sum_fit ] ; then
                echo "${f_sum_fit} does not exists"
                continue
            fi
            
            # input val
            PHAS_SUM=$(awk '{printf "%5.6f", $1}' $f_sum_fit)
            PHA=$(awk '{printf "%5.6f", $1}' $f_fit)
            
            # calc goffset
            goffset=$(echo "scale=20; ${PHAS_SUM} - ${PHA}" | bc | xargs -n1 printf "%.10f")
            
            # output File
            outputFile="goffset_noise${noise}_G${grade}.dat"
            
            # output
            echo "${PHA} ${goffset}" >> ${d_master}/${outputFile}
            
        done
        
    done
    
done


exit
