#version 120

#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/sky.glsl"

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 glcolor;
varying vec4 normal;
varying vec3 worldPos;
varying float isWater;
varying float fogMix;
varying float torchStrength;

// Obtient la couleur des torches avec des valeurs codées en dur
vec3 getTorchColor(vec3 ambient) {
    float strength = torchStrength;
    
    strength = max(0.0, min(1.0, strength));
    strength = strength * strength * (3.0 - 2.0 * strength); // Lissage
    
    // Couleurs chaudes pour les torches
    vec3 torchColorInner = vec3(1.0, 0.8, 0.6);  // Orange chaud 
    vec3 torchColorOuter = vec3(1.0, 0.55, 0.2); // Orange plus foncé
    
    return mix(torchColorOuter, torchColorInner, strength) * strength * max(0.0, 1.0 - (ambient.r + ambient.g + ambient.b) / 3.0);
}

// Obtenir une couleur d'eau personnalisée basée sur les paramètres
vec3 getCustomWaterColor() {
    // Utiliser les composantes RGB définies dans settings.glsl
    return vec3(WATER_RED, WATER_GREEN, WATER_BLUE) * WATER_BRIGHTNESS;
}

// Ajuster la couleur en fonction de l'heure de la journée
vec3 getTimeAdjustedWaterColor() {
    vec3 baseColor = getCustomWaterColor();
    float dayFactor = getDayFactor();
    float transitionFactor = getTransitionFactor();
    float isSunset = getSunsetFactor() > 0.0 ? 1.0 : 0.0;
    
    // Ajustements pour le jour/nuit
    vec3 nightTint = vec3(0.5, 0.7, 1.0);    // Teinte plus froide la nuit
    vec3 dayTint = vec3(1.0, 1.0, 1.0);      // Pas de teinte le jour
    vec3 sunriseTint = vec3(1.1, 0.9, 0.8);  // Teinte chaude au lever du soleil
    vec3 sunsetTint = vec3(1.2, 0.8, 0.7);   // Teinte encore plus chaude au coucher
    
    // Sélection de la teinte de transition
    vec3 transTint = mix(sunriseTint, sunsetTint, isSunset);
    
    // Mélange jour/nuit
    vec3 timeTint = mix(nightTint, dayTint, dayFactor);
    
    // Mélange avec transition
    timeTint = mix(timeTint, transTint, transitionFactor);
    
    // Ajuster avec la pluie
    timeTint = mix(timeTint, vec3(0.7, 0.8, 1.0), rainStrength);
    
    return baseColor * timeTint;
}

void main() {
    vec4 color = texture2D(texture, texcoord) * glcolor;
    vec4 ambient = texture2D(lightmap, vec2(0.03, lmcoord.t));
    
    if (isWater > 0.9) {
        // Remplacer complètement la texture vanilla par notre couleur personnalisée
        vec3 waterColor = getTimeAdjustedWaterColor();
        
        // Remplacer complètement la couleur
        color.rgb = waterColor;
        
        // Définir l'opacité en fonction du paramètre
        color.a = WATER_OPACITY;
    }
    
    // Ajoute l'éclairage ambiant basé sur la lightmap Minecraft
    ambient.rgb += 0.5 * getTorchColor(ambient.rgb);
    color *= ambient;
    
    // Applique le brouillard
    color.rgb = mix(color.rgb, fogColor, fogMix);
    
    /* DRAWBUFFERS:067 */
    gl_FragData[0] = color;
    gl_FragData[1] = normal;
    gl_FragData[2] = vec4(isWater, isWater, 0.0, 1.0);
}