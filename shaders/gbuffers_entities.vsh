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
    vec4 position = gl_Vertex;
    
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;
    normal = gl_NormalMatrix * gl_Normal;
    
    // Calculer la position mondiale pour l'éclairage dynamique
    worldPos = mat3(gbufferModelViewInverse) * (gl_ModelViewMatrix * gl_Vertex).xyz 
            + gbufferModelViewInverse[3].xyz;
    
    // Calculer la force de la torche
    torchStrength = getTorchStrength(lmcoord.x);
    
    #ifdef SHADOW_ENABLED
        // Calculer la composante diffuse
        diffuse = (isEyeInWater == 0 ? 1.0 : 0.5) // Réduire sous l'eau
                * (1.0 - rainStrength) // Réduire avec la pluie
                * clamp(2.5 * dot(normalize(gl_NormalMatrix * gl_Normal),
                                normalize(shadowLightPosition)), -0.3333, 1.0);
    #endif
}