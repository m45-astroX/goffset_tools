# gaussFit

2024.08.02 v1 by Yuma Aoki (Kindai Univ.)

## 使用方法

qdp形式のスペクトルファイルをGaussianでフィットする。
ただし、スペクトルファイルはコメント行を含む全ての文字列を排除しなければならない。

    $ bash gaussFit_v2.1.3.bash specfile

## 出力

スクリプトを実行すると以下の値が出力される

    GaussianCenter   GaussianCenter_Error(1sigma)
    GaussianWidth    GaussianWidth_Error(1sigma)
    GaussianNorm     GaussianNorm_Error(1sigma)
