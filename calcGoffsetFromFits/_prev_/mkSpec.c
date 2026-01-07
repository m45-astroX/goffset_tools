/*
 
 mkSpec.c
 
 2021.07.22
 2022.03.02
 2022.08.14
 
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main ( int argc , char *argv[] ) {
    
    // args
    if ( argc != 3 ) {
        printf("Please input 2 arguments\n");
        printf("[inputFile] [outputFile]\n");
        return -1;
    }
    
    // var
    int PHA = 0;
    int data[4096];
    char buf[256];
    
    // init
    for ( int i=0; i<=4095; i++ ){
        data[i] = 0;
    }
    
    // fp
    FILE *inputFile = NULL;
    FILE *outputFile = NULL;
    
    inputFile = fopen(argv[1], "r");
    outputFile = fopen(argv[2], "w");
    if( inputFile == NULL ){
        printf("Error : inputFile\n");
        return -1;
    }
    if( outputFile == NULL ){
        printf("Error : outputFile\n");
        return -1;
    }
    
    
    while ( fgets( buf, sizeof(buf), inputFile ) != NULL ) {
        
        if( sscanf( buf, "%d", &PHA ) != 1 ) {
            continue;
        }
        
        if ( 0 <= PHA && PHA <= 4095 ) {
            data[PHA] = data[PHA] + 1;
        }
        
    }
    
    for ( int i=0; i<=4095; i++ ) {
        fprintf(outputFile, "%d %d\n", i, data[i]);
    }
    
    fclose(inputFile);
    fclose(outputFile);
    
    return 0;
    
}
