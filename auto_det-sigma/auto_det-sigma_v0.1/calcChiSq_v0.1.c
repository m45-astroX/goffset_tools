/*
 
 calcChiSq_v0.1.c
 
 2022.05.02
 
 yuma a
 
 */

#include <stdio.h>
#include <math.h>
#include <string.h>

int main ( int argc, char *argv[] ) {
    
    /* var */
    // main data
    int fake_event[8];
    int eventAll = 0;
    double chiSq = 0.0;
    double real_GBR[8];
    double fake_GBR[8];
    // to read files
    int GRADE = 0;
    char buf[256];
    char name[20];
    double GBR = 0.0;
    double x = 0.0;
    double y = 0.0;
    double PHA = 0.0;
    double PHAS[9];
    double PHAS_SUM = 0.0;
    
    // args
    if ( argc != 3 ) {
        printf("[Event file] [GBR file(%%)]\n");
        return -1;
    }
    
    // reset
    for ( int i=0; i<8; i++ ) {
        fake_event[i] = 0;
        real_GBR[i] = 0.0;
        fake_GBR[i] = 0.0;
    }
    for ( int i=0; i<9; i++ ) {
        PHAS[i] = 0.0;
    }
    
    // files
    FILE *eventFile = NULL;
    FILE *gbrFile = NULL;
    
    // open file
    eventFile = fopen(argv[1], "r");
    if ( eventFile == NULL ) {
        printf("error : eventFile\n");
        return -1;
    }
    gbrFile = fopen(argv[2], "r");
    if ( gbrFile == NULL ) {
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
