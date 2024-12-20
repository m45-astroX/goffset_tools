#!/bin/bash

# calcGoffsetParams_goffsetPG

# 2024.08.23 v1.0 by Yuma Aoki (Kindai Univ.)
# 2024.11.28 v2.0 by Yuma Aoki (Kindai Univ.)
#   - 補正関数を修正
#       これまでの補正関数は奈良教育大筆本卒論に基づいていたが、
#       xtdpilibの4113行目(heasoft6-34)に適合するように変更した。
#       モデルフィットで係数を共有しており、関数が不連続になることはない。

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
    f(x) = a * x**2 + b * x + c
    g(x) = b * x + c
    h(x) = c
    s(x) = x<306.5 ? f(x) : x<2000 ? g(x) : h(x)

    ### Fit
    fit s(x) "$goffsetdatafile_" using 1:2:3 via a,b,c

    ### Save variables
    save variables "$fitresultfile_"

    ### exit
    quit

____EOT

    rm -f 'fit.log'

}


for noise in ${noise_list[@]} ; do
for grade in ${grade_list[@]} ; do
        
    ### Files
    goffsetdatafile="${d_goffsetdata}/goffset_noise${noise}_G${grade}.dat"
    goffsetparamfile="${d_goffsetparams}/goffsetParam_noise${noise}_G${grade}.csv"

    ### Check files
    if [ ! -e $goffsetdatafile ] ; then
        echo "*** Warning"
        echo "$goffsetdatafile does not exist!"
        echo "continue..."
        continue
    fi
    
    ### Fit
    gnuplotfit $goffsetdatafile $fitresultfile
    
    ### Save coefficient as csv file
    echo "$(awk '$1=="a"{print $3}' ${fitresultfile}), $(awk '$1=="a_err"{print $3}' ${fitresultfile})" >> $goffsetparamfile
    echo "$(awk '$1=="b"{print $3}' ${fitresultfile}), $(awk '$1=="b_err"{print $3}' ${fitresultfile})" >> $goffsetparamfile
    echo "$(awk '$1=="c"{print $3}' ${fitresultfile}), $(awk '$1=="c_err"{print $3}' ${fitresultfile})" >> $goffsetparamfile

done
done

rm -f $fitresultfile

exit
