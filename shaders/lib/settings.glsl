#ifndef SETTINGS_GLSL
#define SETTINGS_GLSL

//---------- PARAMÈTRES DES NUAGES ----------//
#define CLOUD_STYLE 1 				 //[0 1]
#define CLOUD_FOG_DISTANCE  0.25 	 //[0.0 0.25 0.5 0.75 1.0 1.5 2.0 3.0]
#define CLOUD_FOG_INTENSITY  1 		 //[0.0 0.25 0.5 0.75 1.0 1.5 2.0]
#define CLOUD_SPEED  1.0 			 //[0.0 0.25 0.5 0.75 1.0 1.2 1.5 1.7 2.0]
#define CLOUD_PERMUTATION_SPEED  1.0 //[0.0 0.25 0.5 0.75 1.0 1.2 1.5 1.7 2.0]
#define CLOUD_DETAIL 4               // Détail des nuages (nombre d'octaves) [2 4 6 8 10]
#define CLOUD_DENSITY 0.7 			 // Densité des nuages [0.3 0.5 0.7 1.0 1.3]
#define CLOUD_HOLES 0.5   			 // Densité des trous dans les nuages [0.1 0.2 0.3 0.4 0.5 0.6]
#define CLOUD_SEED 32     			 // Seed pour la génération des nuages [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32]

//---------- PARAMÈTRES DU CIEL ----------//
#define SKY_COLOR 0              // color of sky [0 1 2 3]
#define ATMOSPHERIC_SCATTERING 1 // Active la diffusion atmosphérique [0 1]

//---------- PARAMÈTRES DE L'EAU ----------//
#define WATER 1 			  //[0 1]
#define WATER_WAVE_SIZE 8     //[0 1 2 3 4 5 6 7 8 9 10]
#define WATER_WAVE_SPEED 2    //[1 2 3 4 5 6 7 8 9 10]
#define WATER_OPACITY 0.8     //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.65 0.7 0.8 0.9 1.0]
#define WATER_BLUE 0.6        //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.65 0.7 0.8 0.9 1.0]
#define WATER_GREEN 0.5       //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.65 0.7 0.8 0.9 1.0]
#define WATER_RED 0.3         //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.65 0.7 0.8 0.9 1.0]
#define WATER_BRIGHTNESS 0.35 //[0.0 0.1 0.2 0.3 0.35 0.4 0.5]
#define REFLECTIONS 10        //[0 1 2 3 4 5 6 7 8 9 10]

//---------- PARAMÈTRES DU VENT ----------//
#define WIND 1 //[0 1]
#define GRASS_BOUNCE_STRENGTH 0.25 //[0.0 0.25 0.5 0.75 1.0]
#define WIND_TURBULENCE 1.5        //[0.0 0.5 1.0 1.5 2.0 2.5 3.0]
#define WIND_NOISE_SCALE 0.25      //[0.1 0.15 0.2 0.25 0.3 0.45 0.5]
#define WIND_SPEED 1.0             //[0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0]
#define WIND_GUST_SPEED 1.0        //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define LEAF_WIND_SPEED 0.5        //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define WIND_STRENGTH 0.02         //[0.0 0.01 0.02 0.03 0.04 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4]
#define WIND_GUST_STRENGTH 0.3     //[0.0 0.1 0.2 0.3 0.4 0.5]
#define LEAF_WIND_STRENGTH 0.75    //[0.0 0.5 0.75 1.0 1.25 1.5 1.75 2.0]

//---------- PARAMÈTRES DES OMBRES ----------//
#define SHADOW_ENABLED
#define SHADOW_DARKNESS 0.85 //[0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1]
#define SHADOW_PIXEL 16 //[0 4 8 16 32 64]

// Paramètres de la shadow map
const int shadowMapResolution = 1024; //[256 512 1024 2048 4096]
const float shadowDistance = 128.0; //[64.0 96.0 128.0 192.0 256.0]
const float shadowIntervalSize = 7.0;
const float shadowDistanceRenderMul = 1.0;
const float entityShadowDistanceMul = 0.2;

// Constantes calculées pour les ombres
const float SHADOW_MAX_DIST_SQUARED = shadowDistance * shadowDistance;
const float INV_SHADOW_MAX_DIST_SQUARED = 1.0 / SHADOW_MAX_DIST_SQUARED;

//---------- PARAMÈTRES D'ÉCLAIRAGE DYNAMIQUE ----------//
#define HAND_DYNAMIC_LIGHTING //Permet à l'objet tenu d'émettre de la lumière
#define TORCH_INTENSITY 1.2 //[0.5 0.75 1.0 1.2 1.5 1.75 2.0]
#define DYNAMIC_LIGHT_DISTANCE 0.5 //[0.25 0.5 0.75 1.0]

//---------- PARAMÈTRES DE POST-PROCESSING ----------//
#define BLOOM_ENABLED 1           //[0 1]
#define BLOOM_INTENSITY 0.8       //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.25 1.5 1.75 2.0]
#define BLOOM_RADIUS 6.0          //[1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]
#define BLOOM_THRESHOLD 0.8       //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define TONEMAPPING_MODE 1        //[0 1 2 3]
#define EXPOSURE 0.9              //[0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.7 2.0 2.5 3.0]
#define CONTRAST 1.2              //[0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.7 2.0]
#define SATURATION 1.0            //[0.0 0.25 0.5 0.75 1.0 1.25 1.5 1.75 2.0]
#define VIBRANCE 0.5              //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define HUE_SHIFT 0.0 //[-0.5 -0.45 -0.4 -0.35 -0.3 -0.25 -0.2 -0.15 -0.1 -0.075 -0.05 -0.025 -0.01 0.0 0.01 0.025 0.05 0.075 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5]

//---------- PARAMÈTRES DES GOD RAYS ----------//
#define GODRAYS_ENABLED 1            //[0 1]
#define GODRAYS_STRENGTH 3.0         //[1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]
#define GODRAYS_LENGTH 1.5           //[0.5 0.75 1.0 1.25 1.5 1.75 2.0 2.5 3.0 3.5 4.0 4.5 5.0]
#define GODRAYS_SAMPLES 16           //[8 16 24 32 48 64]
#define GODRAYS_BLUR 1               //[0 1 2 3]
#define GODRAYS_COLOR_R 1.0          //[0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define GODRAYS_COLOR_G 0.8          //[0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define GODRAYS_COLOR_B 0.6          //[0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define GODRAYS_RADIUS 0.4           //[0.05 0.1 0.15 0.2 0.25 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 2.0 5.0]

#endif // SETTINGS_GLSL