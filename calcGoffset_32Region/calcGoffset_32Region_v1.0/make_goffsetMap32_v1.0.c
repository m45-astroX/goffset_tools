/*

    make_goffsetMap32

    2023.12.15 v1.0 by Yuma Aoki 

*/

#include "stdio.h"
#include "stdlib.h"
#include "fitsio.h"

#define MAPSIZE_X 4
#define MAPSIZE_Y 8

int main ( int argc, char *argv[] ) {

    if ( argc != 3 ) {
        fprintf(stderr, "Usage : ./make_goffsetMap32 infile(ascii) outfile(fits)\n");
        return -1;
    }

    int x_in = 0;
    int y_in = 0;
    float value_in = 0.0;
    float map[MAPSIZE_Y][MAPSIZE_X];
    char buf[256];

    int status = 0;
    int naxis = 2;
    long naxes[2] = { 4, 8 };
    int fpixel = 1;
    char infile_path[FILENAME_MAX];
    char outfile_path[FILENAME_MAX];
    long nelements = naxes[0] * naxes[1];

    FILE *fp_infile = NULL;
    fitsfile *fp_outfile = NULL;

    // datafile (in)
    snprintf(infile_path, sizeof(infile_path), "%s", argv[1]);
    fp_infile = fopen(infile_path, "r");
    if ( fp_infile == NULL ) {
        fprintf(stderr, "infile open error (%s)\n", infile_path);
        return -1;
    }

    // fitsfile (out)
    fits_create_file(&fp_outfile, argv[2], &status);
    fits_create_img(fp_outfile, FLOAT_IMG, naxis, naxes, &status);
    if ( status != 0 ) {
        fprintf(stderr, "outfile make error (%s)\n", outfile_path);
        return -1;
    }

    while ( fgets(buf, sizeof(buf), fp_infile) != NULL ) {
        
        if( sscanf(buf, "%d %d %f", &x_in, &y_in, &value_in) != 3 ) {
            continue;
        }

        if ( x_in < 0 || MAPSIZE_X <= x_in ) {
            fprintf(stderr, "x_in is out of range (%d)\n", x_in);
            continue;
        }
        if ( y_in < 0 || MAPSIZE_Y <= y_in ) {
            fprintf(stderr, "y_in is out of range (%d)\n", y_in);
            continue;
        }
        printf("%d %d %f\n", x_in, y_in, value_in);
        map[y_in][x_in] = value_in;

    }

    fits_write_img(fp_outfile, TFLOAT, fpixel, nelements, map[0], &status);

    fits_close_file(fp_outfile, &status);
    
    fits_report_error(stderr, status);
    
    return( status );

}


