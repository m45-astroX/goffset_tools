/*

    merge_g0_g6_chisq.c
        - G0, G6 のカイ二乗値ファイルをマージするスクリプト
        - 入力ファイルはcalcChiSq4GoffsetPGの生成物

    2025.01.15 v1.0 by Yuma Aoki (Kindai Univ.)

*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define OFFSET_MIN  0.0
#define OFFSET_STEP 0.1
#define OFFSET_MAX  10.0

int read_linenum ( char infile_name[FILENAME_MAX], int file_type );

int main ( int argc, char *argv[] ) {

    int line_num = 0;
    float offset = 0.0;
    char buf[1024];

    // 読み込み用変数
    float g0_noise = 0.0;
    float g0_chisq = 0.0;
    float g6_noise = 0.0;
    float g6_chisq = 0.0;

    char filename_g0[FILENAME_MAX];     // Grade0のカイ二乗値リスト
    char filename_g6[FILENAME_MAX];     // Grade6のカイ二乗値リスト
    char filename_merge[FILENAME_MAX];  // マージ後のファイル
    FILE *fp_g0 = NULL;
    FILE *fp_g6 = NULL;
    FILE *fp_merge = NULL;
    
    // 行数取得
    snprintf(filename_g0, sizeof(filename_g0), "chisq_g0_offset_%04.1f.dat", OFFSET_MIN);
    line_num = read_linenum ( filename_g0, 1 );

    while ( offset <= ( OFFSET_MAX + OFFSET_STEP ) ) {

        // Set file names
        snprintf(filename_g0, sizeof(filename_g0), "chisq_g0_offset_%04.1f.dat", offset);
        snprintf(filename_g6, sizeof(filename_g6), "chisq_g6_offset_%04.1f.dat", offset);
        snprintf(filename_merge, sizeof(filename_merge), "chisq_merge_g06_offset_%04.1f.dat", offset);

        // カイ二乗値の読み込み (行数(ノイズ)を1つづつ増やしていく)
        for (int i=0; i<line_num; i++) {
            
            int j = 0;

            // Open files
            fp_g0 = fopen(filename_g0, "r");
            if ( fp_g0 == NULL ) {
                fprintf(stderr, "*** Error\n");
                fprintf(stderr, "Can not open infile (%s)\n", filename_g0);
                fprintf(stderr, "abort\n");
                exit(0);
            }
            fp_g6 = fopen(filename_g6, "r");
            if ( fp_g6 == NULL ) {
                fprintf(stderr, "*** Error\n");
                fprintf(stderr, "Can not open infile (%s)\n", filename_g6);
                fprintf(stderr, "abort\n");
                exit(0);
            }
            fp_merge = fopen(filename_merge, "a");
            if ( fp_merge == NULL ) {
                fprintf(stderr, "*** Error\n");
                fprintf(stderr, "Can not open infile (%s)\n", filename_merge);
                fprintf(stderr, "abort\n");
                exit(0);
            }

            // Grade 0
            j = 0;
            while ( fgets( buf, sizeof(buf), fp_g0 ) != NULL ) {
                
                if( sscanf( buf, "%f %f", &g0_noise, &g0_chisq ) != 2 ) {
                    continue;
                }

                if ( i == j ) {
                    break;
                }
                else {
                    j ++;
                    continue;
                }

            }
            // Grade 6
            j = 0;
            while ( fgets( buf, sizeof(buf), fp_g6 ) != NULL ) {

                if( sscanf( buf, "%f %f", &g6_noise, &g6_chisq ) != 2 ) {
                    continue;
                }

                if ( i == j ) {
                    break;
                }
                else {
                    j ++;
                    continue;
                }

            }

            // Merge
            if ( g0_noise == g6_noise ) {
                fprintf(fp_merge, "%f %f\n", g0_noise, g0_chisq+g6_chisq);
            }
            else {
                // If the noise matchs 
                fprintf(stderr, "*** Error\n");
                fprintf(stderr, "g0_noise != g6_noise\n");
                fprintf(stderr, "line_num = %d\n", i);
                return -1;
            }

            // Close files
            fclose(fp_g0);
            fclose(fp_g6);
            fclose(fp_merge);

        }

        // インクリメント
        offset = offset + OFFSET_STEP;

    }
    
    return 0;

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

        if ( file_type == 1 && sscanf( buf_, "%f %f", &readvalue_[0], &readvalue_[1]) == 2 ) {
            line_num ++;
        }
        else if ( file_type == 2 && sscanf( buf_, "%f %s %f %f %f %f %f %f %f %f", &readvalue_[0], readvalue_char_, &readvalue_[2], &readvalue_[3], &readvalue_[4], &readvalue_[5], &readvalue_[6], &readvalue_[7], &readvalue_[8], &readvalue_[9] ) == 10 ) {
            line_num ++;
        }

    }

    fclose(fp_infile);

    return line_num;

}

