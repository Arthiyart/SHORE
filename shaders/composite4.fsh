#version 120

#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/gaussian_blur.glsl"

varying vec2 texcoord;

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;
    
    // Premier passage de flou (horizontal)
    #if BLOOM_ENABLED == 1
        vec3 bloomSource = texture2D(colortex1, texcoord).rgb;
        vec3 blurH = blurHorizontal(colortex1, texcoord, viewWidth);
    #else
        vec3 blurH = vec3(0.0);
    #endif
    
    /* DRAWBUFFERS:01 */
    gl_FragData[0] = vec4(color, 1.0);
    gl_FragData[1] = vec4(blurH, 1.0);
}