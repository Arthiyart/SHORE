#ifndef SHADOW_DISTORTION_GLSL
#define SHADOW_DISTORTION_GLSL

// Applique une distorsion à la projection d'ombre pour optimiser l'utilisation
// de la résolution de la shadow map et réduire l'effet de "peter panning"
vec3 getShadowDistortion(vec3 shadowClipPos) {
  shadowClipPos.xy /= 0.8 * abs(shadowClipPos.xy) + 0.2;
  return shadowClipPos;
}

#endif // SHADOW_DISTORTION_GLSL
