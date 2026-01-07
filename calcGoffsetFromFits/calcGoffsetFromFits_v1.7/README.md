# calcGoffsetFromFits

\# 2024.08.02 v1.0


## 概要

イベントファイルからGoffsetを算出するスクリプト。
PHA_MIN, PHA_MAXにより、Goffset算出に用いる輝線を決める。


## 使用方法

    $ bash calcGoffsetFromFits_v1.1.bash evtfile PHA_MIN PHA_MAX (PHASSUM_MIN; optional) (PHASSUM_MAX; optional)"

    evtfile ($1) : Xtend cleaned event file processed by xtdpipeline with usegoffset option 'no'
    PHA_MIN and PHA_MAX ($2/$3) : The range of pha spectrum to be fitted
    PHASSUM_MIN and PHASSUM_MAX ($4/$5) : The range of phassum spectrum to be fitted
