#ifndef GAUSSIAN_BLUR_GLSL
#define GAUSSIAN_BLUR_GLSL

#include "/lib/settings.glsl"

// Flou gaussien horizontal
vec3 blurHorizontal(sampler2D image, vec2 uv, float resolution) {
    vec3 blurred = vec3(0.0);
    float total = 0.0;
    
    for (float i = -BLOOM_RADIUS; i <= BLOOM_RADIUS; i += 1.0) {
        float weight = exp(-(i * i) / (2.0 * BLOOM_RADIUS * BLOOM_RADIUS));
        vec2 offset = vec2(i / resolution, 0.0);
        blurred += texture2D(image, uv + offset).rgb * weight;
        total += weight;
    }
    
    return blurred / total;
}

// Flou gaussien vertical
vec3 blurVertical(sampler2D image, vec2 uv, float resolution) {
    vec3 blurred = vec3(0.0);
    float total = 0.0;
    
    for (float i = -BLOOM_RADIUS; i <= BLOOM_RADIUS; i += 1.0) {
        float weight = exp(-(i * i) / (2.0 * BLOOM_RADIUS * BLOOM_RADIUS));
        vec2 offset = vec2(0.0, i / resolution);
        blurred += texture2D(image, uv + offset).rgb * weight;
        total += weight;
    }
    
    return blurred / total;
}

#endif // GAUSSIAN_BLUR_GLSL