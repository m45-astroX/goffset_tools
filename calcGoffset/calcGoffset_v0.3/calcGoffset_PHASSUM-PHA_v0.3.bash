#!/bin/bash -f

# 2022.03.29

# Goffset = PHAS_SUM[GoodGrade] - PHA


# ref
noise_ref=( 5.8 6.0 )
PHA0_ref=( 958 )
grade_ref=( 0 2 3 4 6 )

# dir
d_master='goffsetResult'
d_fit='fittingResult_cor'
d_sum_fit='fittingResult_cor_sum'
d_temp='TEMPDIR_CALC_GOFFSET'

# var
fit_fileType='corSpec'
sum_fit_fileType='corSpec_sum'

# check dir
if [ -d $tempDir ] ; then
    rm -rf $tempDir
fi
if [ -d $d_master ] ; then
    echo "${d_master} exists"
    exit
fi

# calc goffset
for noise in ${noise_ref[@]} ; do
    
    for grade in ${grade_ref[@]} ; do
        
        for PHA0 in ${PHA0_ref[@]} ; do
            
            # file
            f_fit="${d_fit}/fitData_${fit_fileType}_PHA${PHA0}_noise${noise}_G${grade}.dat"
            f_sum_fit="${d_sum_fit}/fitData_${sum_fit_fileType}_PHA${PHA0}_noise${noise}_G8.dat"
            
            # input val
            PHAS_SUM=$(awk '{printf "%5.6f", $1}' $f_sum_fit)
            PHA=$(awk '{printf "%5.6f", $1}' $f_fit)
            
            # calc goffset
            goffset=$(echo "scale=5; ${PHAS_SUM} - ${PHA}" | bc | xargs printf "%.5f" $1)
            
            # output
            echo "noise = ${noise} Grade = ${grade} goffset = ${goffset}"
            
        done
        
    done
    
done


exit
