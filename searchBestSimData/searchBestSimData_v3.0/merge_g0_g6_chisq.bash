#!/bin/bash

# merge_g0_g6_chisq.bash

# 2024.12.15 v1.0 by Yuma Aoki (Kindai Univ.)


for i in $(seq 0 0.1 10 | xargs printf "%04.1f\n") ; do

    file_g0="chisq_g0_offset_${i}.dat"
    file_g6="chisq_g6_offset_${i}.dat"
    file_merge="chisq_merge_g06_offset_${i}.dat"

    for j in $(seq 1 $(cat ${file_g0} | wc -l)) ; do
        noise=$(awk -v j=$j 'NR==j{print $1}' $file_g0)
        g0_value=$(awk -v j=$j 'NR==j{print $2}' $file_g0)
        g6_value=$(awk -v j=$j 'NR==j{print $2}' $file_g6)
        chisq_sum=$(echo "scale=10; (${g0_value}) + (${g6_value})" | bc | xargs printf "%.10f")
        printf "${noise} ${chisq_sum}\n" >> $file_merge
    done

done
