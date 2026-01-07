

プログラム1
　シミュレーションデータを作成
　　・auto_makeData_v0.10.2.bash 
　　・FakeData_Goffset_PlusNoise_v0.10.2.c

　ガウス関数でピークをフィットし、フィッティングパラメータを出力
　　・gaussFit_main_goffsetPG_v1.0.bash
　　・gaussFit_sub_goffsetPG_v1.0.bash
　　・qdpFit_v1.0.bash

　PHA vs goffsetを出力
　　・calcGoffset_PHASSUM-PHA_v0.3.bash
　もしくは
　　・calcGoffset_PHA0-PHA_v0.3.bash

　

備考
・cFile
FakeData_Goffset_PlusNoise_v0.10.2.c
　シミュレーションのアルゴリズムはv0.10のまま。
　Gradeごとにスペクトルを作成し、別ファイルに保存するように変更


