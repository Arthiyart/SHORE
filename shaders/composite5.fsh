#version 120

#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/gaussian_blur.glsl"

varying vec2 texcoord;

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;
    
    // Second passage de flou (vertical)
    #if BLOOM_ENABLED == 1
        vec3 blurH = texture2D(colortex1, texcoord).rgb;
        vec3 finalBloom = blurVertical(colortex1, texcoord, viewHeight);
    #else
        vec3 finalBloom = vec3(0.0);
    #endif
    
    /* DRAWBUFFERS:01 */
    gl_FragData[0] = vec4(color, 1.0);
    gl_FragData[1] = vec4(finalBloom, 1.0);
}