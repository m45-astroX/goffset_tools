#!/bin/bash -f

# 2022.04.10

# yuma a


# ref
noise_ref=( 5.0 5.5 6.0 6.5 )
grade_ref=( 0 2 3 6 )

# file
b_param_out='outputGoffsetParam_sub_v0.1.bash'

for noise in ${noise_ref[@]} ; do
    
    for grade in ${grade_ref[@]} ; do
        
        bash $b_param_out 
        
    done
    
done

exit
