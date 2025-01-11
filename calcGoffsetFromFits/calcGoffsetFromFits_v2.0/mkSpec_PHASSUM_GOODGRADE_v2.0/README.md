# mkSpec_PHASSUM_GOODGRADE

2024.08.02 v1 by Yuma Aoki (Kindai Univ.)


## 概要

GoodGrade(Grade 0, 2, 3, 4, 6) の PHAS_SUM スペクトルを作成するスクリプト。


## 使用方法

Makefileの中身は環境により適宜変更する。

    $ make

    $ ./mkSpec_PHASSUM_GOODGRADE evtfile outfile (PHAScol; optional)
        PHAScol : PHAS column to be used to calculate PHAS_SUM
        Default value is set to PHAS_CTICORR
        Users can set the value as shown below...
        ( PHAS / PHAS_EVENODD / PHAS_TRAILCORR / PHAS_CTICORR )
