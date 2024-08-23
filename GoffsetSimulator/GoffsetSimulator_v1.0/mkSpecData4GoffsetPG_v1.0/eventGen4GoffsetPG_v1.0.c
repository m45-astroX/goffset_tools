/*

    Goffset_makeData

    v0 : Masayoshi Nobukawa (Nara Univ. of education)
    v1.0 : Yuma Aoki (Kindai Univ.)

*/

#include <stdio.h>
#include <stdlib.h>
#include <math.h>


/* 関数の定義 */
int det_grade( double phas_input[9], int spth );
    // Grade判定関数
double nrand();
    // 標準正規分布(Ave=0,Sigma=1)に従う確率変数を出力する関数
double calc_phas( double pha, int px_no, double sigma_charge, double x0, double y0 );
    // 各ピクセルのPHを計算する関数(マスタ)
double calc_ph( double x, double y, double pha, double sigma_charge );
    // 各ピクセルのPHを計算する関数
double calc_pha( double phas_input[9], int grade );
    // GradeにしたがってPHAを計算する関数
double phas_sum( double phas_input[9] );
    // PHA_SUMを計算する関数



int main ( int argc, char *argv[] ) {

    /* Variables */
    int grade = -1;             // Grade
    int spth = 15;              // SplitThreshold
    int num_trial = 0;          // 試行回数
    int pha_int = 0;            // 整数に丸めたPHA
    int phas_sum_int = 0;       // 整数に丸めたPHAS_SUM
    double noise = 0.0;         // ノイズ
    double x0 = 0.0;            // X線が入射した点のx座標
    double y0 = 0.0;            // X線が入射した点のy座標
    double pha0 = 0.0;          // ノイズ、ファノゆらぎがない場合での波高値
    double pha0_fano = 0.0;     // 変数pha0にファノゆらぎを与えたもの1 electron = 3.65 eV を仮定
    double pha = 0.0;           // PHA (Gradeにしたがって計算した波高値)
    double fano_factor = 0.115; // ファノ因子
    double sigma_charge = 0.1;  // 電荷雲の大きさ(電荷雲の密度分布を2次元Gaussianと仮定したときの幅)
    double phas[9] = {0, 0, 0, 0, 0, 0, 0, 0, 0};       // 各ピクセルの波高値
    double phas_cor[9] = {0, 0, 0, 0, 0, 0, 0, 0, 0};   // 各ピクセルの波高値(ノイズを与えたもの)
    char filename[256];
    


    /* 引数のチェック */
    if ( argc != 5 ){
        fprintf(stderr, "Usage: ./Goffset_makeData PHA0 sigma noise num_trial\n");
        fprintf(stderr, "    sigma : Size of charge cloud (double)\n");
        return -1;
    }
    else {
        pha0 = atof(argv[1]);
        sigma_charge = atof(argv[2]);
        noise = atof(argv[3]);
        num_trial = atof(argv[4]);
        fprintf(stdout, "input (PHA0, sigma, noise, trial) = (%1.0f %1.2f %1.2f %1d)\n", pha0, sigma_charge, noise, num_trial);
    }


    /* メモリ確保 */
    // Note1: Grade数だけメモリを確保
    // Note2: 各Gradeについて、-1000chから4095chまでメモリを確保

    // ダブルポインタで配列を管理
    int **sp_cnt_org = NULL;               // PHAのスペクトル計算用配列。ノイズなし。
    int **sp_cnt_phassum_org = NULL;       // PHAS_SUMのスペクトル計算用配列。ノイズなし。[8]はGoodGrade, [9]は全Grade。
    int **sp_cnt_cor = NULL;               // PHAのスペクトル計算用配列。ノイズあり。
    int **sp_cnt_phassum_cor = NULL;       // PHA_SUMのスペクトル計算用配列。ノイズあり。[8]はGoodGrade, [9]は全Grade。

    // PHAのスペクトル
    sp_cnt_org = (int**)malloc( sizeof(int*) * 8 );     // ノイズなし
    sp_cnt_cor = (int**)malloc( sizeof(int*) * 8 );     // ノイズあり
    for ( int i=0; i<8; i++ ) {
        sp_cnt_org[i] = (int*)malloc( sizeof(int) * 5096 );
        sp_cnt_org[i] = sp_cnt_org[i] + 1000;
        sp_cnt_cor[i] = (int*)malloc( sizeof(int) * 5096 );
        sp_cnt_cor[i] = sp_cnt_cor[i] + 1000;
    }

    // PHAS_SUMのスペクトル
    sp_cnt_phassum_org = (int**)malloc( sizeof(int*) * 10 );    // ノイズなし
    sp_cnt_phassum_cor = (int**)malloc( sizeof(int*) * 10 );    // ノイズあり
    for ( int i=0; i<10; i++ ) {
        sp_cnt_phassum_org[i] = (int*)malloc( sizeof(int) * 5096 );
        sp_cnt_phassum_org[i] = sp_cnt_phassum_org[i] + 1000;
        sp_cnt_phassum_cor[i] = (int*)malloc( sizeof(int) * 5096 );
        sp_cnt_phassum_cor[i] = sp_cnt_phassum_cor[i] + 1000;
    }

    if ( sp_cnt_org == NULL || sp_cnt_phassum_org == NULL || sp_cnt_cor == NULL || sp_cnt_phassum_cor == NULL ) {
        fprintf(stderr, "Memory error!\nabort\n");
        return -1;
    }
    
    
    /* 配列の初期化 */
    for ( int i=0 ; i<=7 ; i++ ) {   
        for ( int j=-1000 ; j<4096 ; j++ ) {
            sp_cnt_org[i][j] = 0;
            sp_cnt_cor[i][j] = 0;
        }
    }
    for ( int i=0 ; i<=9 ; i++ ) {   
        for ( int j=-1000 ; j<4096 ; j++ ) {
            sp_cnt_phassum_org[i][j] = 0;
            sp_cnt_phassum_cor[i][j] = 0;
        }
    }
    

    /* ファイル設定 */
    // イベントファイル(ノイズなし)
    FILE *fp1_org = NULL;
    snprintf(filename, sizeof(filename), "Event_org.dat");
    fp1_org = fopen(filename, "w");
    if ( fp1_org == NULL ) {
        fprintf(stderr, "fopen error (%s)\nabort\n", filename);
        return -1;
    }
    // イベントファイル(ノイズあり)
    FILE *fp1_cor = NULL;
    snprintf(filename, sizeof(filename), "Event_cor.dat");
    fp1_cor = fopen(filename, "w");
    if ( fp1_cor == NULL ) {
        fprintf(stderr, "fopen error (%s)\nabort\n", filename);
        return -1;
    }

    // スペクトルファイル(PHA, ノイズなし)
    FILE *fp_spec_org[8];
    // ファイル作成(PHA)
    for ( int i=0; i<=7; i++ ) {
        snprintf(filename, sizeof(filename), "Spectrum_org_G%d.dat", i);
        fp_spec_org[i] = fopen(filename, "w");
        if ( fp_spec_org[i] == NULL ) {
            fprintf(stderr, "Could not open %s\nabort\n", filename);
            return -1;
        }
    }
    // スペクトルファイル(PHA, ノイズあり)
    FILE *fp_spec_cor[8];
    for ( int i=0; i<=7; i++ ) {
        snprintf(filename, sizeof(filename), "Spectrum_cor_G%d.dat", i);
        fp_spec_cor[i] = fopen(filename, "w");
        if ( fp_spec_cor[i] == NULL ) {
            fprintf(stderr, "Could not open %s\nabort\n", filename);
            return -1;
        }
    }
    // スペクトルファイル(PHAS_SUM, ノイズなし)
    FILE *fp_spec_org_sum[10];
    for ( int i=0; i<=9; i++ ) {
        snprintf(filename, sizeof(filename), "Spectrum_PhasSum_org_G%d.dat", i);
        fp_spec_org_sum[i] = fopen(filename, "w");
        if ( fp_spec_org_sum[i] == NULL ) {
            fprintf(stderr, "Could not open %s\nabort\n", filename);
            return -1;
        }
    }
    // スペクトルファイル(PHAS_SUM, ノイズあり)
    FILE *fp_spec_cor_sum[10];
    for ( int i=0; i<=9; i++ ) {
        snprintf(filename, sizeof(filename), "Spectrum_PhasSum_cor_G%d.dat", i);
        fp_spec_cor_sum[i] = fopen(filename, "w");
        if ( fp_spec_cor_sum[i] == NULL ) {
            fprintf(stderr, "Could not open %s\nabort\n", filename);
            return -1;
        }
    }


    /* イベント生成 */
    for ( int i=0 ; i<num_trial ; i++){
        
        /* 入力座標の乱数化 */
        x0 = drand48() - 0.5;
        y0 = drand48() - 0.5;
        
        /* PHA0にファノゆらぎを与える */
        pha0_fano = pha0 * ( 1.0 + (double)nrand() / sqrt( pha0 * 6.0 / 3.65 ) * sqrt(fano_factor) );
        
        /* 各ピクセルのPulseHeight計算 */
        for ( int a=0 ; a<9 ; a++ ) {
            phas[a] = calc_phas( pha0_fano, a, sigma_charge, x0, y0 );
        }
        
        /* Grade判定 */
        grade = det_grade( phas, spth );
        
        /* PHA計算 */
        pha = calc_pha( phas, grade );
        
        /* イベント情報を出力 */
        fprintf(fp1_org, "%6.3f %6.3f %9.2f %6.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %5d %9.2f\n", x0, y0, pha, phas[0], phas[1], phas[2], phas[3], phas[4], phas[5], phas[6], phas[7], phas[8], grade, phas_sum(phas));
        
        /* スペクトルデータ作成 */
        // PHA
        pha_int = (int)(pha + 0.5);
        sp_cnt_org[grade][pha_int] += 1;
        // PHAS_SUM
        phas_sum_int = (int)(phas_sum(phas)+0.5);
        sp_cnt_phassum_org[grade][phas_sum_int] += 1;
        // GoodGradeのPHAS_SUM
        if ( grade == 0 || grade == 2 || grade == 3 || grade == 4 || grade == 6 ) sp_cnt_phassum_org[8][phas_sum_int] += 1;
        // 全GradeのPHAS_SUM
        sp_cnt_phassum_org[9][phas_sum_int] = sp_cnt_phassum_org[9][phas_sum_int] + 1;



        /* 各ピクセルのPHに対しノイズを与える */
        for ( int a=0 ; a<9 ; a++ ) {
            phas_cor[a] = phas[a] + (double)nrand() * noise;         //各ピクセルに対してノイズを加算
        }
        
        /* Grade判定 */
        grade = det_grade(phas_cor, spth);
        
        /* PHA計算 */
        pha = calc_pha(phas_cor, grade);
        
        /* イベント情報を出力 */
        fprintf(fp1_cor, "%6.3f %6.3f %9.2f %6.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %5d %9.3f\n", x0, y0, pha, phas_cor[0], phas_cor[1], phas_cor[2], phas_cor[3], phas_cor[4], phas_cor[5], phas_cor[6], phas_cor[7], phas_cor[8], grade, phas_sum(phas_cor));
        
        /* スペクトルデータ作成 */
        // PHA
        pha_int = (int)(pha + 0.5);
        sp_cnt_cor[grade][pha_int] += 1;
        // PHAS_SUM
        phas_sum_int = (int)(phas_sum(phas_cor) + 0.5);
        sp_cnt_phassum_cor[grade][phas_sum_int] += 1;
        // GoodGradeのPHAS_SUM
        if ( grade == 0 || grade == 2 || grade == 3 || grade == 4 || grade == 6 ) sp_cnt_phassum_cor[8][phas_sum_int] += 1;
        // AllGradeのPHAS_SUM
        sp_cnt_phassum_cor[9][phas_sum_int] += 1;
        
    }

    
    /* PHAのスペクトルを出力 */
    for ( int i=0; i<=7; i++ ) {
        for ( int j=-1000 ; j<4096 ; j++ ) {
            // ノイズなし
            fprintf(fp_spec_org[i], "%5d %6d\n", j, sp_cnt_org[i][j]);
            // ノイズあり
            fprintf(fp_spec_cor[i], "%5d %6d\n", j, sp_cnt_cor[i][j]);
        }
    }

    /* PHAS_SUMのスペクトルを出力 */
    for ( int i=0; i<=9; i++ ) {
        for ( int j=-1000 ; j<4096 ; j++ ) {
            // ノイズなし
            fprintf(fp_spec_org_sum[i], "%5d %6d\n", j, sp_cnt_phassum_org[i][j]);
            // ノイズあり
            fprintf(fp_spec_cor_sum[i], "%5d %6d\n", j, sp_cnt_phassum_cor[i][j]);
        }
    }


    /* Close files */
    fclose(fp1_org);
    fclose(fp1_cor);
    for ( int i=0; i<=7; i++ ) {
        fclose(fp_spec_org[i]);
        fclose(fp_spec_cor[i]);
    }
    for ( int i=0; i<=9; i++ ) {
        fclose(fp_spec_org_sum[i]);
        fclose(fp_spec_cor_sum[i]);
    }

    
    /* メモリ解放 */
    // ポインタ
    for ( int i=0; i<=7; i++ ) {
        free(sp_cnt_org[i] - 1000);
        free(sp_cnt_cor[i] - 1000);
    }
    for ( int i=0; i<=9; i++ ) {
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



/* PH計算(マスタ) */
double calc_phas( double pha, int px_no, double sigma_charge, double x0, double y0 ) {
    
    double x = 0.0;
    double y = 0.0;
    
    if ( px_no == 0 ) {
        x =  0.0 - x0;          //x座標を指定( 0.0 - X線が入射した点のx座標)
        y =  0.0 - y0;          //y座標を指定( 0.0 - X線が入射した点のy座標)
    }
    else if ( px_no == 1 ) {
        x = -1.0 - x0;          //x座標を指定(-1.0 - X線が入射した点のx座標)
        y = -1.0 - y0;          //y座標を指定(-1.0 - X線が入射した点のy座標)
    }
    else if ( px_no == 2 ) {
        x =  0.0 - x0;          //x座標を指定( 0.0 - X線が入射した点のx座標)
        y = -1.0 - y0;          //y座標を指定(-1.0 - X線が入射した点のy座標)
    }
    else if ( px_no == 3 ) {
        x =  1.0 - x0;          //x座標を指定( 1.0 - X線が入射した点のx座標)
        y = -1.0 - y0;          //y座標を指定(-1.0 - X線が入射した点のy座標)
    }
    else if ( px_no == 4 ) {
        x = -1.0 - x0;          //x座標を指定(-1.0 - X線が入射した点のx座標)
        y =  0.0 - y0;          //y座標を指定( 0.0 - X線が入射した点のy座標)
    }
    else if ( px_no == 5 ) {
        x =  1.0 - x0;          //x座標を指定( 1.0 - X線が入射した点のx座標)
        y =  0.0 - y0;          //y座標を指定( 0.0 - X線が入射した点のy座標)
    }
    else if ( px_no == 6 ) {
        x = -1.0 - x0;          //x座標を指定(-1.0 - X線が入射した点のx座標)
        y =  1.0 - y0;          //y座標を指定( 1.0 - X線が入射した点のy座標)
    }
    else if ( px_no == 7 ) {
        x =  0.0 - x0;          //x座標を指定( 0.0 - X線が入射した点のx座標)
        y =  1.0 - y0;          //y座標を指定( 1.0 - X線が入射した点のy座標)
    }
    else if ( px_no == 8 ) {
        x =  1.0 - x0;          //x座標を指定( 1.0 - X線が入射した点のx座標)
        y =  1.0 - y0;          //y座標を指定( 1.0 - X線が入射した点のy座標)
    }
    
    return (double)calc_ph( x, y, pha, sigma_charge );

}



/* PH計算 */
double calc_ph( double x, double y, double pha, double sigma_charge ) {

    int n_div_x = 100;          // x方向の分割数
    int n_div_y = 100;          // y方向の分割数
    double sum_calcph = 0.0;    // PH計算用
    double x1, y1;              // 擬似ピクセルの座標
    double pi=3.141592;         // 円周率

    // 1. 1つのピクセル100マスに区切る(1マスのことを擬似ピクセルと呼ぶ)
    // 2. 各擬似ピクセルのPHを計算する
    // 3. 全擬似ピクセルのPHの和をピクセルのPHとする
    for ( int i=1 ; i<=n_div_x ; i++ ) {
        for ( int j=1 ; j<=n_div_y ; j++ ) {
            x1 = x + i * 0.01 - 0.005 - 0.5;    // 擬似ピクセルのx座標(x:ピクセルの中心座標)
            y1 = y + j * 0.01 - 0.005 - 0.5;    // 擬似ピクセルのy座標(y:ピクセルの中心座標)
            sum_calcph += exp(-1*( x1*x1 + y1*y1 ) / 2 / sigma_charge / sigma_charge ) / (2*pi*sigma_charge*sigma_charge) / (n_div_x * n_div_y) * pha ;
        }
    }

    return(sum_calcph);

}



/* 標準正規分布(Ave=0,Sigma=1)に従う確率変数を出力する関数 */
// ボックス=ミュラー法を使用
double nrand () {

    static int sw = 0;
    static double r1,r2,s;

    if ( sw == 0 ) {
        sw = 1;
        do {
            r1 = 2.0*drand48()-1.0;       //(drand48():[0.0,1.0)の区間で乱数を発生)*2 -1.0
            r2 = 2.0*drand48()-1.0;       //(drand48():[0.0,1.0)の区間で乱数を発生)*2 -1.0
            s = r1*r1+r2*r2;
        } while ( s>1.0 || s==0.0 );
        s = sqrt(-2.0*log(s)/s);
        return(r1*s);
    }
    else {
        sw = 0;
        return(r2*s);
    }

}



/* Grade 判定 */
int det_grade( double phas_input[9], int spth ) {
    
    int grade_out = 0;
    int phas_pattern = 0;
    int grade_ref[256] = {0, 1, 2, 5, 1, 1, 5, 7, 3, 5, 8, 6, 3, 5, 7, 7, 4, 4, 8, 7, 5, 5, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 1, 1, 2, 5, 1, 1, 5, 7, 5, 7, 7, 7, 5, 7, 7, 7, 4, 4, 8, 7, 5, 5, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 2, 2, 7, 7, 2, 2, 7, 7, 8, 7, 7, 7, 8, 7, 7, 7, 8, 8, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 5, 5, 7, 7, 5, 5, 7, 7, 6, 7, 7, 7, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 1, 1, 2, 5, 1, 1, 5, 7, 3, 5, 8, 6, 3, 5, 7, 7, 5, 5, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 1, 1, 2, 5, 1, 1, 5, 7, 5, 7, 7, 7, 5, 7, 7, 7, 5, 5, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 5, 5, 7, 7, 5, 5, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7};
    
    for ( int a=1 ; a<=8 ; a++ ) {
        if ( phas_input[a] >= spth ) phas_pattern = phas_pattern + pow(2, a-1);
    }

    grade_out = grade_ref[phas_pattern];

    // Grade8はGrade6に変更
    if ( grade_out == 8 ) grade_out = 6;

    return(grade_out);
    
}



/* PHA計算 */
double calc_pha( double phas_input[9], int grade ) {

    double pha_out = 0;

    if ( grade == 0 ) {
        pha_out = phas_input[0];
    }
    else if ( grade == 1 || grade == 5 || grade == 7 ) {
        pha_out = phas_input[0];
    }
    else if ( grade == 2 ) {
        if ( phas_input[2] <= phas_input[7] ) {
            pha_out = phas_input[0] + phas_input[7];
        }
        else {
            pha_out = phas_input[0] + phas_input[2];
        }
    }
    else if ( grade == 3 ) {
        pha_out = phas_input[0] + phas_input[4];
    }
    else if ( grade == 4 ) {
        pha_out = phas_input[0] + phas_input[5];
    }
    else if ( grade == 6 ) {
        if ( phas_input[2] >= phas_input[7] && phas_input[4] >= phas_input[5] ) {
            pha_out = phas_input[0] + phas_input[1] + phas_input[2] + phas_input[4];
        }
        else if ( phas_input[2] >= phas_input[7] && phas_input[4] < phas_input[5] ) {
            pha_out = phas_input[0] + phas_input[2] + phas_input[3] + phas_input[5];
        }
        else if ( phas_input[2] < phas_input[7] && phas_input[4] >= phas_input[5] ) {
            pha_out = phas_input[0] + phas_input[4] + phas_input[6] + phas_input[7];
        }
        else if ( phas_input[2] < phas_input[7] && phas_input[4] < phas_input[5] ) {
            pha_out = phas_input[0] + phas_input[5] + phas_input[7] + phas_input[8];
        }
    }

    return(pha_out);

}



double phas_sum( double phas_input[9] ){
    
    double phas_sum_value = 0.0;
    
    phas_sum_value = phas_input[0] + phas_input[1] + phas_input[2] + phas_input[3] + phas_input[4] + phas_input[5] + phas_input[6] + phas_input[7] + phas_input[8];
    
    return(phas_sum_value);
    
}
