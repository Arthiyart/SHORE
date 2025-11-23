#version 120

#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/dynamic_lighting.glsl"

varying vec2 texcoord;
varying vec4 glcolor;
varying vec3 normal;
varying vec2 lmcoord;
varying vec3 worldPos;
varying float torchStrength;

#ifdef SHADOW_ENABLED
    varying float diffuse;
    uniform vec3 shadowLightPosition;
#endif

void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;
    normal = gl_NormalMatrix * gl_Normal;
    
    // Calculer la position mondiale pour l'éclairage dynamique
    worldPos = mat3(gbufferModelViewInverse) * (gl_ModelViewMatrix * gl_Vertex).xyz 
              + gbufferModelViewInverse[3].xyz;
    
    // Pour les éléments à la première personne, nous voulons toujours un bon éclairage
    // Donc nous allons booster légèrement la valeur de la torche
    torchStrength = getTorchStrength(lmcoord.x) * 1.2;
    
    #ifdef SHADOW_ENABLED
        // Pour la main, utiliser une diffusion constante et élevée pour un meilleur éclairage
        diffuse = 0.95 * (1.0 - rainStrength * 0.3);
    #endif
}