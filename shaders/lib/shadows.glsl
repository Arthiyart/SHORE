#ifndef SHADOWS_GLSL
#define SHADOWS_GLSL

#include "/lib/settings.glsl"
#include "/lib/getShadowDistortion.glsl"

// Calcule la composante de diffusion lumineuse selon la normale et la position de la lumière
float calculateDiffuse(vec3 normal, vec3 lightPosition, float skyLight, float fogMix, float rainStrength, bool isThin) {
  // Réduire sous l'eau
  float diffuse = (isEyeInWater == 0 ? 1.0 : 0.5)
    // Réduire avec le brouillard
    * (1.0 - fogMix)
    // Réduire avec la pluie
    * (1.0 - rainStrength)
    // Réduire avec la lumière du ciel
    * clamp((skyLight - 0.3137) / (0.6235 - 0.3137), 0.0, 1.0);
    
  // Les objets fins ont une diffusion constante
  if (isThin) {
    return diffuse * 0.75;
  } else {
    return diffuse * clamp(2.5 * dot(normalize(normal), normalize(lightPosition)), -0.3333, 1.0);
  }
}

// Calcule la force de l'ombre basée sur la position dans le monde
float getShadowStrength(vec3 worldPos, vec3 normal, float diffuse, mat4 shadowModelView, mat4 shadowProjection, sampler2D shadowtex1) {
  // Précision des pixels (snap)
  #if SHADOW_PIXEL > 0
    vec3 pos = worldPos + cameraPosition;
    pos = pos * SHADOW_PIXEL;
    pos = floor(pos + 0.01) + 0.5;
    pos = pos / SHADOW_PIXEL - cameraPosition;
  #else
    vec3 pos = worldPos;
  #endif

  float posDistance = dot(pos, pos); // Squared length
  
  // Ne pas calculer les ombres au-delà de la distance maximale
  if (posDistance > SHADOW_MAX_DIST_SQUARED || diffuse <= 0.0) {
    return diffuse;
  }
  
  // Transformer la position vers l'espace de la shadow map
  vec4 shadowView = shadowModelView * vec4(pos, 1.0);
  vec4 shadowClip = shadowProjection * shadowView;
  
  // Appliquer la distortion aux coordonnées
  shadowClip.xyz = getShadowDistortion(shadowClip.xyz);
  
  // Convertir en coordonnées UV (0-1)
  vec3 shadowUV = shadowClip.xyz * 0.5 + 0.5;
  
  // Vérifier si le point est dans les limites de la shadow map
  if (shadowUV.z >= 1.0 || shadowUV.s <= 0.0 || shadowUV.s >= 1.0 || shadowUV.t <= 0.0 || shadowUV.t >= 1.0) {
    return diffuse;
  }
  
  // Échantillonner la profondeur et comparer
  float shadowFade = 1.0 - posDistance / SHADOW_MAX_DIST_SQUARED;
  float shadowDepth = texture2D(shadowtex1, shadowUV.st).x;
  
  // Comparaison avec biais pour éviter le shadow acne
  float shadowFactor = clamp(3.0 * (shadowDepth - shadowUV.z) / shadowProjection[2].z, 0.0, 1.0);
  
  return diffuse * (1.0 - shadowFade * shadowFactor);
}

// Obtient la couleur du soleil en fonction du temps
vec3 getSunColor(float worldTime, vec3 lightPosition, mat4 gbufferModelViewInverse, float skyLight) {
  const float NORMALIZE_TIME = 1.0/24000.0;
  const float NOON = 0.25;     // 6000
  const float SUNSET = 0.5325; // 12780
  const float MIDNIGHT = 0.75; // 18000
  const float SUNRISE = 0.9675; // 23220
  
  float x = worldTime * NORMALIZE_TIME;
  float y = x > SUNRISE ? (x - 1.0) - NOON : x - NOON;
  bool isDay = x > SUNRISE || x < SUNSET;
  
  // Rendre la lumière plus rouge au lever/coucher du soleil
	vec3 sunColor = isDay
		? normalize(vec3(1.0 + clamp(66.0*y*y - 3.7142, 0.12, 1.0), 1.06, 1.0))
		: vec3(0.1, 0.15, 0.3); // Couleur fixe de la lune (bleu froid)
  
  // Créer une transition entre les préréglages de couleur en fonction de la hauteur de la lumière
  sunColor *= clamp(0.1*(gbufferModelViewInverse * vec4(lightPosition, 1.0)).y - 0.4453, 0.0, 1.0);
  
  // Réduire la brillance des couleurs dans les zones sombres
  return mix(vec3(length(sunColor)), sunColor, skyLight);
}

#endif // SHADOWS_GLSL
