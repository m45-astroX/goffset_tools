/*
 2021-05-29, 一つのX線イベントに対して、波高値の計算とノイズ加算を行うプログラム。
 2021-06-29, v3: 入射位置をランダムにする
 2021-07-08, v4: Fano factor を入れる
 2021-07-15, v0.5: bug fix
 2021-07-23, v0.6: bug fix, squareroot of fano_factor
 2021-07-26, v0.7: good grade, all-grade の PHAS_SUM を追加。
 2021-08-27, v0.8: bug fix (pha_int, phas_sum_int)
 2021-08-28, v0.9: pha_int, phas_sum_intの仕様変更
 2021-09-16, v0.10: 負のPHA,PHAS_SUMに対応
 */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
 
double nrand();
    // 正規分布に従うデータを出力する関数
double calc_ph( double x, double y, double pha, double sigma_charge );
    // ピクセルをN=100マス(変更可)に区切って、電荷量を計算する関数
void func ( char list );
    // listを表示する関数
int det_grade( double phas_input[9], int spth );
    // グレード判定関数
double calc_phas( double pha, int px_no, double sigma_charge, double x0, double y0 );
    // 各ピクセルの波高値を計算する
double calc_pha( double phas_input[9], int grade );
    // Gradeごとの演算
double phas_sum( double phas_input[9] );    // PHA_SUM (3x3の合計)



int main( int argc, char *argv[] ){
    
    double noise = 5.0;
    double sigma_charge = 0.1;
    double phas[9] = {0, 0, 0, 0, 0, 0, 0, 0, 0};
        // 各ピクセルの波高値を格納
    double phas_cor[9] = {0, 0, 0, 0, 0, 0, 0, 0, 0};
        // ノイズを加えた後の各ピクセルの波高値を格納
    
    int grade = -1;
    int spth = 15;          // split threshold
    int num_trial = 0;      // 試行回数
    
    double x0 = 0.0;        // X線が入射した点のx座標
    double y0 = 0.0;        // X線が入射した点のy座標
    double pha0 = 100.0;    // 波高値の初期値
    double pha = 100.0;     // 波高値
    
    double pha_fano = 100.0;
        // PHA にfano揺らぎを加算したもの。 1ch/eV、 1electron = 3.65eV を仮定
    double fano_factor = 0.115; // fano factor
    
    int pha_int = 0;        // PHA 計算値の四捨五入値
    int phas_sum_int = 0;   // PHAS_SUM の四捨五入
    
    int i = 0;        // loop用
    int j = 0;        // loop用
    int a = 0;        // loop用
    
    FILE *fp1_org = NULL;       // ファイル
    FILE *fp2_org = NULL;       // ファイル
    FILE *fp3_org = NULL;       // ファイル
    FILE *fp1_cor = NULL;       // ファイル
    FILE *fp2_cor = NULL;       // ファイル
    FILE *fp3_cor = NULL;       // ファイル
    
    int **sp_cnt_org = NULL;               // スペクトル用
    int **sp_cnt_phassum_org = NULL;       // スペクトル用, [8]は PHAS_SUM用, [9] は全イベント
    int **sp_cnt_cor = NULL;               // スペクトル用
    int **sp_cnt_phassum_cor = NULL;       // スペクトル用, [8]は PHAS_SUM用, [9] は全イベント
    
    /* メモリ確保 */
    // 1.Grade数だけメモリを確保
    // 2.各Gradeについて、-1000chから4095chまでメモリを確保
    sp_cnt_org = (int**)malloc( sizeof(int*) * 8 );
    for ( i=0; i<8; i++ ) {
        sp_cnt_org[i] = (int*)malloc( sizeof(int) * 5096 );
        sp_cnt_org[i] = sp_cnt_org[i] + 1000;       //ポインタ値の変更
    }
    sp_cnt_phassum_org = (int**)malloc( sizeof(int*) * 10 );
    for ( i=0; i<10; i++ ) {
        sp_cnt_phassum_org[i] = (int*)malloc( sizeof(int) * 5096 );
        sp_cnt_phassum_org[i] = sp_cnt_phassum_org[i] + 1000;       //ポインタ値の変更
    }
    sp_cnt_cor = (int**)malloc( sizeof(int*) * 8 );
    for ( i=0; i<8; i++ ) {
        sp_cnt_cor[i] = (int*)malloc( sizeof(int) * 5096 );
        sp_cnt_cor[i] = sp_cnt_cor[i] + 1000;       //ポインタ値の変更
    }
    sp_cnt_phassum_cor = (int**)malloc( sizeof(int*) * 10 );
    for ( i=0; i<10; i++ ) {
        sp_cnt_phassum_cor[i] = (int*)malloc( sizeof(int) * 5096 );
        sp_cnt_phassum_cor[i] = sp_cnt_phassum_cor[i] + 1000;       //ポインタ値の変更
    }
    // メモリが確保できているか確認
    if ( sp_cnt_org == NULL || sp_cnt_phassum_org == NULL || sp_cnt_cor == NULL || sp_cnt_phassum_cor == NULL ) {
        printf("メモリ確保失敗\n");
        return -1;
    }
    
    // 初期化
    for ( i=0 ; i<8 ; i++){   
        for ( a=-1000 ; a<4096 ; a++){
            sp_cnt_org[i][a] = 0;
            sp_cnt_cor[i][a] = 0;
        }
    }
    for ( i=0 ; i<10 ; i++){   
        for ( a=-1000 ; a<4096 ; a++){
            sp_cnt_phassum_org[i][a] = 0;
            sp_cnt_phassum_cor[i][a] = 0;
        }
    }
    
    // 引数が4つでなければ使用方法の表示とともに終了
    if ( argc != 5 ){
        printf("Usage: ./FakeData_Goffset [PHA] [電荷分布(σ)] [ノイズ(rms)] [試行回数]\n");
        //printf("      [位置ランダム]: 入射位置をランダムにするか。0ならランダムにしない, 1ならランダム\n");
        //printf("      [ノイズ計算回数]: 元のPHのノイズ加算の試行回数。0なら実行しない\n");
        exit(0);
    }
    
    /* 入力パラメータの代入 */
    pha0 = atof(argv[1]);           //PHAの初期値(発生した全電荷による波高値)
    sigma_charge = atof(argv[2]);   //電荷分布の標準偏差σ
    noise = atof(argv[3]);          //ノイズ
    num_trial = atof(argv[4]);      //ノイズ加算試行回数
    
    printf("input (PHA, sigma_charge, noise, trial)= (%1.0f %1.2f %1.2f %1d)\n", pha0, sigma_charge, noise, num_trial );         //入力された数値の表示
    
    /* 書き込みファイル準備 */
    fp1_org = fopen("Event_org.dat","w");
    if( fp1_org == NULL ){
        printf("ファイルオープンエラー\n");
        return -1;
    }
    fp1_cor = fopen("Event_cor.dat","w");
    if( fp1_cor == NULL ){
        printf("ファイルオープンエラー\n");
        return -1;
    }
    
    /* 計算 loop */
    fprintf(fp1_org, "x       y         PHA     PHAS[0-8]                                      GRADE  PHAS_SUM\n");
    fprintf(fp1_cor, "x       y         PHA     PHAS[0-8]                                      GRADE  PHAS_SUM\n");
    
    for ( i=0 ; i<num_trial ; i++){
        
        /* 入力座標の乱数化 */
        x0 = drand48() - 0.5;
        y0 = drand48() - 0.5;
        
        /* PHAS(各ピクセルの波高値)を計算する */
        /* fano を加算して、PHAS(各ピクセルの波高値)を計算する */
        pha_fano = pha0 * ( 1.0 + (double)nrand() / sqrt( pha0 * 6.0 / 3.65 ) * sqrt(fano_factor) );
        
        for ( a=0 ; a<9 ; a++){     //9マスすべてに関して波高値の計算をする
            //phas[a] = calc_phas( pha0, a, sigma_charge, x0, y0 );
            phas[a] = calc_phas( pha_fano, a, sigma_charge, x0, y0 );
                //各ピクセルについて、波高値を計算する(全波高値,ピクセル番号,標準偏差σ,x座標(X線が入射した点のx座標),y座標(X線が入射した点のy座標))
        }
        
        /* grade 判定 */
        grade = det_grade( phas, spth );
        
        /* pha 計算 (グレードごとの演算を実行する(足し合わせ)) */
        pha = calc_pha( phas, grade );
        
        /* 波高値分布を出力 */
        // printf("%6.3f %6.3f %9.2f %6.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %5d\n", x0, y0, pha, phas[0], phas[1], phas[2], phas[3], phas[4], phas[5], phas[6], phas[7], phas[8], grade);
        fprintf(fp1_org, "%6.3f %6.3f %9.2f %6.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %5d %9.2f\n", x0, y0, pha, phas[0], phas[1], phas[2], phas[3], phas[4], phas[5], phas[6], phas[7], phas[8], grade, phas_sum(phas));
        
        /* スペクトル計算 */
        pha_int = (int)(pha + 0.5);
        sp_cnt_org[grade][pha_int] = sp_cnt_org[grade][pha_int] + 1;
        
        phas_sum_int = (int)(phas_sum(phas)+0.5);
        sp_cnt_phassum_org[grade][phas_sum_int] = sp_cnt_phassum_org[grade][phas_sum_int] + 1;
        
        // good grade PHAS_SUM spectrum
        if ( grade == 0 || grade == 2 || grade == 3 || grade == 4 || grade == 6 ){
            sp_cnt_phassum_org[8][phas_sum_int] = sp_cnt_phassum_org[8][phas_sum_int] + 1;
        }
        // 全イベントの PHAS_SUM
        sp_cnt_phassum_org[9][phas_sum_int] = sp_cnt_phassum_org[9][phas_sum_int] + 1;
        

        
        /* ノイズを加えた結果を出力 */
        for ( a=0 ; a<9 ; a++){     //9ピクセルに対しノイズを加算する
            phas_cor[a] = phas[a] + (double)nrand() * noise;         //各ピクセルに対してノイズを加算
        }
        
        /* grade 判定 */
        grade = det_grade(phas_cor, spth);
        
        /* pha 計算 (グレードごとの演算を実行する(足し合わせ)) */
        pha = calc_pha(phas_cor, grade);
        
        /* 波高値分布を出力 */
        //printf("%6.3f %6.3f %9.2f %6.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %5d\n", x0, y0, pha, phas_cor[0], phas_cor[1], phas_cor[2], phas_cor[3], phas_cor[4], phas_cor[5], phas_cor[6], phas_cor[7], phas_cor[8], grade);
        fprintf(fp1_cor, "%6.3f %6.3f %9.2f %6.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %5d %9.3f\n", x0, y0, pha, phas_cor[0], phas_cor[1], phas_cor[2], phas_cor[3], phas_cor[4], phas_cor[5], phas_cor[6], phas_cor[7], phas_cor[8], grade, phas_sum(phas_cor));
        
        /* スペクトル計算 */
        pha_int = (int)(pha + 0.5);
        sp_cnt_cor[grade][pha_int] = sp_cnt_cor[grade][pha_int] + 1;
        
        phas_sum_int = (int)(phas_sum(phas_cor) + 0.5);
        sp_cnt_phassum_cor[grade][phas_sum_int] = sp_cnt_phassum_cor[grade][phas_sum_int] + 1;
        
        // good grade PHAS_SUM spectrum
        if ( grade == 0 || grade == 2 || grade == 3 || grade == 4 || grade == 6 ){
            sp_cnt_phassum_cor[8][phas_sum_int] = sp_cnt_phassum_cor[8][phas_sum_int] + 1;
        }
        // 全イベントの PHAS_SUM
        sp_cnt_phassum_cor[9][phas_sum_int] = sp_cnt_phassum_cor[9][phas_sum_int] + 1;
        
    }
    fclose(fp1_org);  // ファイル閉じる。
    fclose(fp1_cor);  // ファイル閉じる。
    
    /* PHA スペクトル */
    fp2_org = fopen("Spectrum_org.dat","w");
    if( fp2_org == NULL ){
        printf("ファイルオープンエラー\n");
        return -1;
    }
    fp2_cor = fopen("Spectrum_cor.dat","w");
    if( fp2_cor == NULL ){
        printf("ファイルオープンエラー\n");
        return -1;
    }
    // スペクトルを出力, ノイズ加算なし
    fprintf(fp2_org, "! PHA, COUNTS\n");
    fprintf(fp2_org, "SKIP SINGLE\n");

    for (i=0 ; i<8 ; i++){
        for ( j=-1000 ; j<4096 ; j++ ){
            fprintf(fp2_org, "%5d %6d\n", j, sp_cnt_org[i][j]);
        }
        fprintf(fp2_org, "NO\n");
    }
    // スペクトルを出力, ノイズ加算あり
    fprintf(fp2_cor, "! PHA, COUNTS\n");
    fprintf(fp2_cor, "SKIP SINGLE\n");
    
    for (i=0 ; i<8 ; i++){
        for ( j=-1000 ; j<4096 ; j++ ){
            fprintf(fp2_cor, "%5d %6d\n", j, sp_cnt_cor[i][j]);
        }
        fprintf(fp2_cor, "NO\n");
    }
    fclose(fp2_org);  // ファイル閉じる。
    fclose(fp2_cor);  // ファイル閉じる。
    
    /* PHAS_SUM スペクトル */
    fp3_org = fopen("Spectrum_PhasSum_org.dat","w");
    if( fp3_org == NULL ){
        printf("ファイルオープンエラー\n");
        return -1;
    }
    fp3_cor = fopen("Spectrum_PhasSum_cor.dat","w");
    if( fp3_cor == NULL ){
        printf("ファイルオープンエラー\n");
        return -1;
    }
    
    // スペクトルを出力, ノイズ加算なし
    fprintf(fp3_org, "! PHAS_SUM, COUNTS\n");
    fprintf(fp3_org, "SKIP SINGLE\n");

    for (i=0 ; i<10 ; i++){
        for ( j=-1000 ; j<4096 ; j++ ){
            fprintf(fp3_org, "%5d %6d\n", j, sp_cnt_phassum_org[i][j]);
        }
        fprintf(fp3_org, "NO\n");
    }
    // スペクトルを出力, ノイズ加算あり
    fprintf(fp3_cor, "! PHAS_SUM, COUNTS\n");
    fprintf(fp3_cor, "SKIP SINGLE\n");
    
    for (i=0 ; i<10 ; i++){
        for ( j=-1000 ; j<4096 ; j++ ){
            fprintf(fp3_cor, "%5d %6d\n", j, sp_cnt_phassum_cor[i][j]);
        }
        fprintf(fp3_cor, "NO\n");
    }
    fclose(fp3_org);  // ファイル閉じる。
    fclose(fp3_cor);  // ファイル閉じる。
    
    /* メモリ解放 */
    // ポインタ
    for ( i=0; i<8; i++ ) {
        free(sp_cnt_org[i] - 1000);
        free(sp_cnt_cor[i] - 1000);
    }
    for ( i=0; i<10; i++ ) {
        free(sp_cnt_phassum_org[i] - 1000);
        free(sp_cnt_phassum_cor[i] - 1000);
    }
    // ダブルポインタ
    free(sp_cnt_org);
    free(sp_cnt_phassum_org);
    free(sp_cnt_cor);
    free(sp_cnt_phassum_cor);
    
    return 0;
    
}



/* 各ピクセルの波高値を計算する関数(波高値分布を得る) */
double calc_phas( double pha, int px_no, double sigma_charge, double x0, double y0 ){       //x0,y0は、X線が入射した点の座標(x0,y0)
    //(全波高値,ピクセル番号,σ,x座標,y座標)
    
    double x = 0.0;             //座標計算用
    double y = 0.0;             //座標計算用
    
    if ( px_no == 0 ){          //ピクセル番号が0のとき
        x =  0.0 - x0;          //x座標を指定( 0.0 - X線が入射した点のx座標)
        y =  0.0 - y0;          //y座標を指定( 0.0 - X線が入射した点のy座標)
    } else if ( px_no == 1 ){   //ピクセル番号が1のとき
        x = -1.0 - x0;          //x座標を指定(-1.0 - X線が入射した点のx座標)
        y = -1.0 - y0;          //y座標を指定(-1.0 - X線が入射した点のy座標)
    } else if ( px_no == 2 ){   //ピクセル番号が2のとき
        x =  0.0 - x0;          //x座標を指定( 0.0 - X線が入射した点のx座標)
        y = -1.0 - y0;          //y座標を指定(-1.0 - X線が入射した点のy座標)
    } else if ( px_no == 3 ){   //ピクセル番号が3のとき
        x =  1.0 - x0;          //x座標を指定( 1.0 - X線が入射した点のx座標)
        y = -1.0 - y0;          //y座標を指定(-1.0 - X線が入射した点のy座標)
    } else if ( px_no == 4 ){   //ピクセル番号が4のとき
        x = -1.0 - x0;          //x座標を指定(-1.0 - X線が入射した点のx座標)
        y =  0.0 - y0;          //y座標を指定( 0.0 - X線が入射した点のy座標)
    } else if ( px_no == 5 ){   //ピクセル番号が5のとき
        x =  1.0 - x0;          //x座標を指定( 1.0 - X線が入射した点のx座標)
        y =  0.0 - y0;          //y座標を指定( 0.0 - X線が入射した点のy座標)
    } else if ( px_no == 6 ){   //ピクセル番号が6のとき
        x = -1.0 - x0;          //x座標を指定(-1.0 - X線が入射した点のx座標)
        y =  1.0 - y0;          //y座標を指定( 1.0 - X線が入射した点のy座標)
    } else if ( px_no == 7 ){   //ピクセル番号が7のとき
        x =  0.0 - x0;          //x座標を指定( 0.0 - X線が入射した点のx座標)
        y =  1.0 - y0;          //y座標を指定( 1.0 - X線が入射した点のy座標)
    } else if ( px_no == 8 ){   //ピクセル番号が8のとき
        x =  1.0 - x0;          //x座標を指定( 1.0 - X線が入射した点のx座標)
        y =  1.0 - y0;          //y座標を指定( 1.0 - X線が入射した点のy座標)
    }
    return (double)calc_ph( x, y, pha, sigma_charge );
    //計算したx座標,計算したy座標,全波高値,標準偏差を返す
}



/* ピクセルをj×kマスに区切って、電荷の分布(正規分布)を計算する関数(電荷分布から ph[0-8] を計算する。) */
double calc_ph( double x, double y, double pha, double sigma_charge )
{
    double sum_calcph=0;            //波高値計算用(初期値ゼロ)
    double sigma_calcph;            //計算用標準偏差σ
    sigma_calcph = sigma_charge;    //σを代入
    double x1, y1;                  //x座標とy座標(擬似ピクセル)
    double pi=3.141592;             //円周率

    int j=1;    //擬似ピクセル選択loop用
    int k=1;    //擬似ピクセル選択loop用

    //セルを100マスに区切り(=擬似ピクセルとする)、擬似ピクセル一つ一つに対して波高値を計算していく(10000マス)
    //擬似ピクセルそれぞれの波高値の和を、各ピクセルの波高値とする
    for ( j=1 ; j<=100 ; j++ ){
        for ( k=1 ; k<=100 ; k++ ){
            x1 = x + j*0.01 - 0.005 - 0.5;    //擬似ピクセルのx座標(x:ピクセルの中心座標)
            y1 = y + k*0.01 - 0.005 - 0.5;    //擬似ピクセルのy座標(y:ピクセルの中心座標)
            //波高値の計算
            sum_calcph = sum_calcph
                + exp(-1*( x1*x1 + y1*y1 ) / 2 / sigma_calcph / sigma_calcph ) / (2*pi*sigma_calcph*sigma_calcph) / 10000 * pha ;       //2次元ガウス分布に基づいた計算,(10000)は擬似ピクセル数
        }
    }
    return(sum_calcph);         //計算したピクセル波高値を返す
}



/* 標準正規分布(Ave=0,Sigma=1)に従うデータを出力する関数 */
double nrand () {
    static int sw = 0;        //準グローバル変数(整数)。初期化(=0)はプログラムがスタートした時のみ。
    static double r1,r2,s;  //準ゴローバル変数(小数)。初期化(=0)はプログラムがスタートした時のみ。

    if ( sw == 0 ){                     //swの値が0のとき
        sw = 1;                         //swを1とする
        do {                            //do while(条件は下に記載)
            r1=2.0*drand48()-1.0;       //(drand48():[0.0,1.0)の区間で乱数を発生)*2 -1.0
            r2=2.0*drand48()-1.0;       //(drand48():[0.0,1.0)の区間で乱数を発生)*2 -1.0
            s=r1*r1+r2*r2;              //r1とr2の二乗和を計算
        } while (s>1.0 || s==0.0);      //sが1より大きくなってしまった場合,またはsが0になってしまった場合、loop継続,最計算
        s=sqrt(-2.0*log(s)/s);          //(s^(-2)の対数をsで割る)のルート
        return(r1*s);                   //結果を返す
    }
    else {                              //swの値が1のとき
            sw=0;                       //swを0に戻す
            return(r2*s);         //結果を返す
    }
}



/* 与えられた数値を表示する関数 */
void func( char list ) {
        printf("渡された値は%dです\n" , list );     //数値を表示
}



/* Grade 判定 */
int det_grade( double phas_input[9], int spth ){        //(各ピクセルの波高値(9個の配列),閾値)
    
    int grade_out;      //グレードの出力
    grade_out = 0;      //グレードの出力の初期値を0とする
    int grade_ref[256] = {0, 1, 2, 5, 1, 1, 5, 7, 3, 5, 8, 6, 3, 5, 7, 7, 4, 4, 8, 7, 5, 5, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 1, 1, 2, 5, 1, 1, 5, 7, 5, 7, 7, 7, 5, 7, 7, 7, 4, 4, 8, 7, 5, 5, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 2, 2, 7, 7, 2, 2, 7, 7, 8, 7, 7, 7, 8, 7, 7, 7, 8, 8, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 5, 5, 7, 7, 5, 5, 7, 7, 6, 7, 7, 7, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 1, 1, 2, 5, 1, 1, 5, 7, 3, 5, 8, 6, 3, 5, 7, 7, 5, 5, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 1, 1, 2, 5, 1, 1, 5, 7, 5, 7, 7, 7, 5, 7, 7, 7, 5, 5, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 5, 5, 7, 7, 5, 5, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7};       //256個のパターンを定義。グレードを決めるときに参照する辞書のようなもの
    int phas_pattern;   //gradeを確定させる変数(grade_refの[番号]と対応)
    phas_pattern = 0;   //パターンの初期値を0とする
    
    int b=1;            //loop用
    for ( b=1 ; b<9 ; b++){
        //計算された各ピクセルの波高値を、9×9(実際には一列)に格納(イベント中心以外について考えるので、b=1からとなってる)
        if ( phas_input[b] >= spth ){                   //入力が閾値を超えているとき
            phas_pattern = phas_pattern + pow(2, b-1);  //パターンの数値(grade_refの番号と対応)を増やしていく
        }
    }
    grade_out = grade_ref[phas_pattern];    //パターンのリファレンスを確認し、対応するグレードを決定。
    if ( grade_out == 8 ){                  //Grade8と出た場合
        grade_out = 6;                      //Grade6と変更
    }
    return(grade_out);                      //グレードを返す
    
}



/* Gradeごとの演算(和を計算) */
double calc_pha( double phas_input[9], int grade ){         //(波高値各ピクセルの波高値,グレード)
    double pha_out = 0;                                     //出力の初期値を0にしとく
    if ( grade == 0 ){                                      //グレード0のとき
        pha_out = phas_input[0];                            //0番のピクセルだけ使用
        
    } else if ( grade == 1 || grade == 5 || grade == 7 ){   //グレード1,5,7のとき
        pha_out = phas_input[0];                            //中心の値だけ使用
        
    } else if ( grade == 2 ){                               //グレード2のとき
        if ( phas_input[2] <= phas_input[7] ){              //下よりも上の方が波高値が高いとき(ピクセル波高値の比較)
            pha_out = phas_input[0] + phas_input[7];        //中心と上を足す
        } else {                                            //上よりも下の方が波高値が高いとき(ピクセル波高値の比較)
            pha_out = phas_input[0] + phas_input[2];        //中心と下を足す
        }
    } else if ( grade == 3 ){                               //グレード3のとき
        pha_out = phas_input[0] + phas_input[4];            //中心と左の和をとる
        
    } else if ( grade == 4 ){                               //グレード4のとき
        pha_out = phas_input[0] + phas_input[5];            //中心と右の和をとる
    } else if ( grade == 6 ){                                                               //グレード6のとき(分岐が4パターン,上下左右について比較)
        if ( phas_input[2] >= phas_input[7] && phas_input[4] >= phas_input[5] ){            //上よりも下の方が波高値が高い∩左の方が右よりも波高値が高いとき(左下に電荷漏れ)
            pha_out = phas_input[0] + phas_input[1] + phas_input[2] + phas_input[4];        //中心,左下,下,左の和をとる
        } else if ( phas_input[2] >= phas_input[7] && phas_input[4] < phas_input[5] ){      //上よりも下の方が波高値が高い∩右の方が左よりも波高値が高いとき(右下に電荷漏れ)
            pha_out = phas_input[0] + phas_input[2] + phas_input[3] + phas_input[5];        //中心,下,右下,右の和をとる
        } else if ( phas_input[2] < phas_input[7] && phas_input[4] >= phas_input[5] ){      //下よりも上の方が波高値が高い∩左の方が右よりも波高値が高いとき(左上に電荷漏れ)
            pha_out = phas_input[0] + phas_input[4] + phas_input[6] + phas_input[7];        //中心,左,左上,上の和をとる
        } else if ( phas_input[2] < phas_input[7] && phas_input[4] < phas_input[5] ){       //下よりも上の方が波高値が高い∩右の方が左よりも波高値が高いとき(右上に電荷漏れ)
            pha_out = phas_input[0] + phas_input[5] + phas_input[7] + phas_input[8];        //中心,右,上,右上の和をとる
        }
    }
    return(pha_out);        //計算した波高値を返す
}



double phas_sum( double phas_input[9] ){
    
    double phas_sum_value = 100.0;
    
    phas_sum_value = phas_input[0] + phas_input[1] + phas_input[2] + phas_input[3] + phas_input[4] + phas_input[5] + phas_input[6] + phas_input[7] + phas_input[8];
    
    return(phas_sum_value);
    
}



