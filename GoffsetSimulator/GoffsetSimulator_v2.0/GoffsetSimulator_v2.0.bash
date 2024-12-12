#!/bin/bash

# GoffsetSimulator

# 2024.08.23 v1.0 by Yuma Aoki (Kindai Univ.)
# 2024.12.12 v2.0 by Yuma Aoki (Kindai Univ.)


sigma='0.11'
trial='100000'
noise_list=( $(seq 4.0 0.1 8.0 | xargs printf "%.1f ") )
PHA0_list=( 100 120 140 160 180 200 220 240 260 280 300 350 400 450 500 600 700 800 900 1000 )

VERSION='1.0'
VERSION_MAKEDATA='1.0'
VERSION_GAUSSFIT='1.0'
VERSION_CALCGOFFSETVAL='1.0'
VERSION_CALCGOFFSETPAR='2.0'

SCRIPT_MAKEDATA="$(cd $(dirname $0) && pwd)/mkSpecData4GoffsetPG_v${VERSION_MAKEDATA}/mkSpecData4GoffsetPG_v${VERSION_MAKEDATA}.bash"
SCRIPT_GAUSSFIT="$(cd $(dirname $0) && pwd)/mkFitData4GoffsetPG_v${VERSION_GAUSSFIT}/mkFitData4GoffsetPG_v${VERSION_GAUSSFIT}.bash"
SCRIPT_CALCGOFFSETVAL="$(cd $(dirname $0) && pwd)/calcGoffset_goffsetPG_v${VERSION_CALCGOFFSETVAL}/calcGoffset_goffsetPG_PHASSUM-PHA_v${VERSION_CALCGOFFSETVAL}.bash"
SCRIPT_CALCGOFFSETPAR="$(cd $(dirname $0) && pwd)/calcGoffsetParams_goffsetPG_v${VERSION_CALCGOFFSETPAR}/calcGoffsetParams_goffsetPG_v${VERSION_CALCGOFFSETPAR}.bash"

### Directories
d_specdata='sim_specdata'
d_fitdata='sim_fitdata'
d_goffsetdata='sim_goffsetData'

### Make Data
bash $SCRIPT_MAKEDATA $sigma $trial "$(echo ${noise_list[@]})" "$(echo ${PHA0_list[@]})"

### Gauss fitting
bash $SCRIPT_GAUSSFIT $d_specdata "$(echo ${noise_list[@]})" "$(echo ${PHA0_list[@]})"

### Calculate Goffset values
bash $SCRIPT_CALCGOFFSETVAL $d_fitdata "$(echo ${noise_list[@]})" "$(echo ${PHA0_list[@]})"

### Calculate Goffset parameters
bash $SCRIPT_CALCGOFFSETPAR $d_goffsetdata "$(echo ${noise_list[@]})"

exit
