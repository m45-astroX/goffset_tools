#!/bin/bash -f

# calcGoffsetFromFits
# yuma aoki

# 2023.01.19 (v1.0)


# args
if [ $# != 1 ] ; then
    printf "[evtFits]\n"
    exit
fi

# how to calculate Goffset (sum/g6)
goffsetMode='g6'

# file
inputFile=$1
tmp1='TMP_calcGoffsetFromFits_1.tmp'
tmp2='TMP_calcGoffsetFromFits_2.tmp'
tmp3='TMP_calcGoffsetFromFits_3.tmp'

d_bin=$(cd $(dirname $0); pwd)
d_PHA='./org'
d_PHASSUM='./org_sum'
d_goffset='./goffset/goffsetResult'

# source
c_mkSpec='mkSpec.c'
bin_mkSpec='bin_mkSpec'
b_gaussFit="${d_bin}/gaussFit_goffsetPG_for_calcGoffsetFromFits_v1.0/gaussFit_goffsetPG_for_calcGoffsetFromFits_v1.0.bash"

# list
CCDID_list=( 0 1 2 3 )
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
if [ -d $d_goffset ] ; then
    rm -rf $d_goffset
    mkdir -p $d_goffset
else
    mkdir -p $d_goffset
fi

# compile
gcc -o $bin_mkSpec $d_bin/$c_mkSpec

# fits -> txt
fdump page=no prhead=no pagewidth=1024 outfile=STDOUT columns="CCD_ID, SEGMENT, GRADE, PHA, PHAS" rows=-100000 $inputFile | awk 'NF==6 {print $2, $3, $4, $5, $6} NF==1 {print $1}' > $tmp1

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

echo fitting

# fitting
for phType in 'org' 'org_sum' ; do
    
    cd $phType
    
    if [ $phType = 'org' ] ; then
        mkdir fittingResult_PHA
    elif [ $phType = 'org_sum' ] ; then
        mkdir fittingResult_PHASSUM
    fi
    
    for CCDID in ${CCDID_list[@]} ; do
        
        CCDNAME=$(echo "${CCDID}+1" | bc)
        
        for SEGMENT in ${SEGMENT_list[@]} ; do
            
            SEGMENTNAME=${SEGMENTNAME_list[${SEGMENT}]}
            
            for grade in ${GRADE_list[@]} ; do
                
                # infile
                f_PHA_spec="./dat/CCD${CCDNAME}${SEGMENTNAME}_G${grade}_PHA_spec.dat"
                f_PHASSUM_spec="./dat/CCD${CCDNAME}${SEGMENTNAME}_G${grade}_PHASSUM_spec.dat"
                
                # outfile
                f_fit_PHA="./fittingResult_PHA/fitData_CCD${CCDNAME}${SEGMENTNAME}_G${grade}_PHA.dat"
                f_fit_PHASSUM="./fittingResult_PHASSUM/fitData_CCD${CCDNAME}${SEGMENTNAME}_G${grade}_PHASSUM.dat"
                
                # fit
                if [ $phType = 'org' ] ; then
                    bash $b_gaussFit $f_PHA_spec $f_fit_PHA
                elif [ $phType = 'org_sum' ] ; then
                    bash $b_gaussFit $f_PHASSUM_spec $f_fit_PHASSUM
                fi
                
            done
        
        done
        
    done
    
    cd ../

done

echo marge goodGrade spec

# marge goodGrade spec
for phType in 'org' 'org_sum' ; do
    
    cd $phType
    
    for CCDID in ${CCDID_list[@]} ; do
        
        CCDNAME=$(echo "${CCDID}+1" | bc)
        
        for SEGMENT in ${SEGMENT_list[@]} ; do
            
            SEGMENTNAME=${SEGMENTNAME_list[${SEGMENT}]}
            
            # file
            f_good_PHA_master="./fittingResult_PHA/fitData_CCD${CCDNAME}${SEGMENTNAME}_GoodGrade_PHA.dat"
            f_good_PHASSUM_master="./fittingResult_PHASSUM/fitData_CCD${CCDNAME}${SEGMENTNAME}_GoodGrade_PHASSUM.dat"
            
            # make master spec file
            for i in $(seq 0 4095) ; do
                
                if [ $phType = 'org' ] ; then
                    echo "${i} 0" >> $f_good_PHA_master
                elif [ $phType = 'org_sum' ] ; then
                    echo "${i} 0" >> $f_good_PHASSUM_master
                fi
            
            done
            
            # marge spec
            for grade in ${GRADE_list[@]} ; do
                
                if [ $phType = 'org' ] ; then
                    
                    # infile
                    f_good_PHA="./fittingResult_PHA/fitData_CCD${CCDNAME}${SEGMENTNAME}_G${grade}_PHA.dat"
                    # marge
                    bash ${d_bin}/margeSpec_v2.0/margeSpec_v2.0.bash "$f_good_PHA" "$f_good_PHA_master"
                    
                elif [ $phType = 'org_sum' ] ; then
                    
                    # skip bad grade
                    if [ $grade -ne 0 ] && [ $grade -ne 2 ] && [ $grade -ne 3 ] && [ $grade -ne 4 ] && [ $grade -ne 6 ] ; then
                        continue
                    fi
                    
                    # infile
                    f_good_PHASSUM="./fittingResult_PHASSUM/fitData_CCD${CCDNAME}${SEGMENTNAME}_G${grade}_PHASSUM.dat"
                    # marge
                    bash ${d_bin}/margeSpec_v2.0/margeSpec_v2.0.bash "$f_good_PHASSUM" "$f_good_PHASSUM_master"
                    
                fi
                
                
            done
        
        done

    done
    
    cd ../

done

echo calc Goffset

# calc Goffset
for CCDID in ${CCDID_list[@]} ; do
    
    CCDNAME=$(echo "${CCDID}+1" | bc)
    
    for SEGMENT in ${SEGMENT_list[@]} ; do
        
        SEGMENTNAME=${SEGMENTNAME_list[${SEGMENT}]}
        
        for grade in ${GRADE_list[@]} ; do
            
            # file
            f_fit="./org/fittingResult_PHA/fitData_CCD${CCDNAME}${SEGMENTNAME}_G${grade}_PHA.dat"
            f_fit_G6="./org/fittingResult_PHA/fitData_CCD${CCDNAME}${SEGMENTNAME}_G6_PHA.dat"
            f_sum_fit="./org_sum/fittingResult_PHASSUM/fitData_CCD${CCDNAME}${SEGMENTNAME}_G${grade}_PHASSUM.dat"
            
            # check file
            if [ ! -e $f_fit ] ; then
                echo "${f_fit} does not exist"
                continue
            fi
            if [ ! -e $f_fit_G6 ] ; then
                echo "${f_fit_G6} does not exist"
                continue
            fi
            if [ ! -e $f_sum_fit ] ; then
                echo "${f_sum_fit} does not exist"
                continue
            fi
            
            # input val
            PHAS_SUM=$(awk '{printf "%5.6f", $1}' $f_sum_fit)
            PHA=$(awk '{printf "%5.6f", $1}' $f_fit)
            PHA_G6=$(awk '{printf "%5.6f", $1}' $f_fit_G6)
            
            # calc goffset
            if [ $goffsetMode = 'sum' ] ; then
                goffset=$(echo "scale=20; ${PHAS_SUM} - ${PHA}" | bc | xargs -n1 printf "%.10f")
            elif [ $goffsetMode = 'g6' ] ; then
                goffset=$(echo "scale=20; ${PHA_G6} - ${PHA}" | bc | xargs -n1 printf "%.10f")
            fi
            
            # output File
            outputFile="goffset_CCD${CCDNAME}${SEGMENTNAME}_grade${grade}.dat"
            
            # output
            echo "${PHA} ${goffset}" >> ${d_goffset}/${outputFile}
            
        done
        
    done
    
done

# rm
rm -f $tmp1
rm -f $tmp2
rm -f $tmp3
rm -f $bin_mkSpec

exit
