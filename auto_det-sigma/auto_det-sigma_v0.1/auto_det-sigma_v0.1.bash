#!/bin/bash -f

# 2022.05.02

# yuma a


# args
if [ $# != 4 ] ; then
    printf "[PHA0(ch)] [noise(ch)] [GBR file(realData)] [outputFile]\n"
    exit
fi

# var
PHA0=$1
noise=$2
trial=100000

sigma_start=0.06
sigma_max=0.18
delta_sigma=0.01

# file
f_real_GBR=$3
f_eventFile='Event_cor.dat'
c_simulate='FakeData_Goffset_PlusNoise_v0.10'
c_calcChiSq='calcChiSq_v0.1'
outputFile=$4

# check files
if [ ! -e ${c_simulate}.c ] ; then
    printf "${c_simulate}.c does not exist\n"
    exit
fi
if [ ! -e ${c_calcChiSq}.c ] ; then
    printf "${c_calcChiSq} does not exist\n"
    exit
fi
if [ -e $outputFile ] ; then
    printf "${outputFile} exists\n"
    exit
else
    printf "!sigma, chiSq\n" >> $outputFile
fi

# compile
gcc -o ${c_simulate} ${c_simulate}.c
gcc -o ${c_calcChiSq} ${c_calcChiSq}.c

# sigma loop
for sigma in $(seq $sigma_start $delta_sigma $sigma_max | awk '{printf "%.2f\n", $1}') ; do
    
    # simulation (PHA0, sigma, noise, trial)
    ./${c_simulate} $PHA0 $sigma $noise $trial
    
    # calc chi-SQ (Event file, GBR file)
    chiSq=$(./${c_calcChiSq} $f_eventFile $f_real_GBR)
    
    # print result
    printf "$sigma $chiSq\n" >> $outputFile
    
    # remove files
    rm -f Event_org.dat
    rm -f Event_cor.dat
    rm -f Spectrum_org.dat
    rm -f Spectrum_cor.dat
    rm -f Spectrum_PhasSum_org.dat
    rm -f Spectrum_PhasSum_cor.dat
    
done

# remove files
rm -f $c_simulate
rm -f ${c_calcChiSq}

exit
