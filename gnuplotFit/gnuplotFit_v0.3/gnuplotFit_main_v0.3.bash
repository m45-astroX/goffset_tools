#!/bin/bash -f

# 2022.04.09

# yuma a


# args
if [ $# != 0 ] ; then
    echo ""
    exit
fi

# ref
noise_ref=( 6 )
grade_ref=( 0 2 3 4 6 )

# file
b_fit='gnuplotFit_sub_v0.3.bash'

# var (do not change)
f_pdf='FIT_Graph.pdf'
f_fitData='FIT_Result.dat'
f_fitLog='fit.log'
f_fit_MID1='MIDFILE_FOR_GF_1.DAT'
d_infile='./goffsetResult'
d_pdf='./pdf'
d_coe='./coefficient'

# check dir
if [ -d $d_pdf ] ; then
    rm -rf $d_pdf
fi
if [ -d $d_coe ] ; then
    rm -rf $d_coe
fi

# make dir
mkdir $d_pdf
mkdir $d_coe

# auto set y range (y min)
function set_y_min_1 () {
    
    y_min=$(awk 'NR==1 {min=$2} NR>=2 && min>$2 {min=$2} END {print min}' $f_file)
    
    if [ "$(echo "${y_min} >= 0" | bc)" -eq "1" ] ; then
        y_min=$(echo "scale=4; ${y_min} - 0.5" | bc | xargs printf "%.0f")
    else
        y_min=$(echo "scale=4; ${y_min} - 0.5" | bc | xargs printf "%.0f")
    fi
    
}

# auto set y range (y max)
function set_y_max_1 () {
    
    y_max=$(awk 'NR==1 {max=$2} NR>=2 && max<$2 {max=$2} END {print max}' $f_file)
    
    if [ "$(echo "${y_max} >= 0" | bc)" -eq "1" ] ; then
        y_max=$(echo "scale=4; ${y_max} + (${y_max} - ${y_min}) / 8 + 0.5" | bc | xargs printf "%.0f")
    else
        y_max=$(echo "scale=4; ${y_max} + (${y_max} - ${y_min}) / 8 + 0.5" | bc | xargs printf "%.0f")
    fi
        
}

# save coe
function save_coe () {
    
    echo "$(awk '$1=="a"{print $3}' ${f_fitData}), $(awk '$1=="a_err"{print $3}' ${f_fitData})" >> $f_fit_MID1
    echo "$(awk '$1=="b"{print $3}' ${f_fitData}), $(awk '$1=="b_err"{print $3}' ${f_fitData})" >> $f_fit_MID1
    echo "$(awk '$1=="c"{print $3}' ${f_fitData}), $(awk '$1=="c_err"{print $3}' ${f_fitData})" >> $f_fit_MID1
    
}

# noise loop
for noise in ${noise_ref[@]} ; do
    
    # grade loop
    for grade in ${grade_ref[@]} ; do
        
        # file
        f_file="${d_infile}/goffset_noise${noise}_G${grade}.dat"
        
        # check file
        if [ ! -e $f_file ] ; then
            echo "$f_file does not exist"
            continue
        fi
        
        # set yrange
        set_y_min_1
        set_y_max_1
        
        # fit
        bash $b_fit $f_file $grade $y_min $y_max
        
        # save coefficient
        save_coe
        
        # rename
        mv $f_pdf "FIT_Graph_noise${noise}_G${grade}.pdf"
        mv $f_fit_MID1 "FIT_Result_noise${noise}_G${grade}.csv"
        
        # move files
        mv "FIT_Graph_noise${noise}_G${grade}.pdf" ./$d_pdf
        mv "FIT_Result_noise${noise}_G${grade}.csv" ./$d_coe
        
        # remove files
        rm -f $f_fitLog
        rm -f $f_fitData
        
    done

done

exit
