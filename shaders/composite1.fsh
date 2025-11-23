#version 120

#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/sky.glsl"
#include "/lib/godrays.glsl"

varying vec2 texcoord;

// Convertir un vecteur de l'espace vue à l'espace écran
vec3 viewToScreen(vec3 viewPos) {
    vec4 clipPos = gbufferProjection * vec4(viewPos, 1.0);
    vec3 screenPos = clipPos.xyz / clipPos.w;
    return screenPos * 0.5 + 0.5;
}

// Vérifier si c'est la nuit ou le jour pour les god rays
bool isDayForGodRays() {
    float time = worldTime / 24000.0;
    
    // Jour: entre 23900-24000 et 0-12000 (approximativement)
    if ((time > 0.996 || time < 0.5)) {
        return true;
    }
    
    return false;
}

void main() {
    // Lire la couleur actuelle de la scène
    vec3 color = texture2D(colortex0, texcoord).rgb;
    vec3 godRaysColor = vec3(0.0); // Pour stocker les god rays séparément
    
    #if GODRAYS_ENABLED == 1
        // Vérifier explicitement si c'est le jour
        if (isDayForGodRays()) {
            // Obtenir le facteur jour/nuit standard
            float dayFactor = getDayFactor();
            
            // Obtenir la position du soleil en espace écran
            vec3 sunPos = viewToScreen(normalize(sunPosition));
            
            // Vérifier si le soleil est au-dessus de l'horizon
            float sunHeight = (gbufferModelViewInverse * vec4(normalize(sunPosition), 0.0)).y;
            
            // N'appliquer que si le soleil est au-dessus de l'horizon
            if (sunHeight > 0.01) {
                // Calculer les god rays de base
                vec3 rays = calculateGodRays(texcoord, sunPos, depthtex0, noisetex, dayFactor, frameTimeCounter);
                
                // Si le flou est activé et que ce n'est pas le premier frame
                if (GODRAYS_BLUR > 0 && frameCounter > 0) {
                    // Appliquer le flou pour réduire le bruit
                    rays = blurGodRays(rays, colortex1, texcoord);
                }
                
                // Stocker les rayons pour le buffer et les ajouter à la couleur
                godRaysColor = rays;
                color += godRaysColor;
            }
        }
    #endif
    
    /* DRAWBUFFERS:01 */
    gl_FragData[0] = vec4(color, 1.0);            // Scène avec god rays
    gl_FragData[1] = vec4(godRaysColor, 1.0);     // Stocker les god rays pour le flou
}