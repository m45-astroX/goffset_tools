#!/bin/bash -f

# 2022.04.09

# yuma a


# args
if [ $# != 4 ] ; then
    echo "[inputFile] [Grade] [y min] [y max]"
    exit
fi

# input args
inputFile=$1
grade=$2
y_min=$3
y_max=$4

# check args
if [ ! -e $inputFile ] ; then
    echo "${inputFile} does not exist"
    exit
fi

# var
f_pdf='FIT_Graph.pdf'
f_fitData='FIT_Result.dat'

# plot
if [ "$grade" -eq "0" ] ; then
    c_plot="plot \"${inputFile}\" title \"data\" with points ps 0.8 pt 7 lc 'blue', s(x) title \"fit\" lw 2 lc 'black'"
elif [ "$grade" -eq "2" ] ; then
    c_plot="plot \"${inputFile}\" title \"data\" with points ps 0.8 pt 7 lc 'orange', s(x) title \"fit\" lw 2 lc 'black'"
elif [ "$grade" -eq "3" ] ; then
    c_plot="plot \"${inputFile}\" title \"data\" with points ps 0.8 pt 7 lc 'forest-green', s(x) title \"fit\" lw 2 lc 'black'"
elif [ "$grade" -eq "4" ] ; then
    c_plot="plot \"${inputFile}\" title \"data\" with points ps 0.8 pt 7 lc 'gray', s(x) title \"fit\" lw 2 lc 'black'"
elif [ "$grade" -eq "6" ] ; then
    c_plot="plot \"${inputFile}\" title \"data\" with points ps 0.8 pt 7 lc 'red', s(x) title \"fit\" lw 2 lc 'black'"
else
    echo "grade ${grade} is out of scope"
    exit
fi


# gnuplot
gnuplot << _EOT_ >& /dev/null

# define
f(x) = a * ( x - 306.5 )**2 + b * ( x - 306.5 ) + c
g(x) = b * ( x - 306.5 ) + c
h(x) = b * ( 2000 - 306.5 ) + c
s(x) = x<306.5 ? f(x) : x<2000 ? g(x) : h(x)

# set
set xrange [0:2500]
set yrange [${y_min}:${y_max}]
set xlabel 'PHA (ch)'
set ylabel 'Goffset (ch)'
set xlabel font "Arial, 25"
set ylabel font "Arial, 25"
set xtics font "Arial, 25"
set ytics font "Arial, 25"
set key font "Arial, 15"
set xlabel offset 0, -2
set ylabel offset -5, 0
set xtics offset 0, -1
set ytics offset -1, 0
set size 0.8, 0.9
set origin 0.12, 0.05

# fit
fit s(x) "${inputFile}" using 1:2 via a, b, c

# plot
${c_plot}

# save var
save variables "${f_fitData}"

# save graph
set terminal pdfcairo size 6, 4
set output "${f_pdf}"

# replot
replot

# exit
quit
_EOT_

exit
