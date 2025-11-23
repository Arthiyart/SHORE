#ifndef WIND_GLSL
#define WIND_GLSL

#include "/lib/settings.glsl"

// Fonction de bruit améliorée pour les bourrasques de vent
vec3 hash33(vec3 p3) {
    p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
}

// Fonction de bruit pour les bourrasques de vent
float windGustNoise(vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    float n = p.x + p.y*157.0 + 113.0*p.z;
    return mix(mix(mix(dot(hash33(p), f),
                       dot(hash33(p + vec3(1,0,0)), f - vec3(1,0,0)),
                       f.x),
                   mix(dot(hash33(p + vec3(0,1,0)), f - vec3(0,1,0)),
                       dot(hash33(p + vec3(1,1,0)), f - vec3(1,1,0)),
                       f.x),
                   f.y),
               mix(mix(dot(hash33(p + vec3(0,0,1)), f - vec3(0,0,1)),
                       dot(hash33(p + vec3(1,0,1)), f - vec3(1,0,1)),
                       f.x),
                   mix(dot(hash33(p + vec3(0,1,1)), f - vec3(0,1,1)),
                       dot(hash33(p + vec3(1,1,1)), f - vec3(1,1,1)),
                       f.x),
                   f.y),
               f.z);
}

// Nouvelle fonction pour le mouvement des feuilles
vec3 applyLeafWind(vec3 position, float time, float windGust) {
    // Fréquences d'oscillation différentes pour chaque axe
    float freqX = 2.0 * LEAF_WIND_SPEED;
    float freqY = 1.5 * LEAF_WIND_SPEED;
    float freqZ = 2.5 * LEAF_WIND_SPEED;

    // Amplitudes d'oscillation
    float ampX = 0.05 * LEAF_WIND_STRENGTH;
    float ampY = 0.03 * LEAF_WIND_STRENGTH;
    float ampZ = 0.04 * LEAF_WIND_STRENGTH;

    // Calcul des oscillations
    float oscillationX = sin(time * freqX + position.x * 0.5 + position.z * 0.3) * ampX;
    float oscillationY = cos(time * freqY + position.z * 0.5 + position.x * 0.2) * ampY;
    float oscillationZ = sin(time * freqZ + position.x * 0.4 + position.z * 0.6) * ampZ;

    // Application des oscillations et des bourrasques
    position.x += oscillationX * (1.0 + windGust);
    position.y += oscillationY * (1.0 + windGust * 0.5);
    position.z += oscillationZ * (1.0 + windGust);

    return position;
}

vec3 applyWind(vec3 position, float material, vec2 texcoord, vec2 mc_midTexCoord) {
    vec3 originalPos = position;
    float time = frameTimeCounter * WIND_SPEED;
    
    // Calcul des bourrasques de vent
    vec3 windNoisePos = position * WIND_NOISE_SCALE + vec3(time * WIND_GUST_SPEED, 0.0, 0.0);
    float windGust = windGustNoise(windNoisePos) * 2.0 - 1.0;
    windGust = sign(windGust) * pow(abs(windGust), WIND_TURBULENCE) * WIND_GUST_STRENGTH;

    // Calcul de l'oscillation de base
    vec2 wind = vec2(
        sin(time + position.x * 0.5 + position.z * 0.5),
        cos(time * 0.5 + position.x * 0.5 + position.z * 0.5)
    );
    
    wind *= WIND_STRENGTH;
    
    // Application des bourrasques
    wind += vec2(windGust, windGust * 0.5);

    bool isTopVertex = texcoord.y < mc_midTexCoord.y;
    float vertexFactor = isTopVertex ? 1.0 : 0.3;

    // Application du vent aux différents types de végétation
    if (material == 10004.0 || material == 10005.0 || material == 10006.0) { 
        // Plantes basses/hautes (herbe, fleurs, buissons)
        position.xz += wind * vertexFactor * GRASS_BOUNCE_STRENGTH;
        position.y += sin(time * 2.0 + position.x * 0.5 + position.z * 0.5) * 0.02 * vertexFactor * GRASS_BOUNCE_STRENGTH;
    } 
    else if (material == 10003.0) { // Feuilles
        position = applyLeafWind(position, time, windGust);
    }
    else if (material == 10001.0) { // Tiges et végétation flexible (canne à sucre, vignes)
        position.xz += wind * vertexFactor * 0.5; // Animation plus subtile
    }

    return position;
}

#endif // WIND_GLSL