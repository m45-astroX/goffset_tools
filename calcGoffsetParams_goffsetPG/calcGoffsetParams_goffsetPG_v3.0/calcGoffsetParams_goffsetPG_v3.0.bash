#!/bin/bash

# calcGoffsetParams_goffsetPG

# 2024.08.23 v1.0 by Yuma Aoki (Kindai Univ.)
# 2024.12.12 v2.0 by Yuma Aoki (Kindai Univ.)
#   - Gnuplotのモデル関数は2022年青木修論(近大)の式(6.1)–(6.3)
#   - モデル関数のパラメータはxtdpiに対応するように出力する

VERSION='2.0'

if [ $# != 2 ] ; then
    echo "Usage : bash calcGoffsetParams_goffsetPG_v${VERSION}.bash"
    echo "    \$1 : Data directory path of goffset data"
    echo "    \$2 : Noise list (Enclose in single or double quotation)"
    exit
else
    d_goffsetdata=$1
    noise_list=$2
fi

### Variables
PH_BOUND_LOWER="306.5"
PH_BOUND_HIGHER="2000.0"
grade_list=( 0 2 3 4 6 )

### Files and directories
fitresultfile='tmp_fitresult_gnuplot.tmp'
d_goffsetparams='sim_GoffsetParams'

### Check files and directories
if [ -e $d_goffsetparams ] ; then
    rm -f $d_goffsetparams/*
else
    mkdir $d_goffsetparams
fi

function gnuplotfit () {

    goffsetdatafile_=$1
    fitresultfile_=$2

    gnuplot << ____EOT >& /dev/null

    ### Define
    f(x) = a * ( x - ${PH_BOUND_LOWER} )**2 + b * ( x - ${PH_BOUND_LOWER} ) + c
    g(x) = b * ( x - ${PH_BOUND_LOWER} ) + c
    h(x) = b * ( ${PH_BOUND_HIGHER} - ${PH_BOUND_LOWER} ) + c
    s(x) = x<${PH_BOUND_LOWER} ? f(x) : x<${PH_BOUND_HIGHER} ? g(x) : h(x)

    ### Fit
    fit s(x) "$goffsetdatafile_" using 1:2:3 via a,b,c

    ### Save variables
    save variables "$fitresultfile_"

    ### exit
    quit

____EOT

    rm -f 'fit.log'

}


function calc_coefficient () {

    # Convert the goffset function
    #   f(x) = a*(x-306.5)^2 + b*(x-306.5) + c
    #   g(x) = b*(x-306.5) + c
    #   h(x) = b*(x-2000.0) + c
    # to
    #   f(x) = A1*x^2 + B1*x + C1
    #   g(x) = B2*x + C2
    #   h(x) = C3

    # Extract from $HEADAS/../hitomixrism/xrism/xtend/tasks/xtdpi/xtdpilib.cxx
    #   goffset_evt = goffset_al0[g_indx] + (goffset_al1[g_indx] * phaEvt) + (goffset_al2[g_indx] * pow(phaEvt,2.0)) + (goffset_al3[g_indx] * pow(phaEvt,3.0))
    #   goffset_evt = goffset_am0[g_indx] + (goffset_am1[g_indx] * phaEvt) + (goffset_am2[g_indx] * pow(phaEvt,2)) + (goffset_am3[g_indx] * pow(phaEvt,3))
    #   goffset_evt = goffset_ah0[g_indx]

    # $1 : LOWER, MIDDLE or HIGHER
    # $2 : CUBIC, SQUARE, LINER or CONSTANT
    RANGE=$1
    INDEX=$2
    a=$3; a_err=$4
    b=$5; b_err=$6
    c=$7; c_err=$8

    if [ "$RANGE" = "LOWER" ] ; then

        if [ "$INDEX" = "CUBIC" ] ; then
            value=0
            value_err=0
        elif [ "$INDEX" = "SQUARE" ] ; then
            value="$a"
            value_err=0
        elif [ "$INDEX" = "LINER" ] ; then
            value="$(echo "scale=10; -2*${a}*${PH_BOUND_LOWER}+${b}" | bc | xargs printf "%0.10f")"
            value_err=0
        elif [ "$INDEX" = "CONSTANT" ] ; then
            value="$(echo "scale=10; ${a}*${PH_BOUND_LOWER}^2 - ${b}*${PH_BOUND_LOWER} + ${c}" | bc | xargs printf "%0.10f")"
            value_err=0
        else
            echo "*** Warning" 1>&2
            echo "Calculation of the coefficient was skipped!" 1>&2
            echo "Details : \$1=$1, \$2=$2" 1>&2
        fi

    elif [ "$RANGE" = "MIDDLE" ] ; then

        if [ "$INDEX" = "CUBIC" ] ; then
            value=0
            value_err=0
        elif [ "$INDEX" = "SQUARE" ] ; then
            value=0
            value_err=0
        elif [ "$INDEX" = "LINER" ] ; then
            value="$b"
            value_err=0
        elif [ "$INDEX" = "CONSTANT" ] ; then
            value="$(echo "scale=10; -1*${b}*${PH_BOUND_LOWER} + ${c}" | bc | xargs printf "%0.10f")"
            value_err=0
        else
            echo "*** Warning" 1>&2
            echo "Calculation of the coefficient was skipped!" 1>&2
            echo "Details : \$1=$1, \$2=$2" 1>&2
        fi

    elif [ "$RANGE" = "HIGHER" ] ; then

        if [ "$INDEX" = "CUBIC" ] ; then
            value=0
            value_err=0
        elif [ "$INDEX" = "SQUARE" ] ; then
            value=0
            value_err=0
        elif [ "$INDEX" = "LINER" ] ; then
            value=0
            value_err=0
        elif [ "$INDEX" = "CONSTANT" ] ; then
            value="$(echo "scale=10; ${b}*(${PH_BOUND_HIGHER}-${PH_BOUND_LOWER}) + ${c}" | bc | xargs printf "%0.10f")"
            value_err=0
        else
            echo "*** Warning" 1>&2
            echo "Calculation of the coefficient was skipped!" 1>&2
            echo "Details : \$1=$1, \$2=$2" 1>&2
        fi

    else
        echo "*** Warning" 1>&2
        echo "calc_coefficient" 1>&2
        echo "\$1 must be LOWER, MIDDLE or HIGHER" 1>&2
    fi

    # -- : Escape the character "-"
    printf -- "${value} ${value_err}"

}

for noise in ${noise_list[@]} ; do
for grade in ${grade_list[@]} ; do
        
    ### Files
    goffsetdatafile="${d_goffsetdata}/goffset_noise${noise}_G${grade}.dat"
    goffsetparamfile="${d_goffsetparams}/goffsetParam_noise${noise}_G${grade}.csv"

    ### Check files
    if [ ! -e $goffsetdatafile ] ; then
        echo "*** Warning" 1>&2
        echo "$goffsetdatafile does not exist!" 1>&2
        echo "continue..." 1>&2
        continue
    fi
    
    ### Fit
    gnuplotfit $goffsetdatafile $fitresultfile
    
    ### Save coefficient as csv file
    a=$(awk '$1=="a"{print $3}' ${fitresultfile})
    b=$(awk '$1=="b"{print $3}' ${fitresultfile})
    c=$(awk '$1=="c"{print $3}' ${fitresultfile})
    a_err=$(awk '$1=="a_err"{print $3}' ${fitresultfile})
    b_err=$(awk '$1=="b_err"{print $3}' ${fitresultfile})
    c_err=$(awk '$1=="c_err"{print $3}' ${fitresultfile})
    
    ### Check the results
    if [ -z "$a" ] || [ -z "$b" ] || [ -z "$c" ] || [ -z "$a_err" ] || [ -z "$b_err" ] || [ -z "$c_err" ] ; then
        echo "*** Warning" 1>&2
        echo "The results are anomalous!" 1>&2
        echo "a=$a, a_err=$a_err" 1>&2
        echo "b=$b, b_err=$b_err" 1>&2
        echo "c=$c, c_err=$c_err" 1>&2
        echo "continue..." 1>&2
        continue
    fi

    printf "LOW CUBI $(calc_coefficient LOWER CUBIC     $a $a_err $b $b_err $c $c_err)\n" >> $goffsetparamfile
    printf "LOW SQAR $(calc_coefficient LOWER SQUARE    $a $a_err $b $b_err $c $c_err)\n" >> $goffsetparamfile
    printf "LOW LINR $(calc_coefficient LOWER LINER     $a $a_err $b $b_err $c $c_err)\n" >> $goffsetparamfile
    printf "LOW CONS $(calc_coefficient LOWER CONSTANT  $a $a_err $b $b_err $c $c_err)\n" >> $goffsetparamfile

    printf "MID CUBI $(calc_coefficient MIDDLE CUBIC    $a $a_err $b $b_err $c $c_err)\n" >> $goffsetparamfile
    printf "MID SQAR $(calc_coefficient MIDDLE SQUARE   $a $a_err $b $b_err $c $c_err)\n" >> $goffsetparamfile
    printf "MID LINR $(calc_coefficient MIDDLE LINER    $a $a_err $b $b_err $c $c_err)\n" >> $goffsetparamfile
    printf "MID CONS $(calc_coefficient MIDDLE CONSTANT $a $a_err $b $b_err $c $c_err)\n" >> $goffsetparamfile

    printf "HIG CUBI $(calc_coefficient HIGHER CUBIC    $a $a_err $b $b_err $c $c_err)\n" >> $goffsetparamfile
    printf "HIG SQAR $(calc_coefficient HIGHER SQUARE   $a $a_err $b $b_err $c $c_err)\n" >> $goffsetparamfile
    printf "HIG LINR $(calc_coefficient HIGHER LINER    $a $a_err $b $b_err $c $c_err)\n" >> $goffsetparamfile
    printf "HIG CONS $(calc_coefficient HIGHER CONSTANT $a $a_err $b $b_err $c $c_err)\n" >> $goffsetparamfile

done
done

rm -f $fitresultfile

exit
