#!/bin/bash -f

# marge spec
# yuma aoki

# 2023.01.19 (v1.0)

if [ ! -d 'org' ] && [ ! -d 'org_sum' ] ; then
    echo "org or org_sum not found..."
    exit
done

d_bin=$(cd $(dirname $0); pwd)

# list
CCDID_list=( 0 1 2 3 )
SEGMENT_list=( 0 1 )
SEGMENTNAME_list=( 'AB' 'CD' )
GRADE_list=( 0 2 3 4 6 )

# marge goodGrade spec
for phType in 'org' 'org_sum' ; do
    
    cd $phType/dat
    
    for CCDID in ${CCDID_list[@]} ; do

        CCDNAME=$(echo "${CCDID}+1" | bc)

        for SEGMENT in ${SEGMENT_list[@]} ; do
            
            SEGMENTNAME=${SEGMENTNAME_list[${SEGMENT}]}
            
            # file
            f_good_PHA_master="CCD${CCDNAME}${SEGMENTNAME}_GoodGrade_PHA_spec.dat"
            f_good_PHASSUM_master="CCD${CCDNAME}${SEGMENTNAME}_GoodGrade_PHA_spec.dat"
            
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
                    
                    # skip bad grade
                    if [ $grade -ne 0 ] && [ $grade -ne 2 ] && [ $grade -ne 3 ] && [ $grade -ne 4 ] && [ $grade -ne 6 ] ; then
                        continue
                    fi
                    
                    # infile
                    f_good_PHA=""
                    # marge
                    bash ${d_bin}/margeSpec_v2.0/margeSpec_v2.0.bash "$f_good_PHA" "$f_good_PHA_master"
                    
                elif [ $phType = 'org_sum' ] ; then
                    
                    # skip bad grade
                    if [ $grade -ne 0 ] && [ $grade -ne 2 ] && [ $grade -ne 3 ] && [ $grade -ne 4 ] && [ $grade -ne 6 ] ; then
                        continue
                    fi
                    
                    # infile
                    f_good_PHASSUM=""
                    # marge
                    bash ${d_bin}/margeSpec_v2.0/margeSpec_v2.0.bash "$f_good_PHASSUM" "$f_good_PHASSUM_master"
                    
                fi
                
                
            done
        
        done

    done
    
    cd ../../

done


exit
