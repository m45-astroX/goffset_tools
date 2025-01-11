/*

    mkSpec_PHASSUM_GOODGRADE

    2024.08.02 v1.0 by Yuma Aoki (Kindai Univ.)
    2024.10.02 v2.0 by Yuma Aoki (Kindai Univ.)
        - Description
            v1.0ではdouble型のPHASをint型に変換してからint型のPHAS_SUMに加算していたが、
            正しくはPHAS_SUMをdouble型で計算し、最後にint型に変換しなければならない

*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "fitsio.h"

int main ( int argc, char *argv[] ) {

    /* Variables */
    int status = 0;
    long N_row = 0;
    int colnum_PHAS = 0;
    int colnum_GRADE = 0;
    long width_PHAS = 0;
    long width_GRADE = 0;
    long repeat_PHAS = 0;
    long repeat_GRADE = 0;
    int nulval = 0;
    int anynul = 0;
    int hdutype = 0;
    int datatype_PHAS = 0;
    int datatype_GRADE = 0;
    signed short read_GRADE;
    signed short read_PHAS_s[9];
    double PHAS_SUM = 0.0;
    double read_PHAS_d[9];
    long spec[4096];
    char evtfile_path[FLEN_FILENAME];
    char outfile_path[FLEN_FILENAME];
    char phas_col_name[1024];

    /* Arguments */
    if ( argc != 3 && argc != 4 ) {
        fprintf(stderr, "Usage : ./mkSpec_PHASSUM_GOODGRADE evtfile outfile (PHAScol; optional)\n");
        fprintf(stderr, "    PHAScol : PHAS column to be used to calculate PHAS_SUM\n");
        fprintf(stderr, "              Default value is set to PHAS_CTICORR\n");
        fprintf(stderr, "              Users can set the value as shown below...\n");
        fprintf(stderr, "              ( PHAS / PHAS_EVENODD / PHAS_TRAILCORR / PHAS_CTICORR )\n");
        return -1;
    }
    else if ( argc == 3 ) {
        snprintf(evtfile_path, sizeof(evtfile_path), "%s", argv[1]);
        snprintf(outfile_path, sizeof(outfile_path), "%s", argv[2]);
        snprintf(phas_col_name, sizeof(phas_col_name), "PHAS_CTICORR");
    }
    else if ( argc == 4 ) {
        snprintf(evtfile_path, sizeof(evtfile_path), "%s", argv[1]);
        snprintf(outfile_path, sizeof(outfile_path), "%s", argv[2]);
        snprintf(phas_col_name, sizeof(phas_col_name), "%s", argv[3]);
        // Check the phas_col_name
        if ( strcmp(phas_col_name,"PHAS")!=0 && strcmp(phas_col_name,"PHAS_EVENODD")!=0 && strcmp(phas_col_name,"PHAS_TRAILCORR")!=0 && strcmp(phas_col_name,"PHAS_CTICORR")!=0 ) {
            fprintf(stderr, "*** Error\n");
            fprintf(stderr, "PHAScol ($3) must be set to as shown below\n");
            fprintf(stderr, "( PHAS / PHAS_EVENODD / PHAS_TRAILCORR / PHAS_CTICORR )\n");
            return -1;
        }
    }

    /* Reset */
    for (long i=0; i<4096; i++) {
        spec[i] = 0;
    }

    /* Files */
    fitsfile *fp_evtfile = NULL;
    if ( fits_open_file(&fp_evtfile, evtfile_path, READONLY, &status) != 0 ) {
        fprintf(stderr, "*** Error\n");
        fprintf(stderr, "Can not open eventfile (%s) status=%d\n", evtfile_path, status);
        fprintf(stderr, "abort\n");
        return -1;
    }
    FILE *fp_outfile = NULL;
    fp_outfile = fopen(outfile_path, "w");
    if ( fp_outfile == NULL ) {
        fprintf(stderr, "*** Error\n");
        fprintf(stderr, "Can not open outfile (%s)\n", outfile_path);
        fprintf(stderr, "abort\n");
        return -1;
    }
    
    // Move HDU
    fits_movabs_hdu(fp_evtfile, 2, &hdutype, &status);
    // Check status
    if ( status != 0 ) {
        fprintf(stderr, "*** Error\n");
        fprintf(stderr, "Failed to move HDU\n");
        fprintf(stderr, "status = %d\n", status);
        return -1;
    }
    // Get colnum of PHAS and Grade
    fits_get_colnum(fp_evtfile, CASESEN, "GRADE", &colnum_GRADE, &status);
    fits_get_colnum(fp_evtfile, CASESEN, phas_col_name, &colnum_PHAS, &status);
    // Check status
    if ( status != 0 ) {
        fprintf(stderr, "*** Error\n");
        fprintf(stderr, "Failed to get the colnum\n");
        fprintf(stderr, "status = %d\n", status);
        return -1;
    }
    // Get datatype of PHAS and Grade
    fits_get_coltype(fp_evtfile, colnum_PHAS, &datatype_PHAS, &repeat_PHAS, &width_PHAS, &status);
    fits_get_coltype(fp_evtfile, colnum_GRADE, &datatype_GRADE, &repeat_GRADE, &width_GRADE, &status);
    // Get row number
    fits_get_num_rows(fp_evtfile, &N_row, &status);

    // Loop
    for (long i=1; i<=N_row; i++) {
        
        // Read Grade
        fits_read_col(fp_evtfile, datatype_GRADE, colnum_GRADE, i, 1, repeat_GRADE, &nulval, &read_GRADE, &anynul, &status);

        // Grade filtering
        if ( read_GRADE != 0 && read_GRADE != 2 && read_GRADE != 3 && read_GRADE != 4 && read_GRADE != 6 ) {
            continue;
        }

        // Read PHAS
        if ( datatype_PHAS == TSHORT ) {
            fits_read_col(fp_evtfile, datatype_PHAS, colnum_PHAS, i, 1, repeat_PHAS, &nulval, read_PHAS_s, &anynul, &status);
        }
        else if ( datatype_PHAS == TDOUBLE ) {
            fits_read_col(fp_evtfile, datatype_PHAS, colnum_PHAS, i, 1, repeat_PHAS, &nulval, read_PHAS_d, &anynul, &status);
        }
        else {
            fprintf(stderr, "*** Error\n");
            fprintf(stderr, "Datatype of PHAS is neither TSHORT nor TDOUBLE\n");
            fprintf(stderr, "abort\n");
            return -1;
        }

        // Calculate PHAS_SUM
        PHAS_SUM = 0.0;
        for (int j=0; j<9; j++) {
            if ( datatype_PHAS == TSHORT ) {
                PHAS_SUM += (double)read_PHAS_s[j];
            }
            else {
                PHAS_SUM += read_PHAS_d[j];
            }
        }
        
        // Make spectrum
        if ( 0 <= (int)(PHAS_SUM + 0.5) && (int)(PHAS_SUM + 0.5) <= 4095 ) {
            spec[(int)(PHAS_SUM + 0.5)] ++;
        }
        else {
            continue;
        }

    }

    /* Print result */
    for (int i=0; i<4096; i++) {
        fprintf(fp_outfile, "%d %ld\n", i, spec[i]);
    }

    /* fclose */
    fclose(fp_outfile);
    fits_close_file(fp_evtfile, &status);

    return 0;

}
