#ifndef GODRAYS_GLSL
#define GODRAYS_GLSL

#include "/lib/settings.glsl"

// Détection du ciel améliorée
float getSkyMask(sampler2D depthTex, vec2 uv, float brightness) {
    // Utiliser plusieurs échantillons et moyenner pour réduire le bruit
    float depth = texture2D(depthTex, uv).x;
    return (depth >= 0.999) ? brightness : 0.0;
}

// Flou gaussien simple pour adoucir les rayons
vec3 blurGodRays(vec3 rays, sampler2D colorTex, vec2 texCoord) {
    #if GODRAYS_BLUR == 0
        return rays;
    #endif
    
    float blurSize = 0.002 * GODRAYS_BLUR;
    vec3 blurred = rays;
    
    // Échantillonnage en croix (moins coûteux qu'un flou gaussien complet)
    blurred += texture2D(colorTex, texCoord + vec2(blurSize, 0.0)).rgb * 0.25;
    blurred += texture2D(colorTex, texCoord + vec2(-blurSize, 0.0)).rgb * 0.25;
    blurred += texture2D(colorTex, texCoord + vec2(0.0, blurSize)).rgb * 0.25;
    blurred += texture2D(colorTex, texCoord + vec2(0.0, -blurSize)).rgb * 0.25;
    
    return blurred / 2.0;
}

// Fonction principale pour calculer les god rays avec moins de bruit
vec3 calculateGodRays(
    vec2 texCoord,          // Coordonnées de texture
    vec3 sunPos,            // Position du soleil en espace d'écran 
    sampler2D depthTex,     // Texture de profondeur
    sampler2D noiseTex,     // Texture de bruit
    float dayFactor,        // Facteur jour/nuit
    float time              // Temps pour l'animation
) {
    #if GODRAYS_ENABLED == 0
        return vec3(0.0);
    #endif
    
    // Vérifier si le soleil est visible (au-dessus de l'horizon)
    float sunHeight = (gbufferModelViewInverse * vec4(normalize(sunPosition), 0.0)).y;
    
    // N'appliquer que si le soleil est visible et pendant la journée
    if(sunHeight < 0.01 || dayFactor < 0.05) 
        return vec3(0.0);
    
    // Calcul de la distance au soleil dans l'espace d'écran
    float distToSun = distance(texCoord, sunPos.xy);
    
    // N'appliquer que si la distance est inférieure au rayon configuré
    if(distToSun > GODRAYS_RADIUS) 
        return vec3(0.0);
    
    // Atténuation basée sur la distance au soleil
    float falloff = 1.0 - smoothstep(0.0, GODRAYS_RADIUS, distToSun);
    falloff = falloff * falloff; // Falloff quadratique
    
    // Utilisation de blue noise pour meilleur dithering
    float noise = texture2D(noiseTex, fract(texCoord * 20.0 + vec2(time * 0.01, time * 0.02))).r;
    
    // Direction vers le soleil
    vec2 sunDirection = normalize(sunPos.xy - texCoord) * 0.02;
    
    // La couleur configurée des rayons
    vec3 rayColor = vec3(GODRAYS_COLOR_R, GODRAYS_COLOR_G, GODRAYS_COLOR_B);
    
    // Facteur météo
    float weatherFactor = 1.0 - rainStrength * 0.8;
    
    // Force par échantillon (réduite pour moins de bruit)
    float stepStrength = GODRAYS_STRENGTH * 0.005 * weatherFactor;
    
    // Accumulateur
    float rayDensity = 0.0;
    
    // Position initiale avec dithering amélioré
    vec2 samplePos = texCoord + sunDirection * noise * 0.5;
    
    // Échantillonnage avec plus de points et distribution améliorée
    for(int i = 0; i < GODRAYS_SAMPLES; i++) {
        // Utiliser différents poids pour les échantillons (plus forts au centre)
        float weight = 1.0 - abs(float(i) / float(GODRAYS_SAMPLES) - 0.5) * 2.0;
        weight = weight * weight; // Distribution quadratique des poids
        
        // Ajouter la contribution pondérée
        rayDensity += getSkyMask(depthTex, samplePos, stepStrength) * weight;
        
        // Progression non-linéaire pour meilleure distribution des échantillons
        float step = float(i) / float(GODRAYS_SAMPLES - 1);
        step = step * step; // Progression quadratique
        
        // Avancer vers le soleil
        samplePos = texCoord + sunDirection * GODRAYS_LENGTH * step;
    }
    
    // Facteurs d'intensité
    float transitionFactor = getTransitionFactor();
    float sunsetFactor = getSunsetFactor();
    
    // Réduire progressivement les rayons pendant le coucher du soleil
    float sunsetAdjustment = 1.0;
    if(sunsetFactor > 0.0) {
        // Réduire l'intensité vers la fin du coucher de soleil
        sunsetAdjustment = max(0.0, 1.0 - (sunsetFactor * 3.0 - 1.0));
    }
    
    // Facteur d'angle du soleil
    float sunAngleFactor = mix(1.0, 3.0, transitionFactor * (1.0 - sunsetFactor * 0.5));
    
    // Force finale
    float finalStrength = rayDensity * sunAngleFactor * falloff * dayFactor * sunsetAdjustment;
    
    // Résultat avec intensité ajustée pour compenser l'échantillonnage de qualité
    return rayColor * finalStrength * 2.0;
}

#endif // GODRAYS_GLSL