/*
 
 calcChiSq_Goffset-PHA_v0.1.c
 
 2022.05.17
 
 yuma a
 
 */

#include <stdio.h>
#include <math.h>
#include <string.h>

int main ( int argc, char *argv[] ) {
    
    /* var */
    double real_PHA[8];
    double real_goffset[8];
    double fake_coe_a[8];
    double fake_coe_b[8];
    double fake_coe_c[8];
    // to read
    int GRADE = 0;
    
    
    // args
    if ( argc != 3 ) {
        printf("[Param file (realData)]\n")
        printf("[Function coefficient (fakeData)]\n");
        return -1;
    }
    
    // reset
    for ( int i=0; i<8; i++ ) {
        real_PHA[i] = 0.0;
        real_goffset[i] = 0.0;
        fake_coe_a[i] = 0.0;
        fake_coe_b[i] = 0.0;
        fake_coe_c[i] = 0.0;
    }
    
    // files
    FILE *realFile = NULL;
    FILE *fakeFile = NULL;
    
    // duplicate
    if ( strcmp(argv[1], argv[2]) == 0 ) {
        printf("error : realData -eq fakeData\n");
        return -1;
    }
    
    // open file
    realFile = fopen(argv[1], "r");
    if ( realFile == NULL ) {
        printf("error : realFile\n");
        return -1;
    }
    fakeFile = fopen(argv[2], "r");
    if ( fakeFile == NULL ) {
        printf("error : gbrFile\n");
        return -1;
    }
    
    /* Read fake Data */
    while ( fgets( buf, sizeof(buf), eventFile ) != NULL ) {
        
        // skip
        if( strncmp(buf, "//", 2) == 0 || strcmp(buf, "\n") == 0 || strcmp(buf, "#") == 0 ) {
            continue;
        }
        
        // read
        if( sscanf( buf, "%lf %lf %lf %lf %lf %lf %lf %lf %lf %lf %lf %lf %d %lf", &x, &y, &PHA, &PHAS[0], &PHAS[1], &PHAS[2], &PHAS[3], &PHAS[4], &PHAS[5], &PHAS[6], &PHAS[7], &PHAS[8], &GRADE, &PHAS_SUM ) != 14 ) {
            continue;
        }
        
        // event ++
        fake_event[GRADE] ++;
        eventAll ++;
        
    }
    
    // calc fake GBR
    for ( int i=0; i<8; i++ ) {
        fake_GBR[i] = fake_event[i] / (double)eventAll;
    }
    
    /* Read real Data */
    while ( fgets( buf, sizeof(buf), gbrFile ) != NULL ) {
        
        // skip
        if( strncmp(buf, "//", 2) == 0 || strcmp(buf, "\n") == 0 || strcmp(buf, "#") == 0 ) {
            continue;
        }
        
        // read
        if( sscanf( buf, "%s %lf", name, &GBR ) != 2 ) {
            continue;
        }
        
        // input real GBR ( % -> decimal )
        if ( strcmp(name, "G0") == 0 ) real_GBR[0] = GBR / 100.0;
        if ( strcmp(name, "G1") == 0 ) real_GBR[1] = GBR / 100.0;
        if ( strcmp(name, "G2") == 0 ) real_GBR[2] = GBR / 100.0;
        if ( strcmp(name, "G3") == 0 ) real_GBR[3] = GBR / 100.0;
        if ( strcmp(name, "G4") == 0 ) real_GBR[4] = GBR / 100.0;
        if ( strcmp(name, "G5") == 0 ) real_GBR[5] = GBR / 100.0;
        if ( strcmp(name, "G6") == 0 ) real_GBR[6] = GBR / 100.0;
        if ( strcmp(name, "G7") == 0 ) real_GBR[7] = GBR / 100.0;
        
    }
    
    // calc chiSq
    for ( int i=0; i<8; i++ ) {
        chiSq = chiSq + ( fake_GBR[i] - real_GBR[i] ) * ( fake_GBR[i] - real_GBR[i] ) / real_GBR[i];
    }
    
    // print result (chiSq)
    printf("%lf\n", chiSq);
    
    // fclose
    fclose(eventFile);
    fclose(gbrFile);
    
    return 0;
    
}

