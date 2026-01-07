#!/bin/bash -f

# calc Grade Branching Ratio

# 2022.11.25
# yuma aoki


# var
noise_ref=( 0 2 3 4 6 8 )
grade_ref=( 0 1 2 3 4 5 6 7 )
energy_ref=( 0.52keV 0.68keV 1.5keV 5.9keV )

for energy in ${energy_ref[@]} ; do
    
    echo "Energy = ${energy}"
    echo ""
    
    for noise in ${noise_ref[@]} ; do
        
        echo "Noise = ${noise}"
        
        all_cnt=0
        for grade in ${grade_ref[@]} ; do
            
            eval "g${grade}=\$(awk '{sum+=\$2} END {print sum}' corSpec_PHA\${energy}_noise\${noise}_G\${grade}.dat)"
            
            eval "all_cnt=\$(echo \${all_cnt}+\${g${grade}} | bc)"
            
        done
        
        # print result
        for grade in ${grade_ref[@]} ; do
            
            eval "echo \"scale=5; \${g${grade}} / \${all_cnt} * 100\" | bc | xargs printf \"%.2f\n\""
        done
        
        echo ""
        
    done
    
done
