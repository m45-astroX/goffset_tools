/*

    mkSpec_PHA

    2024.08.02 v1.0 by Yuma Aoki (Kindai Univ.)

*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "fitsio.h"

int main ( int argc, char *argv[] ) {

    if ( argc != 3 ) {
        fprintf(stderr, "Usage : ./mkSpec_PHA evtfile outfile\n");
        return -1;
    }

    /* Variables */
    int status = 0;
    int colnum = 0;
    long N_row = 0;
    long width = 0;
    long repeat = 0;
    int nulval = 0;
    int anynul = 0;
    int hdutype = 0;
    int datatype_PHA = 0;
    signed short read_PHA = 0;
    long spec[4096];
    char evtfile_path[FLEN_FILENAME];
    char outfile_path[FLEN_FILENAME];
    sprintf(evtfile_path, "%s", argv[1]);
    sprintf(outfile_path, "%s", argv[2]);

    /* Reset */
    for (long i=0; i<4096; i++) {
        spec[i] = 0;
    }

    /* Files */
    fitsfile *fp_evtfile = NULL;
    if ( fits_open_file(&fp_evtfile, evtfile_path, READONLY, &status) != 0 ) {
        fprintf(stderr, "Can not open evtfile (%s) status=%d\n", evtfile_path, status);
        fprintf(stderr, "abort\n");
        return -1;
    }
    FILE *fp_outfile = NULL;
    fp_outfile = fopen(outfile_path, "w");
    if ( fp_outfile == NULL ) {
        fprintf(stderr, "Can not open outfile (%s)\n", outfile_path);
        fprintf(stderr, "abort\n");
        return -1;
    }
    
    // Move HDU
    fits_movabs_hdu(fp_evtfile, 2, &hdutype, &status);
    // Get colnum of PHA
    fits_get_colnum(fp_evtfile, CASESEN, "PHA", &colnum, &status);
    // Get datatype of PHA
    fits_get_coltype(fp_evtfile, colnum, &datatype_PHA, &repeat, &width, &status);
    // Get rownum
    fits_get_num_rows(fp_evtfile, &N_row, &status);

    // Loop
    for (long i=1; i<=N_row; i++) {
        
        // Read PHA
        fits_read_col(fp_evtfile, datatype_PHA, colnum, i, 1, 1, &nulval, &read_PHA, &anynul, &status);

        // Make spec
        if ( 0 <= read_PHA && read_PHA <= 4095 ) {
            spec[read_PHA] ++;
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
