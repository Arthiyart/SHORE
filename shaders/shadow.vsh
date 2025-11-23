#version 120

#include "/lib/settings.glsl"
#include "/lib/getShadowDistortion.glsl"

varying vec2 texcoord;
varying float alpha;

void main() {
   gl_Position = ftransform();
   gl_Position.xyz = getShadowDistortion(gl_Position.xyz);
   
   texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
   alpha = gl_Color.a;
}
