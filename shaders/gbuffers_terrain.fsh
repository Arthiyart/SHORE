#version 120

#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/dynamic_lighting.glsl"

#ifdef SHADOW_ENABLED
    #include "/lib/shadows.glsl"
    uniform mat4 shadowModelView;
    uniform mat4 shadowProjection;
    uniform sampler2D shadowtex1;
    in float diffuse;
#endif

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
in float isWind;
in vec3 worldPos;
in float torchStrength;
in float isEmissive;

#ifdef GLOWING_ORES
    in float isOre;
#endif

/* DRAWBUFFERS:0126 */
layout(location = 0) out vec4 albedoOut;      // Couleur de base
layout(location = 1) out vec4 normalOut;      // Normales
layout(location = 2) out vec4 lightmapOut;    // Lightmap
layout(location = 3) out vec4 shadowDataOut;  // Données d'ombre (si activées)

void main() {
    vec4 albedo = texture(gtexture, texcoord) * glcolor;
    vec4 lightmapColor = texture(lightmap, lmcoord);

    if (albedo.a < 0.1) discard;
    
    #ifdef GLOWING_ORES
        // Faire briller les minerais
        if (isOre > 0.5) {
            vec3 oreGlow = vec3(1.0, 0.9, 0.9); // Teinte rosée pour les minerais
            float glowIntensity = 0.3333 * dot(albedo.rgb, albedo.rgb); // Basé sur la luminosité du minerai
            lightmapColor.rgb = mix(lightmapColor.rgb, oreGlow, glowIntensity);
        }
    #endif
    
    #ifdef EMISSIVE_BLOCKS
        // Faire briller les blocs émissifs comme la lave
        if (isEmissive > 0.5) {
            vec3 emissiveColor = vec3(1.0, 0.6, 0.3); // Couleur chaude pour la lave
            lightmapColor.rgb = max(lightmapColor.rgb, emissiveColor * 0.8);
        }
    #endif

        // Appliquer l'éclairage dynamique
        vec3 dynamicLight = calculateDynamicLighting(lightmapColor.rgb, lmcoord.x, worldPos);
        lightmapColor.rgb = dynamicLight * TORCH_INTENSITY;
    
    #ifdef SHADOW_ENABLED
        // Calculer la force de l'ombre
        float shadowStrength = getShadowStrength(worldPos, normal, diffuse, 
                                            shadowModelView, shadowProjection, shadowtex1);
                                
        // Préserver une partie de la luminosité ambiante
        float ambientPreservation = 0.7; // Ajustez cette valeur selon vos préférences
    
        // Appliquer les ombres avec l'intensité spécifiée
        vec3 shadowColor = vec3(1.0 - SHADOW_DARKNESS * (1.0 - ambientPreservation));
    
        // Calculer l'éclairage final avec ombres
        vec3 lighting = lightmapColor.rgb;
        lighting.rgb *= mix(shadowColor, vec3(1.0), shadowStrength);
    
        // Créer une couleur d'éclairage combinée
        albedo.rgb *= lighting;
        
        // Stocker les données d'ombre pour un traitement ultérieur si nécessaire
        shadowDataOut = vec4(shadowStrength, lmcoord.y, 0.0, 1.0);
    #else
        // Éclairage sans ombres
        albedo.rgb *= lightmapColor.rgb;
        shadowDataOut = vec4(1.0, lmcoord.y, 0.0, 1.0);
    #endif

    // Écriture dans les buffers
    albedoOut = albedo;
    normalOut = vec4(normalize(normal) * 0.5 + 0.5, isWind);
    lightmapOut = lightmapColor;
}