#version 120

#include "/lib/settings.glsl"

uniform sampler2D texture;

varying vec2 texcoord;
varying float alpha;

void main() {
   vec4 albedo = texture2DLod(texture, texcoord, 0);
   
   albedo.a *= alpha;
   
   if (albedo.a < 0.1) {
      discard;
   }
   
   gl_FragData[0] = albedo;
}
