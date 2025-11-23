#version 120

#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/dynamic_lighting.glsl"

#ifdef SHADOW_ENABLED
    #include "/lib/shadows.glsl"
    uniform mat4 shadowModelView;
    uniform mat4 shadowProjection;
    uniform sampler2D shadowtex1;
    varying float diffuse;
#endif

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying vec3 normal;
varying vec3 worldPos;
varying float torchStrength;

void main() {
    vec4 albedo = texture2D(texture, texcoord) * glcolor;
    vec4 lightmapColor = texture2D(lightmap, lmcoord);

    if (albedo.a < 0.1) discard;
    
    // Appliquer l'éclairage dynamique
    vec3 dynamicLight = calculateDynamicLighting(lightmapColor.rgb, lmcoord.x, worldPos);
    lightmapColor.rgb = dynamicLight * TORCH_INTENSITY;
    
    #ifdef SHADOW_ENABLED
        // Calculer la force de l'ombre
        float shadowStrength = getShadowStrength(worldPos, normal, diffuse, 
                                            shadowModelView, shadowProjection, shadowtex1);
                                
        // Préserver une partie de la luminosité ambiante
        float ambientPreservation = 0.7;
    
        // Appliquer les ombres avec l'intensité spécifiée
        vec3 shadowColor = vec3(1.0 - SHADOW_DARKNESS * (1.0 - ambientPreservation));
    
        // Calculer l'éclairage final avec ombres
        vec3 lighting = lightmapColor.rgb;
        lighting.rgb *= mix(shadowColor, vec3(1.0), shadowStrength);
    
        // Créer une couleur d'éclairage combinée
        albedo.rgb *= lighting;
        
        // Stocker les données d'ombre pour un traitement ultérieur si nécessaire
        vec4 shadowData = vec4(shadowStrength, lmcoord.y, 0.0, 1.0);
        
        /* DRAWBUFFERS:0126 */
        gl_FragData[0] = albedo;
        gl_FragData[1] = vec4(normalize(normal) * 0.5 + 0.5, 0.0);
        gl_FragData[2] = lightmapColor;
        gl_FragData[3] = shadowData;
    #else
        // Éclairage sans ombres
        albedo.rgb *= lightmapColor.rgb;
        
        /* DRAWBUFFERS:012 */
        gl_FragData[0] = albedo;
        gl_FragData[1] = vec4(normalize(normal) * 0.5 + 0.5, 0.0);
        gl_FragData[2] = lightmapColor;
    #endif
}