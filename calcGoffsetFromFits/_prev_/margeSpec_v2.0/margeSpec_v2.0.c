/*
 
 margeSpec
 
 2023.02.01 (v2.0)
 
 yuma aoki
 
 */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>

int main ( int argc, char *argv[] ) {
    
    int PHA = 0;
    int count = 0;
    int *data = NULL;
    int *spec = NULL;
    int lower = -5000;
    int upper = 4095;
    char buf[256];
    
    FILE *infile1 = NULL;
    FILE *infile2 = NULL;
    FILE *outfile = NULL;
    
    if ( argc == 3 ) {
        infile1 = fopen(argv[1], "r");
        infile2 = fopen(argv[2], "r");
    }
    else if ( argc == 5 ) {
        infile1 = fopen(argv[1], "r");
        infile2 = fopen(argv[2], "r");
        upper = atoi(argv[3]);
        lower = atoi(argv[4]);
    }
    else {
        printf("[specfile] [masterfile] [upper(default=-5000)] [lower(default=4095)]\n");
        return -1;
    }
    
    if ( upper < lower ) {
        printf("Upper value must be larger than lower value...\n");
        return -10;
    }
    if ( 0 < lower ) {
        printf("Lower value must be smaller than 0...\n");
        return -11;
    }
    
    // malloc
    data = (int*) malloc ( sizeof(int) * ( upper - lower + 1 ) );
    for ( int i=0; i<(upper-lower+1); i++ ) {
        data[i] = 0;
    }
    
    // pointer
    spec = &data[abs(lower)];
    
    // read file1
    while ( fgets( buf, sizeof(buf), infile1 ) != NULL ) {
        
        if( sscanf( buf, "%d %d", &PHA, &count ) != 2 ) {
            continue;
        }
        
        if ( lower <= PHA && PHA <= upper ) {
            spec[PHA] += count;
        }
        
    }
    
    // read file2
    while ( fgets( buf, sizeof(buf), infile2 ) != NULL ) {
        
        if( sscanf( buf, "%d %d", &PHA, &count ) != 2 ) {
            continue;
        }
        
        if ( lower <= PHA && PHA <= upper ) {
            spec[PHA] += count;
        }
        
    }
    
    fclose(infile1);
    fclose(infile2);
    
    /* output */
    outfile = fopen(argv[2], "w");
    
    // output
    for ( int i=lower; i<=upper; i++ ) {
        fprintf(outfile, "%d %d\n", i, spec[i]);
    }
    
    fclose(outfile);
    
    return 0;
    
}
