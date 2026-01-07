/*

    calcChisq4GoffsetPG

    2024.08.29 v1.0 by Yuma Aoki (Kindai Univ.)

*/

//#define DEBUG
#define DEBUG_2ND
#define CHISQUARE_INIT 10000000.0

#include <stdio.h>
#include <stdlib.h>

float goffset ( float a, float b, float c, float PHA );

int main ( int argc, char *argv[] ) {

    if ( argc != 6 ) {
        fprintf(stdout, "Usage : ./calcChisq4GoffsetPG\n");
        fprintf(stdout, "    $1 SIMDBfile : The simulation database file\n");
        fprintf(stdout, "    $2 SIMDBfile linenum : The line number of the simulation database file\n");
        fprintf(stdout, "    $3 obsdatafile : The observation file\n");
        fprintf(stdout, "    $4 obsdatafile linenum : The line number of the observation file\n");    
        fprintf(stdout, "    $5 outfile\n");
        return -1;
    }

    /* Variables */
    int linenum_increment_simdbfile = 0;
    int linenum_simbdfile = 0;
    int linenum_increment_obsdata = 0;
    int linenum_obsdatafile = 0;
    char buf[4096];
    float chiSquare = 0.0;
    float readvalue[7];
    float simdb_goffset = 0.0;
    float *simdb_noise = NULL;
    float *simdb_a = NULL;
    float *simdb_b = NULL;
    float *simdb_c = NULL;
    float *simdb_a_err = NULL;
    float *simdb_b_err = NULL;
    float *simdb_c_err = NULL;
    float *obsdata_PHA = NULL;
    float *obsdata_PHA_err = NULL;
    float *obsdata_goffset = NULL;
    float *obsdata_goffset_err = NULL;
    char simdbfile_fullpath[FILENAME_MAX];
    char obsdatafile_fullpath[FILENAME_MAX];
    char outfile_fullpath[FILENAME_MAX];

    /* Arguments */
    snprintf(simdbfile_fullpath, sizeof(simdbfile_fullpath), "%s", argv[1]);
    linenum_simbdfile = atoi(argv[2]);
    snprintf(obsdatafile_fullpath, sizeof(obsdatafile_fullpath), "%s", argv[3]);
    linenum_obsdatafile = atoi(argv[4]);
    snprintf(outfile_fullpath, sizeof(outfile_fullpath), "%s", argv[5]);

    /* Malloc */
    simdb_noise = (float*) malloc (sizeof(float) * linenum_simbdfile);
    simdb_a = (float*) malloc (sizeof(float) * linenum_simbdfile);
    simdb_b = (float*) malloc (sizeof(float) * linenum_simbdfile);
    simdb_c = (float*) malloc (sizeof(float) * linenum_simbdfile);
    simdb_a_err = (float*) malloc (sizeof(float) * linenum_simbdfile);
    simdb_b_err = (float*) malloc (sizeof(float) * linenum_simbdfile);
    simdb_c_err = (float*) malloc (sizeof(float) * linenum_simbdfile);
    obsdata_PHA = (float*) malloc (sizeof(float) * linenum_obsdatafile);
    obsdata_PHA_err = (float*) malloc (sizeof(float) * linenum_obsdatafile);
    obsdata_goffset = (float*) malloc (sizeof(float) * linenum_obsdatafile);
    obsdata_goffset_err = (float*) malloc (sizeof(float) * linenum_obsdatafile);

    /* Files */
    // SIMDB
    FILE *fp_simdb = NULL;
    fp_simdb = fopen(simdbfile_fullpath, "r");
    if ( fp_simdb == NULL ) {
        fprintf(stderr, "*** Error\n");
        fprintf(stderr, "Can not open SIMDB file (%s)\n", simdbfile_fullpath);
        fprintf(stderr, "abort\n");
        return -1;
    }
    // Observation file
    FILE *fp_obsdata = NULL;
    fp_obsdata = fopen(obsdatafile_fullpath, "r");
    if ( fp_obsdata == NULL ) {
        fprintf(stderr, "*** Error\n");
        fprintf(stderr, "Can not open obsdatafile (%s)\n", obsdatafile_fullpath);
        fprintf(stderr, "abort\n");
        return -1;
    }
    // Observation file
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

        // SIMDB format : noise a a_err b b_err c c_err
        if( sscanf( buf, "%f %f %f %f %f %f %f", &readvalue[0], &readvalue[1], &readvalue[2], &readvalue[3], &readvalue[4], &readvalue[5], &readvalue[6] ) != 7 ) {
            continue;
        }
        
        simdb_noise[linenum_increment_simdbfile] = readvalue[0];
        simdb_a[linenum_increment_simdbfile] = readvalue[1];
        simdb_a_err[linenum_increment_simdbfile] = readvalue[2];
        simdb_b[linenum_increment_simdbfile] = readvalue[3];
        simdb_b_err[linenum_increment_simdbfile] = readvalue[4];
        simdb_c[linenum_increment_simdbfile] = readvalue[5];
        simdb_c_err[linenum_increment_simdbfile] = readvalue[6];

        #ifdef DEBUG
        /*
        fprintf(stdout, "simdb_noise[%d] = %f\n", linenum_increment_simdbfile, simdb_noise[linenum_increment_simdbfile]);
        fprintf(stdout, "simdb_a[%d] = %f\n", linenum_increment_simdbfile, simdb_a[linenum_increment_simdbfile]);
        fprintf(stdout, "simdb_a_err[%d] = %f\n", linenum_increment_simdbfile, simdb_a_err[linenum_increment_simdbfile]);
        fprintf(stdout, "simdb_b[%d] = %f\n", linenum_increment_simdbfile, simdb_b[linenum_increment_simdbfile]);
        fprintf(stdout, "simdb_b_err[%d] = %f\n", linenum_increment_simdbfile, simdb_b_err[linenum_increment_simdbfile]);
        fprintf(stdout, "simdb_c[%d] = %f\n", linenum_increment_simdbfile, simdb_c[linenum_increment_simdbfile]);
        fprintf(stdout, "simdb_c_err[%d] = %f\n", linenum_increment_simdbfile, simdb_c_err[linenum_increment_simdbfile]);
        fprintf(stdout, "\n");
        */
        #endif

        linenum_increment_simdbfile ++;

    }

    /* Print information of the input data */
    #ifdef DEBUG
    fprintf(stdout, "Observation data\n");
    fprintf(stdout, "  Inputed data number = %d\n", linenum_obsdatafile);
    fprintf(stdout, "  Read data number = %d\n", linenum_increment_obsdata);
    fprintf(stdout, "SIMDB\n");
    fprintf(stdout, "  Inputed data number = %d\n", linenum_simbdfile);
    fprintf(stdout, "  Read data number = %d\n", linenum_increment_simdbfile);
    fprintf(stdout, "\n");
    #endif

    /* Chi-square test  */
    // シミュレーションデータセットを1つずつ観測データと比較していく
    // i: シミュレーションのインクリメント
    // j: 観測データのインクリメント

    for (int i=0; i<linenum_increment_simdbfile; i++) {
        
        // Reset variables
        chiSquare = 0.0;

        for (int j=0; j<linenum_increment_obsdata; j++) {
            
            simdb_goffset = goffset(simdb_a[i], simdb_b[i], simdb_c[i], obsdata_PHA[j]);

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


float goffset ( float a, float b, float c, float PHA ) {

    float goffset = 0.0;
    float ph_si_edge = 306.5;
    float ph_upper = 2000.0;

    if ( PHA < ph_si_edge ) {
        goffset = a * ( PHA - 306.5 ) * ( PHA - 306.5 ) + b * ( PHA - 306.5 ) + c;
    }
    else if ( ph_si_edge <= PHA && PHA < ph_upper ) {
        goffset = b * ( PHA - 306.5 ) + c;
    }
    else {
        goffset = b * ( ph_upper - 306.5 ) + c;
    }

    return goffset;

}
