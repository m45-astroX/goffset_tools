# mkGoffsetFunctionDataFromCALDB

\# 2024.12.20 v1 by Yuma Aoki (Kindai Univ.)

## 概要

CTI-CALDBに書き込まれているGoffset補正関数のパラメータを出力するスクリプト

## 使い方

    $ bash mkGoffsetFunctionDataFromCALDB.bash
    $1 : CTI CALDB (infile)
    $2 : outfile
    $3 : CCD_ID
    $4 : SEGMENT
    $5 : READNODE (Optional; Default=0)
    $6 : FITS extention (Optional; Default=1)

### Exsample

    $ bash mkGoffsetFunctionDataFromCALDB.bash xa_xtd_cti_20190101v002.fits goffsetFunc_c0s0.dat 0 0
