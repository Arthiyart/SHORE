#ifndef POSTPROCESS_GLSL
#define POSTPROCESS_GLSL

#include "/lib/settings.glsl"

// Fonction utilitaire pour convertir RGB en luminance
float getLuminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

// Extraction des zones brillantes pour le bloom
vec3 getBloomSource(vec3 color) {
    float luminance = getLuminance(color);
    return max(color - BLOOM_THRESHOLD, 0.0);
}

// Convertir RGB en HSV
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// Convertir HSV en RGB
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Appliquer le décalage de teinte
vec3 applyHueShift(vec3 color) {
    // Convertir RGB en HSV
    vec3 hsv = rgb2hsv(color);
    
    // Appliquer le décalage de teinte (hue)
    hsv.x = fract(hsv.x + HUE_SHIFT); // fract pour garder la teinte dans [0,1]
    
    // Convertir HSV en RGB
    return hsv2rgb(hsv);
}

// Différents opérateurs de tone mapping
vec3 ACESToneMapping(vec3 color) {
    color *= EXPOSURE;
    
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    
    return clamp((color * (a * color + b)) / (color * (c * color + d) + e), 0.0, 1.0);
}

vec3 ReinhardToneMapping(vec3 color) {
    color *= EXPOSURE;
    return color / (1.0 + color);
}

vec3 FilmicToneMapping(vec3 color) {
    color *= EXPOSURE;
    
    vec3 x = max(vec3(0.0), color - 0.004);
    return (x * (6.2 * x + 0.5)) / (x * (6.2 * x + 1.7) + 0.06);
}

// Applique le tone mapping sélectionné
vec3 applyToneMapping(vec3 color) {
    #if TONEMAPPING_MODE == 1
        return ACESToneMapping(color);
    #elif TONEMAPPING_MODE == 2
        return ReinhardToneMapping(color);
    #elif TONEMAPPING_MODE == 3
        return FilmicToneMapping(color);
    #else
        return color * EXPOSURE; // Si désactivé, applique juste l'exposition
    #endif
}

// Ajustement du contraste
vec3 adjustContrast(vec3 color) {
    return mix(vec3(0.5), color, CONTRAST);
}

// Ajustement de la saturation
vec3 adjustSaturation(vec3 color) {
    float luminance = getLuminance(color);
    return mix(vec3(luminance), color, SATURATION);
}

// Ajustement de la vibrance (saturation sélective)
vec3 adjustVibrance(vec3 color) {
    // Calcul de la luminance (identique)
    float luminance = getLuminance(color);
    
    // Nouvelle approche plus robuste pour l'effet de vibrance
    float maxComponent = max(color.r, max(color.g, color.b));
    float minComponent = min(color.r, min(color.g, color.b));
    
    // Calcul plus stable de la saturation 
    float saturation = maxComponent > 0.0 ? (maxComponent - minComponent) / maxComponent : 0.0;
    
    // Calculer le facteur d'ajustement de manière plus conservatrice
    float amount = (1.0 - saturation) * VIBRANCE * 0.5;
    
    // Calculer le facteur de préservation de la teinte
    vec3 coefficients = (color - luminance) / max(maxComponent - luminance, 0.0001);
    
    // Assurer que les coefficients restent valides
    coefficients = clamp(coefficients, 0.0, 1.0);
    
    // Calculer la nouvelle couleur avec vibrance
    vec3 newColor = luminance + (color - luminance) * (1.0 + amount);
    
    // S'assurer que la couleur reste dans les limites valides
    newColor = clamp(newColor, 0.0, 1.0);
    
    return newColor;
}

// Fonction principale de post-traitement
vec3 applyPostProcess(vec3 color, vec3 bloomColor) {
    // Ajouter le bloom d'abord
    #if BLOOM_ENABLED == 1
        color += bloomColor * BLOOM_INTENSITY;
    #endif
    
    // Appliquer le hue shift avant les autres ajustements de couleur
    color = applyHueShift(color);
    
    // Ajuster ensuite la saturation et la vibrance
    color = adjustSaturation(color);
    color = adjustVibrance(color);
    
    // Appliquer le tone mapping après les ajustements de couleur
    color = applyToneMapping(color);
    
    // Appliquer le contraste en dernier
    color = adjustContrast(color);
    
    return color;
}

#endif // POSTPROCESS_GLSL