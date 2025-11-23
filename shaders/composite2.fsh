#version 120

#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/clouds_realistic.glsl"

varying vec2 texcoord;

vec3 projectanddivide(mat4 pm, vec3 p)
{
	vec4 hp = pm*vec4(p,1.);
	return hp.xyz/hp.w;
}

void main() {
	vec3 color = texture2D(colortex0, texcoord).rgb;
	float depth = texture2D(depthtex0, texcoord).r;
	
	// Sky mask
	if(depth == 1.0)
	{
		vec4 pos = vec4(texcoord, depth, 1.0) * 2.0 - 1.0; // ndc
		pos.xyz = projectanddivide(gbufferProjectionInverse, pos.xyz); // view pos
		pos = gbufferModelViewInverse * vec4(pos.xyz, 1.0); // feet position
		
		vec3 raydir = normalize(pos.xyz);
		
		// Utiliser la fonction renderRealisticClouds du fichier clouds_realistic.glsl
		vec4 clouds = renderRealisticClouds(raydir);
		
		// Blend clouds with sky
		color.rgb = mix(color.rgb, clouds.rgb, clouds.a);
	}

/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0); //gcolor
}