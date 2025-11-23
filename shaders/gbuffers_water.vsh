#version 120

#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"

attribute vec4 mc_Entity;

uniform int fogShape;
uniform float fogEnd;
uniform float fogStart;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 glcolor;
varying vec4 normal;
varying vec3 worldPos;
varying float isWater;
varying float fogMix;
varying float torchStrength;

// Génère un nombre aléatoire basé sur une position
float random(vec2 pos) {
    return fract(sin(dot(pos, vec2(12.9898, 78.233))) * 43758.5453);
}

// Calcule la force de l'éclairage de torche
float getTorchStrength(float torchLight) {
    return 1.1 * clamp((torchLight - 0.025) / 0.9, 0.0, 1.0);
}

// Calcul du mélange du brouillard
float getFogMix(vec3 pos) {
    #ifdef ENABLE_FOG
        float len = fogShape == 1 ? length(pos.xz) : length(pos);
        
        float fogStart2 = fogStart;
        float fogEnd2 = fogEnd;
        
        // Paramètres de brouillard en fonction de l'heure
        float x = worldTime * (1.0/24000.0);
        
        if (x < 0.75 && x > 0.5325) {
            // Coucher de soleil -> Minuit
            fogStart2 *= OVERWORLD_FOG_MIN;
        } else if (x > 0.75 && x < 0.9675) {
            // Minuit -> Lever de soleil
            fogStart2 *= OVERWORLD_FOG_MIN;
        } else {
            // Jour
            fogStart2 *= OVERWORLD_FOG_MAX;
        }
        
        // Effet de la pluie
        fogStart2 = min(fogStart2, fogStart * (1.0 - rainStrength));
        
        return clamp((len - fogStart2) / (fogEnd2 - fogStart2), 0.0, 1.0);
    #else
        return 0.0;
    #endif
}

// Calcule la position dans le monde
vec3 getWorldPosition() {
    return mat3(gbufferModelViewInverse) * (gl_ModelViewMatrix * gl_Vertex).xyz 
         + gbufferModelViewInverse[3].xyz;
}

// Génère les vagues de l'eau exactement comme dans le shader miniature
void getWaterWave(inout vec4 normal, float random) {
    if (abs(normal.y) > 0.8) {
        // Facteur d'amplification qui augmente avec WATER_WAVE_SIZE
        float amplitudeFactor = WATER_WAVE_SIZE * 0.1; // Relation directe
        
        // Facteur de distance (diminue l'effet avec la distance)
        float distanceFactor = 1.0 / max(1.0, length(worldPos.xz) * 0.5);
        
        // Combiner pour l'amplitude finale des vagues
        float v = amplitudeFactor * distanceFactor;
        v = clamp(v, 0.0, 1.0); // Limiter pour éviter des vagues trop extrêmes
        
        // Calculer les déplacements des vagues
        normal.x += v * pow(sin(random * WATER_WAVE_SPEED * frameTimeCounter), 3.0);
        normal.z += v * pow(cos(random * WATER_WAVE_SPEED * frameTimeCounter), 3.0);
        
        // Normaliser
        normal.xyz = normalize(normal.xyz);
    }
}

void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;
    normal = vec4(gl_Normal, 1.0);
    
    // Identifie si c'est de l'eau
    isWater = float(mc_Entity.x == 10008.0);
    
    // Calcul des positions
    worldPos = getWorldPosition();
    
    // Calcul du brouillard
    fogMix = getFogMix(worldPos);
    
    // Force de l'éclairage de torche
    torchStrength = getTorchStrength(lmcoord.s);
    
    // Si c'est de l'eau, calculer ses propriétés
    if (isWater > 0.9) {
        float posRandom = random(floor(worldPos.xz) + floor(cameraPosition.xz));
        
        #if WATER_WAVE_SIZE > 0
            getWaterWave(normal, posRandom);
        #endif
    }
    
    // Normaliser et transformer les normales pour le stockage
    normal = vec4(0.5 + 0.5 * normal.xyz, 1.0);
}