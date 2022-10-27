#!/bin/bash -f

# 2022.04.13

# yuma a


# args
if [ $# != 0 ] ; then
    echo "[]"
    exit
fi

# ref
noise_ref=( 6.4 6.8 7.2 7.6 8.0 8.4 )
grade_ref=( 0 2 3 6 )

# coefficient dir
d_coe='coefficient'

# files
b_outputParam='outputGoffsetParam_sub_v0.1.bash'

# output
for noise in ${noise_ref[@]} ; do
    
    for grade in ${grade_ref[@]} ; do
        
        # file
        inputFile="./${d_coe}/FIT_Result_noise${noise}_G${grade}.csv"
        outputFile="./${d_coe}/coefficient_noise${noise}.csv"
        
        # check file
        if [ ! -e $inputFile ] ; then
            echo "${inputFile} does not exist"
            continue
        fi
        
        # output
        bash $b_outputParam $inputFile >> $outputFile
        
    done
    
done

exit
