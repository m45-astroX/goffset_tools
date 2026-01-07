#!/bin/bash

# mkGoffsetPlot_goffsetReport

# 2024.08.25 v1.0 by Yuma Aoki (Kindai Univ.)


VERSION='1.0'

if [ $# != 3 ] ; then
    echo "Usage : bash mkGoffsetPlot_goffsetReport_v${VERSION}.bash"
    echo "    \$1 : simulated goffsetData file"
    echo "            Format (Separated by space)"
    echo "            PHA Goffset Goffset_error"
    echo "    \$2 : Observed goffsetData file"
    echo "            Format (Separated by space)"
    echo "            PHASSUM PHASSUM_error PHA PHA_error Goffset Goffset_error"
    echo "    \$3 : Grade"
    exit
fi

### Arguments
file_sim_goffset=$1
file_obs_goffset=$2
grade=$3


function makeGraph () {

    infile_=$1
    grade_=$2

    qdp $infile_ << ____EOT
    /null
    la x PHA[G${grade_}] (ch)
    la y
     
    quit
____EOT

}


