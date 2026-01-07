#!/bin/bash -f

# make GoodGrade spec
# PHA, PHAS_SUM
# yuma aoki

# 2023.02.02 (v1.0)


# args
if [ $# != 1 ] ; then
    printf "[evtFits]\n"
    exit
fi

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

exit
