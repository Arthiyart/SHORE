#version 120

#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/wind.glsl"
#include "/lib/dynamic_lighting.glsl"

out vec2 texcoord;
out vec4 glcolor;
out vec3 vertexPosition;
out vec3 normal;
out vec2 lmcoord;
out float isWind;
out vec3 worldPos;
out float torchStrength;
out float isEmissive;

#ifdef GLOWING_ORES
    out float isOre;
#endif

#ifdef SHADOW_ENABLED
    out float diffuse;
    uniform vec3 shadowLightPosition;
#endif

in vec4 mc_Entity;
in vec2 mc_midTexCoord;
in float mc_material;

void main() {
    vec4 position = gl_Vertex;
    float material = mc_Entity.x;
    
    // Appliquer les effets de vent
    position.xyz = applyWind(position.xyz + cameraPosition, material, gl_MultiTexCoord0.st, mc_midTexCoord);
    position.xyz -= cameraPosition;

    gl_Position = gl_ModelViewProjectionMatrix * position;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;
    vertexPosition = position.xyz;
    normal = gl_NormalMatrix * gl_Normal;
    
    // Calculer la position mondiale pour l'éclairage dynamique
    worldPos = mat3(gbufferModelViewInverse) * (gl_ModelViewMatrix * gl_Vertex).xyz 
            + gbufferModelViewInverse[3].xyz;
    
    // Calculer la force de la torche
    torchStrength = getTorchStrength(lmcoord.x);
    
    // Détecter si c'est un bloc émissif (comme la lave)
    isEmissive = float(mc_Entity.x == 10068.0);  // ID de la lave
    
    #ifdef GLOWING_ORES
        // Détecter si c'est un minerai
        isOre = float(mc_Entity.x == 10014.0);  // ID générique pour les minerais
    #endif
    
    #ifdef SHADOW_ENABLED
        // Vérifier si c'est un objet fin
        bool isThin = mc_Entity.x == 10031.0 || mc_Entity.x == 10059.0
                    || mc_Entity.x == 10175.0 || mc_Entity.x == 10176.0
                    || mc_Entity.x == 10001.0 // Utiliser notre définition de block fin
                    || (abs(gl_Normal.y) < 0.01 && abs(abs(gl_Normal.x) - abs(gl_Normal.z)) < 0.01);
                    
        // Calculer la composante diffuse
        diffuse = (isEyeInWater == 0 ? 1.0 : 0.5) // Réduire sous l'eau
                * (1.0 - rainStrength) // Réduire avec la pluie
                * (isThin ? 0.75 : clamp(2.5 * dot(normalize(gl_NormalMatrix * gl_Normal),
                                               normalize(shadowLightPosition)), -0.3333, 1.0));
    #endif
}