#!/bin/bash -f

# calcGoffset_goffsetPG_PHASSUM-PHA

# 2022.03.29 v0.3 by Yuna Aoki (Kindai Univ.)
# 2024.08.23 v1.0 by Yuna Aoki (Kindai Univ.)

# Goffset = PHAS_SUM[GoodGrade] - PHA


VERSION='1.0'

if [ $# != 3 ] ; then
    echo "Usage : bash calcGoffset_goffsetPG_PHASSUM-PHA_v${VERSION}.bash"
    echo "    \$1 : Data directory path of fit results"
    echo "    \$2 : Noise list (Enclose in single or double quotation)"
    echo "    \$3 : PHA0_list (Enclose in single or double quotation)"
    exit
else
    d_fitdata=$1
    noise_list=$2
    PHA0_list=$3
fi

### Variables
grade_list=( 0 2 3 4 6 )
d_goffsetResult='sim_goffsetData'

### Check directories
if [ -e "$d_goffsetResult" ] ; then
    rm -f $d_goffsetResult/*
else
    mkdir $d_goffsetResult
fi

### Calculate goffset
for PHA0 in ${PHA0_list[@]} ; do
for noise in ${noise_list[@]} ; do
for grade in ${grade_list[@]} ; do
    
    ### Files
    f_fit="${d_fitdata}/fitData_PHA${PHA0}_noise${noise}_G${grade}.dat"
    f_sum_fit="${d_fitdata}/fitData_sum_PHA${PHA0}_noise${noise}_G8.dat"
    outfile="${d_goffsetResult}/goffset_noise${noise}_G${grade}.dat"

    ### Check files
    if [ ! -e $f_fit ] ; then
        echo "*** Warning"
        echo "$f_fit does not exist!"
        echo "continue..."
        continue
    fi
    if [ ! -e $f_sum_fit ] ; then
        echo "*** Warning"
        echo "$f_sum_fit does not exist!"
        echo "continue..."
        continue
    fi
    
    ### Read values
    PHA=$(awk 'NR==1 {printf "%.10f", $1}' $f_fit)
    PHAS_SUM=$(awk 'NR==1 {printf "%.10f", $1}' $f_sum_fit)
    PHA_ERR=$(awk 'NR==1 {printf "%.10f", $2}' $f_fit)
    PHAS_SUM_ERR=$(awk 'NR==1 {printf "%.10f", $2}' $f_sum_fit)

    ### Calculate goffset
    goffset=$(echo "scale=20; ${PHAS_SUM} - ${PHA}" | bc | xargs printf "%.10f")
    goffset_ERR=$(echo "scale=20; sqrt(${PHA_ERR}^2 + ${PHAS_SUM_ERR}^2)" | bc | xargs printf "%.10f")
    
    ### Print result
    echo "${PHA} ${goffset} ${goffset_ERR}" >> $outfile
    
done
done
done

exit
