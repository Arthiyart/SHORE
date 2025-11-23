#version 120

#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/transformations.glsl"
#include "/lib/getReflectionColor.glsl"
#include "/lib/postprocess.glsl"

varying vec2 texUV;

void main() {
   vec4 color = texture2D(colortex0, texUV);
   vec4 info  = texture2D(colortex7, texUV);
   
   // Traitement des réflexions (code existant)
   if (info.x > 0.99) {
      vec3 prenormal = texture2D(colortex6, texUV).xyz*2.0 - 1.0;

      #if WATER_WAVE_SIZE > 0
         if (info.y > 0.99 && abs(prenormal.y) > 0.8) {
            prenormal.xz *= 0.01 * WATER_WAVE_SIZE;
         }
      #endif

      float depth = texture2D(depthtex0, texUV).x;
      vec3 normal = world2screen(prenormal);
      vec3 fragPos = uv2screen(texUV, depth);
      vec4 reflectionColor = getReflectionColor(depth, normal, fragPos);
      float fresnel = 1.0 - dot(normal, -normalize(fragPos));

      color.rgb = mix(
         color.rgb,
         reflectionColor.rgb,
         reflectionColor.a * fresnel * 0.1*REFLECTIONS * (1.0 - color.rgb)
      );
   }
   
   // Récupérer le bloom
   #if BLOOM_ENABLED == 1
      vec3 bloom = texture2D(colortex1, texUV).rgb;
   #else
      vec3 bloom = vec3(0.0);
   #endif
   
   // Appliquer tous les effets de post-traitement
   color.rgb = applyPostProcess(color.rgb, bloom);

   gl_FragData[0] = color;
}