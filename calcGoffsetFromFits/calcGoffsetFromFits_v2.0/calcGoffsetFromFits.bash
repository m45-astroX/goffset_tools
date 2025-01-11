#!/bin/bash

# calcGoffsetFromFits

# 2024.08.02 v1.0 by Yuma Aoki (Kindai Univ.)
# 2024.08.30 v1.1 by Yuma Aoki (Kindai Univ.)
#   - Fittingに用いる関数を "CONS+GAUS" に変更
#   - log fileを残す仕様に変更
# 2024.09.30 v1.1.1 by Yuma Aoki (Kindai Univ.)
#   - 引数の説明文を修正
# 2024.09.30 v1.2 by Yuma Aoki (Kindai Univ.)
#   - Fitting時の画像をディレクトリに保存する仕様に変更
#   - Fitting時の画像をマージ
#   - logfileに書き込むPARAMSの内容を変更
#   - consgaussFitのバージョンを変更 (v1.0 --> v1.1)
# 2024.10.03 v1.3 by Yuma Aoki (Kindai Univ.)
#   - consgaussFitからpowgaussFitにスクリプトを変更
#     (モデル関数をPOWR+GAUSに変更)
#   - PHASSUMスペクトル作成スクリプトのバージョンを変更 (v1.0 --> v2.0)
#   - punlearnを追加
#   - フィットおよびbcコマンドが正常終了しているかを確認する仕様に変更
# 2024.10.03 v1.4 by Yuma Aoki (Kindai Univ.)
#   - モデル関数を以下の中から選択できる仕様に変更
#       - CONS + GAUS
#       - POWR + GAUS
# 2024.10.05 v1.5 by Yuma Aoki (Kindai Univ.)
#   - Goffsetエラー計算部分のバグを修正
# 2024.10.05 v1.6 by Yuma Aoki (Kindai Univ.)
#   - 引数の説明を修正
# 2024.12.16 v1.7 by Yuma Aoki (Kindai Univ.)
#   - 細かい修正
# 2024.12.16 v1.7 by Yuma Aoki (Kindai Univ.)
#   - powgaussFitのバージョン変更 (v1.0)
#   - consgaussFitのバージョン変更 (v1.1)
#   - 統計量を指定する仕様に変更

VERSION='2.0'
MAKE_WARNING_SKIP='0'

if [ $# != 5 ] && [ $# != 7 ] ; then
    echo "Usage : bash calcGoffsetFromFits.bash"
    echo "    \$1 evtfile : Xtend cleaned event file processed by xtdpipeline with usegoffset option 'no' and debugcol option 'yes'"
    echo "    \$2 MODEL (0:CONS+GAUS / 1:POWR+GAUS)"
    echo "    \$3 Statistic (Chi:Chi-Square / Ml:Maximum-likelihood)"
    echo "    \$4,\$5 PHA_MIN and PHA_MAX : The range of pha spectrum to be fitted"
    echo "    \$6,\$7 PHASSUM_MIN and PHASSUM_MAX : The range of phassum spectrum to be fitted"
    exit
elif [ $# = 5 ] ; then
    evtfile=$1
    model=$2
    statistic=$3
    PHA_MIN=$4
    PHA_MAX=$5
    PHASSUM_MIN=$PHA_MIN
    PHASSUM_MAX=$PHA_MAX
elif [ $# = 7 ] ; then
    evtfile=$1
    model=$2
    statistic=$3
    PHA_MIN=$4
    PHA_MAX=$5
    PHASSUM_MIN=$6
    PHASSUM_MAX=$7
fi

### Variables
UNIT='ch'
CCD_ID_list=( 0 1 2 3 )
SEGMENT_list=( 0 1 )
GRADE_list=( 0 2 3 4 6 )

### Files and directories
logfile="logfile_calcGoffsetFromFits_$(date '+%Y%m%d%H%M%S').log"
tmp_fitresult='tmpfile4calcGoffsetFromFits_1.tmp'
d_spec='obs_spec'
d_goffsetresults='obs_GoffsetResults'
d_fitresults='obs_fittingFigures'
f_error_tmp='tmpfile_errorReport_calcGoffsetFromFits.tmp'
f_error="errorReport_calcGoffsetFromFits_$(date '+%Y%m%d%H%M%S').log"

### Scripts
VERSION_MK_SPEC_PHA='1.0'
VERSION_MK_SPEC_PHASSUMGOOD='2.0'
VERSION_POWGAUSS_FIT='2.0'
VERSION_CONSGAUSS_FIT='2.0'
d_MK_SPEC_PHA="$(cd $(dirname $0) && pwd)/mkSpec_PHA_v${VERSION_MK_SPEC_PHA}"
MK_SPEC_PHA="${d_MK_SPEC_PHA}/mkSpec_PHA"
d_MK_SPEC_PHASSUMGOOD="$(cd $(dirname $0) && pwd)/mkSpec_PHASSUM_GOODGRADE_v${VERSION_MK_SPEC_PHASSUMGOOD}"
MK_SPEC_PHASSUMGOOD="${d_MK_SPEC_PHASSUMGOOD}/mkSpec_PHASSUM_GOODGRADE"
d_POWGAUSS_FIT="$(cd $(dirname $0) && pwd)/powgaussFit_v${VERSION_POWGAUSS_FIT}"
POWGAUSS_FIT="${d_POWGAUSS_FIT}/powgaussFit.bash"
d_CONSGAUSS_FIT="$(cd $(dirname $0) && pwd)/consgaussFit_v${VERSION_CONSGAUSS_FIT}"
CONSGAUSS_FIT="${d_CONSGAUSS_FIT}/consgaussFit.bash"

### Check files, model and directories
if [ ! -e $evtfile ] ; then
    echo "$evtfile does not exist!"
    exit
fi
if [ ! -e $POWGAUSS_FIT ] ; then
    echo "$(basename $POWGAUSS_FIT) does not exist!"
    exit
fi
if [ ! -e $CONSGAUSS_FIT ] ; then
    echo "$(basename $CONSGAUSS_FIT) does not exist!"
    exit
fi
if [ ! -e $d_MK_SPEC_PHA ] ; then
    echo "$(dirname $d_MK_SPEC_PHA) does not exist!"
    exit
fi
if [ ! -e $d_MK_SPEC_PHASSUMGOOD ] ; then
    echo "$(dirname $d_MK_SPEC_PHASSUMGOOD) does not exist!"
    exit
fi
if [ "$model" != 0 ] && [ "$model" != 1 ] ; then
    echo "*** Error"
    echo "model(\$2) must be 0 or 1!"
    echo "abort"
    exit
fi
if [ "$(echo $statistic | tr [A-Z] [a-z])" != 'chi' ] && [ "$(echo $statistic | tr [A-Z] [a-z])" != 'ml' ] ; then
    echo "*** Error"
    echo "statistic (\$3) must be Chi or Ml."
    echo "abort"
    exit
fi
if [ -e "$logfile" ] ; then
    rm -f $logfile
fi
if [ -e $f_error_tmp ] ; then
    rm -f $f_error_tmp
fi
if [ -e $f_error ] ; then
    rm -f $f_error
fi

### Create directories
if [ ! -e $d_spec ] ; then
    mkdir $d_spec
else
    rm -f $d_spec/*
fi
if [ ! -e $d_goffsetresults ] ; then
    mkdir $d_goffsetresults
else
    rm -f $d_goffsetresults/*
fi
if [ ! -e $d_fitresults ] ; then
    mkdir $d_fitresults
else
    rm -f $d_fitresults/*
fi

### Make executive files
## PHA spectrum creator
d_org=$(pwd)
echo "CMD : cd $d_MK_SPEC_PHA" ; cd $d_MK_SPEC_PHA 
echo "CMD : make clean"        ; make clean
echo "CMD : make"              ; make
status=$?
cd $d_org
if [ "$status" != 0 ] && [ "$MAKE_WARNING_SKIP" != 0 ] || [ ! -e "$MK_SPEC_PHA" ] ; then
    echo "*** Error"
    echo "Can not make $(basename $MK_SPEC_PHA)"
    echo "status = $status"
    exit
fi
## PHAS spectrum creator
d_org=$(pwd)
echo "CMD : cd $d_MK_SPEC_PHASSUMGOOD" ; cd $d_MK_SPEC_PHASSUMGOOD
echo "CMD : make clean"                ; make clean
echo "CMD : make"                      ; make
status=$?
cd $d_org
if [ "$status" != 0 ] && [ "$MAKE_WARNING_SKIP" != 0 ] || [ ! -e "$MK_SPEC_PHASSUMGOOD" ] ; then
    echo "*** Error"
    echo "Can not make $(basename $MK_SPEC_PHASSUMGOOD)"
    echo "status = $status"
    exit
fi

### punlearn
punlearn fselect

### Make logfile
printf "calcGoffsetFromFits\n\n" >> $logfile
printf "BEGIN PARAMS\n" >> $logfile
printf "\$1 evtfile     : $evtfile\n" >> $logfile
printf "\$2 model       : $model\n" >> $logfile
printf "\$3 statistic   : $statistic\n" >> $logfile
printf "\$4 PHA_MIN     : $PHA_MIN\n" >> $logfile
printf "\$5 PHA_MAX     : $PHA_MAX\n" >> $logfile
printf "\$6 PHASSUM_MIN : $PHASSUM_MIN\n" >> $logfile
printf "\$7 PHASSUM_MAX : $PHASSUM_MAX\n" >> $logfile
printf "END PARAMS\n\n" >> $logfile
printf "BEGIN INFO\n" >> $logfile
printf "CCD_ID_list  = $(echo ${CCD_ID_list[@]})\n" >> $logfile
printf "SEGMENT_list = $(echo ${SEGMENT_list[@]})\n" >> $logfile
printf "GRADE_list   = $(echo ${GRADE_list[@]})\n" >> $logfile
printf "END INFO\n\n" >> $logfile
printf "BEGIN SCRIPTS\n" >> $logfile
printf "VERSION_MK_SPEC_PHA = $VERSION_MK_SPEC_PHA\n" >> $logfile
printf "VERSION_MK_SPEC_PHASSUMGOOD = $VERSION_MK_SPEC_PHASSUMGOOD\n" >> $logfile
printf "VERSION_POWGAUSS_FIT = $VERSION_POWGAUSS_FIT\n" >> $logfile
printf "VERSION_CONSGAUSS_FIT = $VERSION_CONSGAUSS_FIT\n" >> $logfile
printf "END SCRIPTS\n" >> $logfile


### Select color
function color_select () {

    grade_=$1

    if [ "$grade_" = '-1' ] ; then
        echo '15'   # Light Grey
    elif [ "$grade_" = '0' ] ; then
        echo '1'    # Black
    elif [ "$grade_" = '2' ] ; then
        echo '8'    # Orange
    elif [ "$grade_" = '3' ] ; then
        echo '3'    # Green
    elif [ "$grade_" = '4' ] ; then
        echo '4'    # Blue
    elif [ "$grade_" = '6' ] ; then
        echo '2'    # Red
    else
        echo '1'    # Black
    fi

}


### Check status
function check_status () {
    
    status_=$1
    CCD_ID_=$2
    SEGMENT_=$3
    GRADE_=$4
    comment_=$5

    if [ "$status_" != 0 ] ; then
        echo "*** Warning"
        echo "Exit status was not zero (status=$status_)"
        echo "COMMENT = $comment_"
        echo "CCD_ID  = $CCD_ID_"
        echo "SEGMENT = $SEGMENT_"
        echo "GRADE   = $GRADE_"
        echo 
    fi

}

function check_errorfile () {
    
    CCD_ID_=$1
    SEGMENT_=$2
    GRADE_=$3
    comment_=$4

    if [ ! -z "$(cat $f_error_tmp)" ] ; then
        
        echo "*** Warning"
        echo "Error was reported"
        echo "COMMENT = $comment_"
        echo "CCD_ID  = $CCD_ID_"
        echo "SEGMENT = $SEGMENT_"
        echo "GRADE   = $GRADE_"
        echo ""

        echo "*** Warning"         >> $f_error
        echo "Error was reported"  >> $f_error
        echo "COMMENT = $comment_" >> $f_error
        echo "CCD_ID  = $CCD_ID_"  >> $f_error
        echo "SEGMENT = $SEGMENT_" >> $f_error
        echo "GRADE   = $GRADE_"   >> $f_error
        echo "Details"             >> $f_error
        cat $f_error_tmp           >> $f_error
        echo                       >> $f_error

    fi

    rm -f $f_error_tmp

}


### Make evtfiles and spectra
for CCD_ID in ${CCD_ID_list[@]} ; do
for SEGMENT in ${SEGMENT_list[@]} ; do

    ### Make evtfile for each segments
    outfile_evt_cs="$(basename $evtfile | sed 's/\.gz$//g; s/\..*$//g')_c${CCD_ID}s${SEGMENT}.evt"
    fselect "$evtfile" "$outfile_evt_cs" "CCD_ID==${CCD_ID} && SEGMENT==${SEGMENT}" clobber=yes
    check_status $? $CCD_ID $SEGMENT '02346' 'fselect'

    ### Make PHAS_SUM GoodGrade spectrum for each segments
    outfile_spec_PHASSUM="$(basename $evtfile | sed 's/\.gz$//g; s/\..*$//g')_c${CCD_ID}s${SEGMENT}_g02346_PHASSUM.spec"
    $MK_SPEC_PHASSUMGOOD $outfile_evt_cs $outfile_spec_PHASSUM

    ### Fit the spectrum
    color=$(color_select '-1')
    if [ "$model" = 0 ] ; then
        outfile_figure_ps_PHASSUM="fitResult_CONSGAUS_PHASSUM_GOODGRADE_c${CCD_ID}s${SEGMENT}.ps"
        $CONSGAUSS_FIT $outfile_spec_PHASSUM $PHASSUM_MIN $PHASSUM_MAX $statistic $color $outfile_figure_ps_PHASSUM 1> $tmp_fitresult 2> $f_error_tmp
        check_errorfile $CCD_ID $SEGMENT '02346' 'CONSGAUSS_FIT'
    elif [ "$model" = 1 ] ; then
        outfile_figure_ps_PHASSUM="fitResult_POWGAUS_PHASSUM_GOODGRADE_c${CCD_ID}s${SEGMENT}.ps"
        $POWGAUSS_FIT $outfile_spec_PHASSUM $PHASSUM_MIN $PHASSUM_MAX $statistic $color $outfile_figure_ps_PHASSUM 1> $tmp_fitresult 2> $f_error_tmp
        check_errorfile $CCD_ID $SEGMENT '02346' 'POWGAUSS_FIT'
    fi

    ### Read results
    if [ "$model" = 0 ] ; then
        GC_PHASSUM_GOODGRADE=$(cat $tmp_fitresult | awk 'NR==2 {print $1}' | sed 's/E/e/g')
        GC_PHASSUM_GOODGRADE_ERR=$(cat $tmp_fitresult | awk 'NR==2 {print $2}' | sed 's/E/e/g')
    elif [ "$model" = 1 ] ; then
        GC_PHASSUM_GOODGRADE=$(cat $tmp_fitresult | awk 'NR==3 {print $1}' | sed 's/E/e/g')
        GC_PHASSUM_GOODGRADE_ERR=$(cat $tmp_fitresult | awk 'NR==3 {print $2}' | sed 's/E/e/g')
    fi

    ### Merge spectrum figure
    if [ "$model" = 0 ] ; then
        merge_figure="${d_fitresults}/fitResult_CONSGAUS_merge_c${CCD_ID}s${SEGMENT}.ps"
    elif [ "$model" = 1 ] ; then
        merge_figure="${d_fitresults}/fitResult_POWGAUS_merge_c${CCD_ID}s${SEGMENT}.ps"
    fi
    cat $outfile_figure_ps_PHASSUM >> $merge_figure

    for GRADE in ${GRADE_list[@]} ; do
        
        ### Make evtfile for each grades
        outfile_evt_csg="$(basename $evtfile | sed 's/\.gz$//g; s/\..*$//g')_c${CCD_ID}s${SEGMENT}_g${GRADE}.evt"
        fselect "$outfile_evt_cs" "$outfile_evt_csg" "GRADE==${GRADE}" clobber=yes
        check_status $? $CCD_ID $SEGMENT $GRADE 'fselect'

        ### Make PHA spectrum for each grades
        outfile_spec_PHA="$(basename $evtfile | sed 's/\.gz$//g; s/\..*$//g')_c${CCD_ID}s${SEGMENT}_g${GRADE}_PHA.spec"
        $MK_SPEC_PHA $outfile_evt_csg $outfile_spec_PHA
        check_status $? $CCD_ID $SEGMENT $GRADE 'Make PHA spectrum'

        ### Gaussfit
        color=$(color_select $GRADE)
        if [ "$model" = 0 ] ; then
            outfile_figure_ps_PHA="fitResult_CONSGAUS_PHA_c${CCD_ID}s${SEGMENT}_grade${GRADE}.ps"
            $CONSGAUSS_FIT $outfile_spec_PHA $PHA_MIN $PHA_MAX $statistic $color $outfile_figure_ps_PHA 1> $tmp_fitresult 2> $f_error_tmp
            check_errorfile $CCD_ID $SEGMENT $GRADE 'CONSGAUSS_FIT'
        elif [ "$model" = 1 ] ; then
            outfile_figure_ps_PHA="fitResult_POWGAUS_PHA_c${CCD_ID}s${SEGMENT}_grade${GRADE}.ps"
            $POWGAUSS_FIT $outfile_spec_PHA $PHA_MIN $PHA_MAX $statistic $color $outfile_figure_ps_PHA 1> $tmp_fitresult 2> $f_error_tmp
            check_errorfile $CCD_ID $SEGMENT $GRADE 'POWGAUSS_FIT'
        fi

        ### Read results
        if [ "$model" = 0 ] ; then
            GC_PHA=$(cat $tmp_fitresult | awk 'NR==2 {print $1}' | sed 's/E/e/g')
            GC_PHA_ERR=$(cat $tmp_fitresult | awk 'NR==2 {print $2}' | sed 's/E/e/g')
        elif [ "$model" = 1 ] ; then
            GC_PHA=$(cat $tmp_fitresult | awk 'NR==3 {print $1}' | sed 's/E/e/g')
            GC_PHA_ERR=$(cat $tmp_fitresult | awk 'NR==3 {print $2}' | sed 's/E/e/g')
        fi

        ### Calculate goffset
        GOFFSET=$(echo "scale=10; ${GC_PHASSUM_GOODGRADE} - ${GC_PHA}" | bc 2> $f_error_tmp | xargs printf "%0.8f\n")
        check_errorfile $CCD_ID $SEGMENT $GRADE 'Calculate GOFFSET'

        GOFFSET_ERR=$(echo "scale=10; sqrt( (${GC_PHASSUM_GOODGRADE_ERR})^2 + (${GC_PHA_ERR})^2 )" | bc -l 2> $f_error_tmp | xargs printf "%0.8f\n")
        check_errorfile $CCD_ID $SEGMENT $GRADE 'Calculate GOFFSET_ERR'

        ### Print results
        file_result="goffsetResult_c${CCD_ID}s${SEGMENT}_g${GRADE}_${PHA_MIN}-${PHA_MAX}${UNIT}.dat"
        echo "${GC_PHASSUM_GOODGRADE} ${GC_PHASSUM_GOODGRADE_ERR} ${GC_PHA} ${GC_PHA_ERR} ${GOFFSET} ${GOFFSET_ERR}" > $file_result

        ### Merge spectrum figure
        cat $outfile_figure_ps_PHA >> $merge_figure

        ### Move files
        mv $outfile_spec_PHA $d_spec
        mv $file_result $d_goffsetresults
        mv $outfile_figure_ps_PHA $d_fitresults
        rm -f $outfile_evt_csg
        
    done

    ### Move and delete files
    mv $outfile_spec_PHASSUM $d_spec
    mv $outfile_figure_ps_PHASSUM $d_fitresults
    rm -f $outfile_evt_cs

done
done

### delete files
rm -f $tmp_fitresult

exit
