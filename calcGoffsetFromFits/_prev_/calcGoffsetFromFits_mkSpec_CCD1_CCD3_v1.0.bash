#!/bin/bash -f

# calcGoffsetFromFits
# yuma aoki

# 2023.02.02 (v1.0)


# args
if [ $# != 1 ] ; then
    printf "[evtFits]\n"
    exit
fi

# file
inputFile=$1
tmp1='TMP_calcGoffsetFromFits_1.tmp'
tmp2='TMP_calcGoffsetFromFits_2.tmp'
tmp3='TMP_calcGoffsetFromFits_3.tmp'

# directory
d_bin=$(cd $(dirname $0); pwd)
d_PHA='./org'
d_PHASSUM='./org_sum'

# source
c_mkSpec='mkSpec.c'
bin_mkSpec='bin_mkSpec'
b_gaussFit="${d_bin}/gaussFit_goffsetPG_for_calcGoffsetFromFits_v1.0/gaussFit_goffsetPG_for_calcGoffsetFromFits_v1.0.bash"

# list
CCDID_list=( 0 2 )
SEGMENT_list=( 0 1 )
SEGMENTNAME_list=( 'AB' 'CD' )
GRADE_list=( 0 2 3 4 6 )

if [ ! -e $inputFile ] ; then
    echo "${inputFile} does not exist.."
    exit
fi
if [ ! -e ${d_bin}/$c_mkSpec ] ; then
    echo "${c_mkSpec} does not exist.."
    exit
fi
if [ -e $tmp1 ] ; then
    rm -f $tmp1
fi
if [ -e $tmp2 ] ; then
    rm -f $tmp2
fi
if [ -e $tmp3 ] ; then
    rm -f $tmp3
fi
if [ -e $bin_mkSpec ] ; then
    rm -f $bin_mkSpec
fi
if [ -d $d_PHA ] ; then
    rm -rf $d_PHA
    mkdir -p $d_PHA/dat
else
    mkdir -p $d_PHA/dat
fi
if [ -d $d_PHASSUM ] ; then
    rm -rf $d_PHASSUM
    mkdir -p $d_PHASSUM/dat
else
    mkdir -p $d_PHASSUM/dat
fi

# compile
gcc -o $bin_mkSpec $d_bin/$c_mkSpec

# fits -> txt
fdump page=no prhead=no pagewidth=1024 outfile=STDOUT columns="CCD_ID, SEGMENT, GRADE, PHA, PHAS" rows=- $inputFile | awk 'NF==6 {print $2, $3, $4, $5, $6} NF==1 {print $1}' > $tmp1

# make spec
for CCDID in ${CCDID_list[@]} ; do
    
    CCDNAME=$(echo "${CCDID}+1" | bc)
    
    for SEGMENT in ${SEGMENT_list[@]} ; do
        
        SEGMENTNAME=${SEGMENTNAME_list[${SEGMENT}]}
        
        for grade in ${GRADE_list[@]} ; do
            
            # file
            f_PHA_spec="${d_PHA}/dat/CCD${CCDNAME}${SEGMENTNAME}_G${grade}_PHA_spec.dat"
            f_PHASSUM_spec="${d_PHASSUM}/dat/CCD${CCDNAME}${SEGMENTNAME}_G${grade}_PHASSUM_spec.dat"
            
            if [ -e $tmp2 ] ; then
                rm -f $tmp2
            fi
            if [ -e $tmp3 ] ; then
                rm -f $tmp3
            fi
            if [ -e $f_PHA_spec ] ; then
                rm -f $f_PHA_spec
            fi
            if [ -e $f_PHASSUM_spec ] ; then
                rm -f $f_PHASSUM_spec
            fi
            
            # make PHA data
            awk -v CCDID_req=$CCDID -v SEGMENT_req=$SEGMENT -v grade_req=$grade '(NR+8)%9==0 && $1==CCDID_req && $2==SEGMENT_req && $3==grade_req {print $4}' $tmp1 > $tmp2
            
            # make PHAS_SUM data
            awk -v CCDID_req=$CCDID -v SEGMENT_req=$SEGMENT -v grade_req=$grade 'BEGIN {flag=0} NF==5 {if ($1==CCDID_req && $2==SEGMENT_req && $3==grade_req) {flag=1} else {flag=0}} flag==1 {print}' $tmp1 | awk 'NF==5 {print $5} NF==1 {print $1}' | awk 'BEGIN {PHAS_SUM=0} {PHAS_SUM+=$1} NR%9==0 {print PHAS_SUM; PHAS_SUM=0}' > $tmp3
            
            # make spectra
            ./$bin_mkSpec $tmp2 $f_PHA_spec
            ./$bin_mkSpec $tmp3 $f_PHASSUM_spec
            
        done
        
    done
    
done

rm -f $tmp1
rm -f $tmp2
rm -f $tmp3
rm -f $bin_mkSpec

exit
