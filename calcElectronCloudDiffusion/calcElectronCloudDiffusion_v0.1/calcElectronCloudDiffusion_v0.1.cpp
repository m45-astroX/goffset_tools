/*
 
 calcElectronCloudDiffusion
 
    - 2023.06.12 Yuma Aoki (v0.1)
 
 This program calculates the diffusion of electron clouds.
 
 */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include "constConfig.h"
#include "deviceConfig.h"

#define PRINT_SENSOR_1D
//#define PRINT_SENSOR_2D

//#define PRINT_ELECTRON_DIST
//#define DEBUG_NORMALPARAM
//#define DEBUG_INIT_ELECTRON_CLOUD
//#define DEBUG_INTEGRAL
//#define DEBUG_E

double calc_Dt_drift_m (double length_from_incident_surface_m_);

bool is_inside_electronCloud (int cloud_centre_x_, int cloud_centre_y_, int cloud_centre_z_, int first_gen_cloud_r_, int x_, int y_, int z_);

double E_liner_function (double z_m_);

double Gaussian_2D_function (double sigma_, double x1_, double x2_, double x1_u_, double x2_u_);


int main (int argc, char *argv[]) {
    
    // args
    if ( argc != 1 ) {
        printf("arguments error!\n");
        return -1;
    }
    
    // variables
    double photon_E_keV = 5.9;
    double penetrationDepth_um = 30;
    int outputDataMode = 0;     // select data mode 1D (=0) or 2D (=1)
    
    // variables (do not change)
    const double eV_over_channel = 6.0;
    const double PHA0 = photon_E_keV * pow(10.0, 3.0) / eV_over_channel;
    const double electron_dist_skip_threshold = 0.00000001;
    double sigma = 0.0;
    int penetrationDepth = (int)(penetrationDepth_um / PIXEL_SIZE_UM);
    double first_gen_cloud_r_um = (0.0171 * pow(photon_E_keV, 1.75) / 2.0);
    double first_gen_cloud_r = first_gen_cloud_r_um / PIXEL_SIZE_UM;
    int cloudPixel_N = 0;
    int cloud_centre_x = 0;
    int cloud_centre_y = 0;
    int cloud_centre_z = 0;
    double ***electron_dist = NULL;
    double **sensor = NULL;
    
    // calculate cloud status
    cloud_centre_x = (int)(SIM_DIV_N_X / 2.0);
    cloud_centre_y = (int)(SIM_DIV_N_Y / 2.0);
    cloud_centre_z = penetrationDepth;
    
    /* malloc */
    electron_dist = (double***)malloc(sizeof(double**) * SIM_DIV_N_X);
    for (int x=0; x<SIM_DIV_N_X; x++) {
        electron_dist[x] = (double**)malloc(sizeof(double*) * SIM_DIV_N_Y);
        for (int y=0; y<SIM_DIV_N_Y; y++) {
            electron_dist[x][y] = (double*)malloc(sizeof(double) * SIM_DIV_N_Z);
        }
    }
    sensor = (double**)malloc(sizeof(double*) * SIM_DIV_N_X);
    for (int x=0; x<SIM_DIV_N_X; x++) {
        sensor[x] = (double*)malloc(sizeof(double) * SIM_DIV_N_Y);
    }
    // initialize electron distribution
    for (int x=0; x<SIM_DIV_N_X; x++) {
        for (int y=0; y<SIM_DIV_N_Y; y++) {
            for (int z=0; z<SIM_DIV_N_Z; z++) {
                electron_dist[x][y][z] = 0.0;
            }
        }
    }
    // initialize sensor value
    for (int x=0; x<SIM_DIV_N_X; x++) {
        for (int y=0; y<SIM_DIV_N_Y; y++) {
            sensor[x][y] = 0;
        }
    }
    
    // count electron cloud pixel
    for (int x=0; x<SIM_DIV_N_X; x++) {
        for (int y=0; y<SIM_DIV_N_Y; y++) {
            for (int z=0; z<SIM_DIV_N_Z; z++) {
                if ( is_inside_electronCloud(cloud_centre_x, cloud_centre_y, cloud_centre_z, first_gen_cloud_r, x, y, z) == true ) cloudPixel_N ++;
            }
        }
    }
    for (int x=0; x<SIM_DIV_N_X; x++) {
        for (int y=0; y<SIM_DIV_N_Y; y++) {
            for (int z=0; z<SIM_DIV_N_Z; z++) {
                if ( is_inside_electronCloud(cloud_centre_x, cloud_centre_y, cloud_centre_z, first_gen_cloud_r, x, y, z) == true ) {
                    electron_dist[x][y][z] = PHA0 / (double)cloudPixel_N;
                }
            }
        }
    }
#ifdef PRINT_ELECTRON_DIST
    for (int z=0; z<SIM_DIV_N_Z; z++) {
        for (int y=0; y<SIM_DIV_N_Y; y++) {
            for (int x=0; x<SIM_DIV_N_X; x++) {
                if ( z == cloud_centre_z && electron_dist[x][y][z] != 0.0) fprintf(stderr, "%f ", electron_dist[x][y][z]);
            }
            if ( z == cloud_centre_z ) fprintf(stderr, "\n");
        }
    }
#endif

#ifdef DEBUG_NORMALPARAM
    fprintf(stderr, "NORMALPARAMDEBUG\n");
    fprintf(stderr, "PIXEL_SIZE_UM = %.2f\n", PIXEL_SIZE_UM);
    fprintf(stderr, "SIM_DIV_N_X = %d\n", SIM_DIV_N_X);
    fprintf(stderr, "SIM_DIV_N_Y = %d\n", SIM_DIV_N_Y);
    fprintf(stderr, "SIM_DIV_N_Z = %d\n", SIM_DIV_N_Z);
    fprintf(stderr, "sensorSize X = %.2f\n", SIM_DIV_N_X*PIXEL_SIZE_UM);
    fprintf(stderr, "sensorSize Y = %.2f\n", SIM_DIV_N_Y*PIXEL_SIZE_UM);
    fprintf(stderr, "sensorSize Z = %.2f\n", SIM_DIV_N_Z*PIXEL_SIZE_UM);
    fprintf(stderr, "penetrationDepth = %d\n", penetrationDepth);
    fprintf(stderr, "penetrationDepth_um = %.2f\n", penetrationDepth_um);
    fprintf(stderr, "cloud_centre_x = %d\n", cloud_centre_x);
    fprintf(stderr, "cloud_centre_y = %d\n", cloud_centre_y);
    fprintf(stderr, "cloud_centre_z = %d\n", cloud_centre_z);
    fprintf(stderr, "first_gen_cloud_r = %.2f\n", first_gen_cloud_r);
    fprintf(stderr, "first_gen_cloud_r_um = %.2f\n", first_gen_cloud_r_um);
    fprintf(stderr, "NORMALPARAMDEBUG END\n\n");
#endif
    
    // z (for each imaginary pixels)
    for (int z=0; z<SIM_DIV_N_Z; z++) {
        
        // set gaussian params
        sigma = sqrt(2.0 * calc_Dt_drift_m(z * PIXEL_SIZE_UM * pow(10.0, -6.0))) / (PIXEL_SIZE_UM * pow(10.0, -6.0));
        
#ifdef DEBUG_INIT_ELECTRON_CLOUD
        fprintf(stderr, "length_from_incident_surface_m_ = %5.10f\n", z * PIXEL_SIZE_UM * pow(10.0, -6.0));
        fprintf(stderr, "z = %3d, calc_Dt_drift_um = %2.10f, sigma= %2.10f\n", z, calc_Dt_drift_m(z * PIXEL_SIZE_UM * pow(10.0, -6.0)) * pow(10.0, 6.0), sigma);
#endif
        
        // x (for each imaginary pixels)
        for (int x=0; x<SIM_DIV_N_X; x++) {
            // y (for each imaginary pixels)
            for (int y=0; y<SIM_DIV_N_Y; y++) {
                
                if ( electron_dist[x][y][z] < electron_dist_skip_threshold ) continue;
                
                // sensor_x
                for (int s_x=0; s_x<SIM_DIV_N_X; s_x++) {
                    
                    // sensor_y
                    for (int s_y=0; s_y<SIM_DIV_N_Y; s_y++) {
                        
                        sensor[s_x][s_y] += electron_dist[x][y][z] * Gaussian_2D_function (sigma, s_x, s_y, cloud_centre_x, cloud_centre_y);
                    }
                }
            }
        }
    }
    
    if ( outputDataMode == 0 ) {     // 1D data
        // sensor_x
        for (int s_x=0; s_x<SIM_DIV_N_X; s_x++) {
            double s_x_sum = 0.0;
            // sensor_y
            for (int s_y=0; s_y<SIM_DIV_N_Y; s_y++) {
                if (sensor[s_x][s_y] != 0.0) {
                    s_x_sum += sensor[s_x][s_y];
                }
            }
            fprintf(stdout, "%d %2.10f\n", s_x, s_x_sum);
        }
    }
    else if ( outputDataMode == 1 ) {     // 2D data
        // sensor_x
        for (int s_x=0; s_x<SIM_DIV_N_X; s_x++) {
            // sensor_y
            for (int s_y=0; s_y<SIM_DIV_N_Y; s_y++) {
                fprintf(stdout, "%d %d %2.10f\n", s_x, s_y, sensor[s_x][s_y]);
            }
        }
    }

    /* memory freeing */
    // pointers
    for (int x=0; x<SIM_DIV_N_X; x++) {
        for (int y=0; y<SIM_DIV_N_Y; y++) {
            free(electron_dist[x][y]);
        }
    }
    for (int x=0; x<SIM_DIV_N_X; x++) {
        free(sensor[x]);
    }
    // double pointers
    for (int x=0; x<SIM_DIV_N_X; x++) {
        free(electron_dist[x]);
    }
    free(sensor);
    // triple pointers
    free(electron_dist);
    
    return 0;
    
}


double calc_Dt_drift_m (double length_from_incident_surface_m_) {
    
    int integ_div_N = 1000;
    double Dt_drift_m = 0.0;
    double integ_min_m = (-((double)SIM_DIV_N_Z * PIXEL_SIZE_UM * pow(10.0, -6.0) * 0.5) + length_from_incident_surface_m_);
    double integ_max_m = (double)SIM_DIV_N_Z * PIXEL_SIZE_UM * pow(10.0, -6.0) * 0.5;
    double dz_m = (integ_max_m - integ_min_m) / (double)integ_div_N;
    
    // check integral range
    if ( integ_min_m >= integ_max_m ) {
        fprintf(stderr, "calc_Dt_drift_m : integ_min_m must be less than integ_max_m\n");
        fprintf(stderr, "abort\n");
        exit(-1);
    }
    
    // calc Dt_drift_m
    for (int i=0; i<integ_div_N; i++) {
        Dt_drift_m += (-1) * KB_OVER_Q_ELECTRON * SIM_PARAM_CCDTEMP * (1 / E_liner_function(integ_min_m + dz_m * i)) * dz_m;
    }
    
    if ( Dt_drift_m < 0 ) {
        fprintf(stderr, "calc_Dt_drift_m : Dt_drift_m must be plus\n");
        fprintf(stderr, "abort\n");
        exit(-1);
    }
    
#ifdef DEBUG_INTEGRAL
    fprintf(stderr, "D/2 (unit:meters) = %2.10f\n", ((double)SIM_DIV_N_Z * PIXEL_SIZE_UM * pow(10.0, -6.0) * 0.5));
    fprintf(stderr, "integ_min_m = %.10f\n", integ_min_m);
    fprintf(stderr, "integ_max_m = %.10f\n", integ_max_m);
    fprintf(stderr, "dz_m = %.10f\n", dz_m);
    fprintf(stderr, "Dt_drift_m = %.20f\n", Dt_drift_m);
#endif
    
    return Dt_drift_m;
    
}


bool is_inside_electronCloud (int cloud_centre_x_, int cloud_centre_y_, int cloud_centre_z_, int first_gen_cloud_r_, int x_, int y_, int z_) {
    
    if ( ((y_-cloud_centre_y_)*(y_-cloud_centre_y_)+(z_-cloud_centre_z_)*(z_-cloud_centre_z_))<=(first_gen_cloud_r_)*(first_gen_cloud_r_) && ((z_-cloud_centre_z_)*(z_-cloud_centre_z_)+(x_-cloud_centre_x_)*(x_-cloud_centre_x_))<=(first_gen_cloud_r_)*(first_gen_cloud_r_) && ((x_-cloud_centre_x_)*(x_-cloud_centre_x_)+(y_-cloud_centre_y_)*(y_-cloud_centre_y_))<=(first_gen_cloud_r_)*(first_gen_cloud_r_) ) {
        return true;
    }
    else {
        return false;
    }
    
}

double E_liner_function (double z_m_) {
    
    double E = 0.0;
    double sim_param_D_m = (double)SIM_DIV_N_Z * PIXEL_SIZE_UM * pow(10.0, -6.0);
    
    E = - (2.0 * (SIM_PARAM_P0 - 1.0) / (SIM_PARAM_P0 + 1.0)) * (SIM_PARAM_V / pow(sim_param_D_m, 2.0)) * z_m_ - (SIM_PARAM_V / sim_param_D_m);
    
#ifdef DEBUG_E
    fprintf(stderr, "z_m_ = %f\n", z_m_);
    fprintf(stderr, "sim_param_D_m = %f\n", sim_param_D_m);
    fprintf(stderr, "E = %f\n", E);
#endif
    
    return E;
    
}


double Gaussian_2D_function (double sigma_, double x1_, double x2_, double x1_u_, double x2_u_) {
    
    return (1.0 / (2.0 * M_PI * pow(sigma_, 2.0))) * exp(- (1.0 / (2.0 * pow(sigma_, 2.0))) * (pow((x1_ - x1_u_), 2.0) + pow((x2_ - x2_u_), 2.0)));
    
}
