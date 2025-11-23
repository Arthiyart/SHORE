#version 120

#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/postprocess.glsl"

varying vec2 texcoord;

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;
    
    // Extraire les zones lumineuses pour le bloom
    #if BLOOM_ENABLED == 1
        vec3 bloomSource = getBloomSource(color);
    #else
        vec3 bloomSource = vec3(0.0);
    #endif
    
    /* DRAWBUFFERS:01 */
    gl_FragData[0] = vec4(color, 1.0);       // Conserver la couleur originale
    gl_FragData[1] = vec4(bloomSource, 1.0);  // Zones brillantes pour le bloom
}