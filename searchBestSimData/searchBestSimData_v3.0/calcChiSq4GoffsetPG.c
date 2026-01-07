/*

    calcChisq4GoffsetPG

    実データとシミュレーションデータのGoffsetのカイ二乗を計算する

    2024.08.29 v1.0 by Yuma Aoki (Kindai Univ.)
    2024.12.13 v2.0 by Yuma Aoki (Kindai Univ.)
        - SIMDBのフォーマット変更に伴う修正
            - 関数goffsetを修正
        - 引数の変更
    
*/

//#define DEBUG
#define CHISQUARE_INIT 1000000000.0

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Goffsetを計算する関数 */
float goffset ( float **a_, float **b_, float **c_, float *PHA_, int specified_simdataset_num, int specified_obsdata_num , float simdb_offset_ );

/* ファイルの行数をカウントする関数 */
int read_linenum ( char infile_name[FILENAME_MAX], int file_type );

int main ( int argc, char *argv[] ) {

    if ( argc != 5 ) {
        fprintf(stdout, "Usage : ./calcChisq4GoffsetPG\n");
        fprintf(stdout, "    $1 obsdatafile : The observation file\n");
        fprintf(stdout, "    $2 SIMDBfile : The simulation database file\n");
        fprintf(stdout, "    $3 Simlation data offset (ch)\n");
        fprintf(stdout, "    $4 outfile\n");
        return -1;
    }
    
    /* Variables */
    int range = 0;      // Goffset補正関数の範囲を指定する変数(LOW, MID, or HIG)
    int linenum_simbdfile = 0;              // SIMDBファイルの行数
    int linenum_increment_simdbfile = 0;    // SIMDBファイルの行数カウント
    int simdataset_num = 0;                 // SIMDBのデータセット数(LOW, MID, HIG合わせて1つのデータセットとみなす)
    int simdataset_increment_num = 0;       // SIMDBのデータセット数カウント
    int linenum_obsdatafile = 0;            // ObsDataファイルの行数
    int linenum_increment_obsdata = 0;      // ObsDataファイルの行数カウント
    
    // データ読み込み用変数
    char buf[4096];
    char readvalue_char[1024];
    float readvalue[10];

    // 計算用変数
    float chiSquare = 0.0;
    float simdb_goffset = 0.0;
    float simdb_offset = 0.0;
    float *simdb_noise = NULL;
    float **simdb_a = NULL;
    float **simdb_b = NULL;
    float **simdb_c = NULL;
    float **simdb_a_err = NULL;
    float **simdb_b_err = NULL;
    float **simdb_c_err = NULL;
    float *obsdata_PHA = NULL;
    float *obsdata_PHA_err = NULL;
    float *obsdata_goffset = NULL;
    float *obsdata_goffset_err = NULL;

    // Files
    char simdbfile_fullpath[FILENAME_MAX];
    char obsdatafile_fullpath[FILENAME_MAX];
    char outfile_fullpath[FILENAME_MAX];

    /* Arguments */
    snprintf(obsdatafile_fullpath, sizeof(obsdatafile_fullpath), "%s", argv[1]);
    snprintf(simdbfile_fullpath, sizeof(simdbfile_fullpath), "%s", argv[2]);
    snprintf(outfile_fullpath, sizeof(outfile_fullpath), "%s", argv[4]);
    simdb_offset = atof(argv[3]);
    linenum_obsdatafile = read_linenum (obsdatafile_fullpath, 1);
    linenum_simbdfile = read_linenum (simdbfile_fullpath, 2);
    if ( simdataset_num % 3 != 0 ) {
        fprintf(stderr, "*** Error\n");
        fprintf(stderr, "The number of rows in the SIMDB file must be divisible by 3.\n");
        fprintf(stderr, "Because the functions LOW, MID, and HIG exist as a set.\n");
        return -1;
    }
    else {
        simdataset_num = linenum_simbdfile / 3;
    }

    /* Malloc */
    simdb_noise = (float*) malloc (sizeof(float) * simdataset_num);
    simdb_a = (float**) malloc (sizeof(float*) * 3);    // LOW, MID and HIG
    for (int i=0; i<3; i++) {
        simdb_a[i] = (float*) malloc (sizeof(float) * simdataset_num);
    }
    simdb_b = (float**) malloc (sizeof(float*) * 3);
    for (int i=0; i<3; i++) {
        simdb_b[i] = (float*) malloc (sizeof(float) * simdataset_num);
    }
    simdb_c = (float**) malloc (sizeof(float*) * 3);
    for (int i=0; i<3; i++) {
        simdb_c[i] = (float*) malloc (sizeof(float) * simdataset_num);
    }
    simdb_a_err = (float**) malloc (sizeof(float*) * 3);
    for (int i=0; i<3; i++) {
        simdb_a_err[i] = (float*) malloc (sizeof(float) * simdataset_num);
    }
    simdb_b_err = (float**) malloc (sizeof(float*) * 3);
    for (int i=0; i<3; i++) {
        simdb_b_err[i] = (float*) malloc (sizeof(float) * simdataset_num);
    }
    simdb_c_err = (float**) malloc (sizeof(float*) * 3);
    for (int i=0; i<3; i++) {
        simdb_c_err[i] = (float*) malloc (sizeof(float) * simdataset_num);
    }
    obsdata_PHA = (float*) malloc (sizeof(float) * linenum_obsdatafile);
    obsdata_PHA_err = (float*) malloc (sizeof(float) * linenum_obsdatafile);
    obsdata_goffset = (float*) malloc (sizeof(float) * linenum_obsdatafile);
    obsdata_goffset_err = (float*) malloc (sizeof(float) * linenum_obsdatafile);

    /* Files */
    // Observation file
    FILE *fp_obsdata = NULL;
    fp_obsdata = fopen(obsdatafile_fullpath, "r");
    if ( fp_obsdata == NULL ) {
        fprintf(stderr, "*** Error\n");
        fprintf(stderr, "Can not open obsdatafile (%s)\n", obsdatafile_fullpath);
        fprintf(stderr, "abort\n");
        return -1;
    }
    // SIMDB
    FILE *fp_simdb = NULL;
    fp_simdb = fopen(simdbfile_fullpath, "r");
    if ( fp_simdb == NULL ) {
        fprintf(stderr, "*** Error\n");
        fprintf(stderr, "Can not open SIMDB file (%s)\n", simdbfile_fullpath);
        fprintf(stderr, "abort\n");
        return -1;
    }
    // Out file
    FILE *fp_outfile = NULL;
    fp_outfile = fopen(outfile_fullpath, "w");
    if ( fp_outfile == NULL ) {
        fprintf(stderr, "*** Error\n");
        fprintf(stderr, "Can not open outfile (%s)\n", outfile_fullpath);
        fprintf(stderr, "abort\n");
        return -1;
    }

    /* Read the observation file */
    linenum_increment_obsdata = 0;
    while ( fgets( buf, sizeof(buf), fp_obsdata ) != NULL ) {

        if ( linenum_increment_obsdata >= linenum_obsdatafile ) {
            fprintf(stdout, "*** Notice\n");
            fprintf(stdout, "linenum_increment_obsdata exceeds linenum_obsdatafile\n");
            fprintf(stdout, "--> Exit loop\n");
            break;
        }

        // The format of obsdatafile
        //    $1(0) : GC_PHASSUM_GOODGRADE
        //    $2(1) : GC_PHASSUM_GOODGRADE_ERR
        //    $3(2) : GC_PHA
        //    $4(3) : GC_PHA_ERR
        //    $5(4) : GOFFSET
        //    $6(5) : GOFFSET_ERR
        if( sscanf( buf, "%f %f %f %f %f %f", &readvalue[0], &readvalue[1], &readvalue[2], &readvalue[3], &readvalue[4], &readvalue[5] ) != 6 ) {
            continue;
        }

        obsdata_PHA[linenum_increment_obsdata] = readvalue[2];
        obsdata_PHA_err[linenum_increment_obsdata] = readvalue[3];
        obsdata_goffset[linenum_increment_obsdata] = readvalue[4];
        obsdata_goffset_err[linenum_increment_obsdata] = readvalue[5];
        
        linenum_increment_obsdata ++;

    }

    /* Read the simdb file */
    linenum_increment_simdbfile = 0;
    while ( fgets( buf, sizeof(buf), fp_simdb ) != NULL ) {
        
        if ( linenum_increment_simdbfile >= linenum_simbdfile ) {
            fprintf(stdout, "*** Notice\n");
            fprintf(stdout, "linenum_increment_simdbfile exceeds linenum_simbdfile\n");
            fprintf(stdout, "--> Exit loop\n");
            break;
        }

        // SIMDB format
        //    $1(0) : noise
        //    $2(1) : range
        //    $3(2) : CUBIC (Not supported)
        //    $4(3) : CUBIC_err (Not supported)
        //    $5(4) : a
        //    $6(5) : a_err
        //    $7(6) : b
        //    $8(7) : b_err
        //    $9(8) : c 
        //    $10(9) : c_err
        if( sscanf( buf, "%f %s %f %f %f %f %f %f %f %f", &readvalue[0], readvalue_char, &readvalue[2], &readvalue[3], &readvalue[4], &readvalue[5], &readvalue[6], &readvalue[7], &readvalue[8], &readvalue[9] ) != 10 ) {
            continue;
        }
        
        // Check function range
        if ( strcmp(readvalue_char, "LOW") == 0 ) range = 0;
        else if ( strcmp(readvalue_char, "MID") == 0 ) range = 1;
        else if ( strcmp(readvalue_char, "HIG") == 0 ) range = 2;
        else {
            fprintf(stdout, "*** Notice\n");
            fprintf(stdout, "SIMDB format error.\n");
            fprintf(stdout, "$2 must be LOW, MID or HIG.\n");
            fprintf(stdout, "However, $2 is %s.\n", readvalue_char);
            fprintf(stdout, "\nDump\n");
            fprintf(stdout, "linenum_increment_simdbfile = %d\n", linenum_increment_simdbfile);
            fprintf(stdout, "--> Exit loop\n");
            break;
        }
        
        simdb_noise[simdataset_increment_num] = readvalue[0];
        simdb_a[range][simdataset_increment_num] = readvalue[4];
        simdb_a_err[range][simdataset_increment_num] = readvalue[5];
        simdb_b[range][simdataset_increment_num] = readvalue[6];
        simdb_b_err[range][simdataset_increment_num] = readvalue[7];
        simdb_c[range][simdataset_increment_num] = readvalue[8];
        simdb_c_err[range][simdataset_increment_num] = readvalue[9];

        #ifdef DEBUG
        fprintf(stdout, "\n");
        fprintf(stdout, "DEBUG:: linenum_increment_simdbfile = %d\n", linenum_increment_simdbfile);
        fprintf(stdout, "DEBUG:: simdataset_increment_num    = %d\n", simdataset_increment_num);
        fprintf(stdout, "DEBUG:: \n");
        fprintf(stdout, "DEBUG:: READ DATA\n");
        fprintf(stdout, "DEBUG:: simdb_noise[%d] = %f\n", simdataset_increment_num, simdb_noise[simdataset_increment_num]);
        fprintf(stdout, "DEBUG:: simdb_a[%d][%d] = %f\n", range, simdataset_increment_num, simdb_a[range][simdataset_increment_num]);
        fprintf(stdout, "DEBUG:: simdb_a_err[%d][%d] = %f\n", range, simdataset_increment_num, simdb_a_err[range][simdataset_increment_num]);
        fprintf(stdout, "DEBUG:: simdb_b[%d][%d] = %f\n", range, simdataset_increment_num, simdb_b[range][simdataset_increment_num]);
        fprintf(stdout, "DEBUG:: simdb_b_err[%d][%d] = %f\n", range, simdataset_increment_num, simdb_b_err[range][simdataset_increment_num]);
        fprintf(stdout, "DEBUG:: simdb_c[%d][%d] = %f\n", range, simdataset_increment_num, simdb_c[range][simdataset_increment_num]);
        fprintf(stdout, "DEBUG:: simdb_c_err[%d][%d] = %f\n", range, simdataset_increment_num, simdb_c_err[range][simdataset_increment_num]);
        fprintf(stdout, "\n");
        #endif

        linenum_increment_simdbfile ++;
        if ( linenum_increment_simdbfile % 3 == 0 ) {
            simdataset_increment_num ++;
        }

    }

    /* Chi-square test  */
    // シミュレーションデータセットを1つずつ観測データと比較していく
    // i: シミュレーションのインクリメント
    // j: 観測データのインクリメント
    for (int i=0; i<simdataset_num; i++) {
        
        // Reset variables
        chiSquare = 0.0;

        for (int j=0; j<linenum_increment_obsdata; j++) {
            
            simdb_goffset = goffset( simdb_a, simdb_b, simdb_c, obsdata_PHA, i, j, simdb_offset );

            chiSquare += ( ( obsdata_goffset[j] - simdb_goffset ) / obsdata_goffset_err[j] ) * ( ( obsdata_goffset[j] - simdb_goffset ) / obsdata_goffset_err[j] );

        }

        /* Print results */
        fprintf(fp_outfile, "%f %f\n", simdb_noise[i], chiSquare);

    }

    /* Free memories */
    free(simdb_noise);
    free(simdb_a);
    free(simdb_b);
    free(simdb_c);
    free(simdb_a_err);
    free(simdb_b_err);
    free(simdb_c_err);
    free(obsdata_PHA);
    free(obsdata_PHA_err);
    free(obsdata_goffset);
    free(obsdata_goffset_err);

    /* Close files */
    fclose(fp_outfile);
    fclose(fp_simdb);
    fclose(fp_obsdata);

    return 0;
}


float goffset ( float **a_, float **b_, float **c_, float *PHA_, int specified_simdataset_num, int specified_obsdata_num, float simdb_offset_ ) {

    int range_ = -1;
    float ph_bound_lower = 306.5;
    float ph_bound_higher = 2000.0;

    if ( PHA_[specified_obsdata_num] < ph_bound_lower ) range_ = 0;
    else if ( ph_bound_lower <= PHA_[specified_obsdata_num] && PHA_[specified_obsdata_num] < ph_bound_higher ) range_ = 1;
    else if ( ph_bound_lower <= PHA_[specified_obsdata_num] && PHA_[specified_obsdata_num] < ph_bound_higher ) range_ = 2;
    else {
        fprintf(stderr, "*** Error\n");
        fprintf(stderr, "function::goffset");
        fprintf(stdout, "abort.");
        exit(0);
    }

    // Return goffset
    return a_[range_][specified_simdataset_num] * PHA_[specified_obsdata_num] * PHA_[specified_obsdata_num] + b_[range_][specified_simdataset_num] * PHA_[specified_obsdata_num] + c_[range_][specified_simdataset_num] + simdb_offset_;

}


int read_linenum ( char infile_name[FILENAME_MAX], int file_type ) {

    int line_num = 0;
    char buf_[4096];
    char readvalue_char_[1024];
    float readvalue_[10];

    FILE *fp_infile = NULL;
    fp_infile = fopen(infile_name, "r");
    if ( fp_infile == NULL ) {
        fprintf(stderr, "*** Error\n");
        fprintf(stderr, "function:read_linenum");
        fprintf(stderr, "Can not open infile (%s)\n", infile_name);
        fprintf(stderr, "abort\n");
        exit(0);
    }

    while ( fgets( buf_, sizeof(buf_), fp_infile ) != NULL ) {

        if ( file_type == 1 && sscanf( buf_, "%f %f %f %f %f %f", &readvalue_[0], &readvalue_[1], &readvalue_[2], &readvalue_[3], &readvalue_[4], &readvalue_[5] ) == 6 ) {
            line_num ++;
        }
        else if ( file_type == 2 && sscanf( buf_, "%f %s %f %f %f %f %f %f %f %f", &readvalue_[0], readvalue_char_, &readvalue_[2], &readvalue_[3], &readvalue_[4], &readvalue_[5], &readvalue_[6], &readvalue_[7], &readvalue_[8], &readvalue_[9] ) == 10 ) {
            line_num ++;
        }

    }

    fclose(fp_infile);

    return line_num;

}
