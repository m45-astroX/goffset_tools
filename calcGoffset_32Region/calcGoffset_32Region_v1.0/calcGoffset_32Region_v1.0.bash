#!/bin/bash -f

# 2023.12.15 v1.0 by Yuma Aoki


if [ $# -ne 1 ] ; then
    echo "Usage : bash calcGoffset_32Region_v1.0.bash infile(evtfits)"
    exit
fi

infile=$1
datadir="./Goffset_32Region_data"

if [ -d $datadir ] ; then
    echo "rm -f $datadir/*"
    rm -f $datadir/*
else
    echo "mkdir $datadir"
    mkdir $datadir
fi

# fits2alpha
fits2alpha="/Users/aoki/git/sxi_tools/fits2alpha/fits2alpha_v1.0/fitsToAlpha_v1.0.bash"
# alpha2spec (binary)
alpha2spec="/Users/aoki/git/sxi_tools/alpha2spec/alpha2spec_v2.0/alpha2spec"
# gaussfit
gaussfit="/Users/aoki/git/sxi_tools/gaussFit/gaussFit_v2.1/gaussFit_v2.1.bash"

# ResultFile
file_result="${datadir}/Goffset_32Region_Result.dat"

# Grade0, 6のイベント抽出
tmp_evtfits_G0="${datadir}/evtdata_extract_G0.fits"
tmp_evtfits_G6="${datadir}/evtdata_extract_G6.fits"
fselect $infile $tmp_evtfits_G0 "GRADE==0"
fselect $infile $tmp_evtfits_G6 "GRADE==6"

# 32領域に分割してGoffset計算
for NX in $(seq 0 3) ; do
for NY in $(seq 0 7) ; do

    tmp_evtfits_G0_REGFILTER="${datadir}/evtdata_REG_NX-${NX}_NY-${NY}_G0.fits"
    tmp_evtfits_G6_REGFILTER="${datadir}/evtdata_REG_NX-${NX}_NY-${NY}_G6.fits"
    tmp_alphafile_G0="${datadir}/alphafile_REG_NX-${NX}_NY-${NY}_G0.dat"
    tmp_alphafile_G6="${datadir}/alphafile_REG_NX-${NX}_NY-${NY}_G6.dat"
    tmp_specfile_G0="${datadir}/specfile_REG_NX-${NX}_NY-${NY}_G0.dat"
    tmp_specfile_G6="${datadir}/specfile_REG_NX-${NX}_NY-${NY}_G6.dat"

    X_min=$(echo "${NX}*80" | bc)
    X_max=$(echo "80+${NX}*80" | bc)
    Y_min=$(echo "${NY}*80" | bc)
    Y_max=$(echo "80+${NY}*80" | bc)

    # extract events from evtfits
    fselect $tmp_evtfits_G0 $tmp_evtfits_G0_REGFILTER "${X_min} <= RAWX && RAWX < ${X_max} && ${Y_min} <= RAWY && RAWY < ${Y_max}"
    fselect $tmp_evtfits_G6 $tmp_evtfits_G6_REGFILTER "${X_min} <= RAWX && RAWX < ${X_max} && ${Y_min} <= RAWY && RAWY < ${Y_max}"

    # fits -> alpha
    bash $fits2alpha $tmp_evtfits_G0_REGFILTER $tmp_alphafile_G0
    bash $fits2alpha $tmp_evtfits_G6_REGFILTER $tmp_alphafile_G6

    # alpha -> spec
    $alpha2spec $tmp_alphafile_G0 $tmp_specfile_G0
    $alpha2spec $tmp_alphafile_G6 $tmp_specfile_G6

    # gausfit
    G0_GC=$(bash $gaussfit $tmp_specfile_G0 | awk 'NR==1{print $1}')
    G6_GC=$(bash $gaussfit $tmp_specfile_G6 | awk 'NR==1{print $1}')

    # calc Goffset
    GOFFSET=$(echo "${G0_GC} ${G6_GC}" | awk '{printf "%0.6f\n", $2-$1}')

    # print Result (display)
    echo "$X_min <= RAWX <= $X_max"
    echo "$Y_min <= RAWY <= $Y_max"
    echo "Goffset = $GOFFSET"
    echo ""

    # print Result (file)
    echo "${NX} ${NY} ${GOFFSET}" >> $file_result

done
    
done
