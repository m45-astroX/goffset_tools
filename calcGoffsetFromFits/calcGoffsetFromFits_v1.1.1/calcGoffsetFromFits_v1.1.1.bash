#!/bin/bash

# calcGoffsetFromFits

# 2024.08.02 v1.0 by Yuma Aoki (Kindai Univ.)
# 2024.08.30 v1.1 by Yuma Aoki (Kindai Univ.)
#   - Fittingに用いる関数を "CONS+GAUS" に変更
#   - log fileを残す仕様に変更
# 2024.09.30 v1.1.1 by Yuma Aoki (Kindai Univ.)
#   - 引数の説明文を修正


VERSION='1.1.1'

if [ $# != 3 ] ; then
    echo "Usage : bash calcGoffsetFromFits_v${VERSION}.bash evtfile PHA_MIN PHA_MAX (PHASSUM_MIN; optional) (PHASSUM_MAX; optional)"
    echo "    evtfile : Xtend cleaned event file processed by xtdpipeline with usegoffset option 'no' and debugcol option 'yes'"
    echo "    PHA_MIN and PHA_MAX : The range of pha spectrum to be fitted"
    echo "    PHASSUM_MIN and PHASSUM_MAX : The range of phassum spectrum to be fitted"
    exit
elif [ $# = 3 ] ; then
    evtfile=$1
    PHA_MIN=$2
    PHA_MAX=$3
    PHASSUM_MIN=$PHA_MIN
    PHASSUM_MAX=$PHA_MAX
elif [ $# = 5 ] ; then
    evtfile=$1
    PHA_MIN=$2
    PHA_MAX=$3
    PHASSUM_MIN=$4
    PHASSUM_MAX=$5
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

### Scripts
VERSION_MK_SPEC_PHA='1.0'
VERSION_MK_SPEC_PHASSUMGOOD='1.0'
VERSION_CONSGAUSS_FIT='1.0'
MK_SPEC_PHA="$(cd $(dirname $0) && pwd)/mkSpec_PHA_v${VERSION_MK_SPEC_PHA}/mkSpec_PHA"
MK_SPEC_PHASSUMGOOD="$(cd $(dirname $0) && pwd)/mkSpec_PHASSUM_GOODGRADE_v${VERSION_MK_SPEC_PHASSUMGOOD}/mkSpec_PHASSUM_GOODGRADE"
CONSGAUSS_FIT="$(cd $(dirname $0) && pwd)/consgaussFit_v${VERSION_CONSGAUSS_FIT}/consgaussFit_v${VERSION_CONSGAUSS_FIT}.bash"


### Check files and directories
if [ -e "$logfile" ] ; then
    rm -f $logfile
fi
if [ ! -e $evtfile ] ; then
    echo "$evtfile does not exist!"
    exit
fi
if [ ! -e $MK_SPEC_PHA ] ; then
    echo "$(basename $MK_SPEC_PHA) does not exist!"
    exit
fi
if [ ! -e $MK_SPEC_PHASSUMGOOD ] ; then
    echo "$(basename $MK_SPEC_PHASSUMGOOD) does not exist!"
    exit
fi
if [ ! -e $CONSGAUSS_FIT ] ; then
    echo "$(basename $CONSGAUSS_FIT) does not exist!"
    exit
fi
if [ ! -e $d_spec ] ; then
    mkdir $d_spec
fi
if [ ! -e $d_goffsetresults ] ; then
    mkdir $d_goffsetresults
fi


### Make logfile
printf "calcGoffsetFromFits\n\n" >> $logfile
printf "BEGIN PARAMS\n" >> $logfile
printf "    \$1 evtfile : $evtfile\n" >> $logfile
printf "    \$2 PHA_MIN : $PHA_MIN\n" >> $logfile
printf "    \$3 PHA_MAX : $PHA_MAX\n" >> $logfile
printf "    \$4 PHASSUM_MIN : $PHASSUM_MIN\n" >> $logfile
printf "    \$5 PHASSUM_MAX : $PHASSUM_MAX\n" >> $logfile
printf "END PARAMS\n\n" >> $logfile
printf "BEGIN INFO\n" >> $logfile
printf "CCD_ID_list  = ${CCD_ID_list[@]}\n" >> $logfile
printf "SEGMENT_list = ${SEGMENT_list[@]}\n" >> $logfile
printf "GRADE_list   = ${GRADE_list[@]}\n" >> $logfile
printf "\n" >> $logfile
printf "END INFO\n\n" >> $logfile
printf "BEGIN SCRIPTS\n" >> $logfile
printf "VERSION_MK_SPEC_PHA = $VERSION_MK_SPEC_PHA\n" >> $logfile
printf "VERSION_MK_SPEC_PHASSUMGOOD = $VERSION_MK_SPEC_PHASSUMGOOD\n" >> $logfile
printf "VERSION_CONSGAUSS_FIT = $VERSION_CONSGAUSS_FIT\n" >> $logfile
printf "END SCRIPTS\n" >> $logfile

### Make evtfiles and spectra
for CCD_ID in ${CCD_ID_list[@]} ; do
for SEGMENT in ${SEGMENT_list[@]} ; do

    ### Make evtfile for each segments
    outfile_evt_cs="$(basename $evtfile | sed 's/\.gz$//g; s/\..*$//g')_c${CCD_ID}s${SEGMENT}.evt"
    fselect "$evtfile" "$outfile_evt_cs" "CCD_ID==${CCD_ID} && SEGMENT==${SEGMENT}" clobber=yes

    ### Make PHAS_SUM GoodGrade spectrum for each segments
    outfile_spec_PHASSUM="$(basename $evtfile | sed 's/\.gz$//g; s/\..*$//g')_c${CCD_ID}s${SEGMENT}_g02346_PHASSUM.spec"
    $MK_SPEC_PHASSUMGOOD $outfile_evt_cs $outfile_spec_PHASSUM

    ### Gaussfit
    outfile_figure_ps_PHASSUM="fitResult_CONSGAUS_PHASSUM_GOODGRADE_c${CCD_ID}s${SEGMENT}.ps"
    $CONSGAUSS_FIT $outfile_spec_PHASSUM $PHASSUM_MIN $PHASSUM_MAX $outfile_figure_ps_PHASSUM > $tmp_fitresult
    GC_PHASSUM_GOODGRADE=$(cat $tmp_fitresult | awk 'NR==2 {print $1}')
    GC_PHASSUM_GOODGRADE_ERR=$(cat $tmp_fitresult | awk 'NR==2 {print $2}')

    for GRADE in ${GRADE_list[@]} ; do
        
        ### Make evtfile for each grades
        outfile_evt_csg="$(basename $evtfile | sed 's/\.gz$//g; s/\..*$//g')_c${CCD_ID}s${SEGMENT}_g${GRADE}.evt"
        fselect "$outfile_evt_cs" "$outfile_evt_csg" "GRADE==${GRADE}" clobber=yes

        ### Make PHA spectrum for each grades
        outfile_spec_PHA="$(basename $evtfile | sed 's/\.gz$//g; s/\..*$//g')_c${CCD_ID}s${SEGMENT}_g${GRADE}_PHA.spec"
        $MK_SPEC_PHA $outfile_evt_csg $outfile_spec_PHA

        ### Gaussfit
        outfile_figure_ps_PHA="fitResult_CONSGAUS_PHA_c${CCD_ID}s${SEGMENT}_grade${GRADE}.ps"
        $CONSGAUSS_FIT $outfile_spec_PHA $PHA_MIN $PHA_MAX $outfile_figure_ps_PHA > $tmp_fitresult
        GC_PHA=$(cat $tmp_fitresult | awk 'NR==2 {print $1}')
        GC_PHA_ERR=$(cat $tmp_fitresult | awk 'NR==2 {print $2}')

        ### Calculate goffset
        GOFFSET=$(echo "scale=10; ${GC_PHASSUM_GOODGRADE} - ${GC_PHA}" | bc | xargs printf "%0.8f\n")
        GOFFSET_ERR=$(echo "scale=10; sqrt( (${GC_PHASSUM_GOODGRADE_ERR})^2 + (${GC_PHA_ERR})^2 )" | bc | xargs printf "%0.6f\n")

        ### Print results
        file_result="goffsetResult_c${CCD_ID}s${SEGMENT}_g${GRADE}_${PHA_MIN}-${PHA_MAX}${UNIT}.dat"
        echo "${GC_PHASSUM_GOODGRADE} ${GC_PHASSUM_GOODGRADE_ERR} ${GC_PHA} ${GC_PHA_ERR} ${GOFFSET} ${GOFFSET_ERR}" > $file_result

        ### Move files
        rm -f $outfile_evt_csg
        mv $outfile_spec_PHA $d_spec
        mv $file_result $d_goffsetresults
        
    done

    ### Move and delete files
    mv $outfile_spec_PHASSUM $d_spec
    rm -f $outfile_evt_cs

done
done

### delete files
rm -f $tmp_fitresult

exit
