#version 120

#include "/lib/uniforms.glsl"
#include "/lib/settings.glsl"
#include "/lib/clouds_vanilla.glsl"

varying vec2 texcoord;
varying vec4 glcolor;
varying float vertexDistance;

void main() {
	vec4 color = texture2D(texture, texcoord) * glcolor;

	// Rendre les nuages vanilla invisibles lorsque CLOUD_STYLE = 1 (Realistic)
	#if CLOUD_STYLE == 1
		discard; // Discard le fragment = nuages invisibles
	#else
		// Facteurs temporels
		float dayFactor = getDayFactor();
		float transitionFactor = getTransitionFactor();
		
		// Ajouter une variation temporelle pour animation subtile
		float timeVary = sin(frameTimeCounter * 0.05) * 0.1 + 0.9;
		
		// Calculer le facteur de densité
		float densityFactor = CLOUD_DENSITY / 0.7;
		
		// Obtenir l'opacité des nuages en utilisant la fonction de clouds.glsl
		float cloudOpacity = getCloudOpacity(vertexDistance, densityFactor);
		
		// Appliquer l'opacité
		color.a *= cloudOpacity;

		// fog
		float fragmentDistance = vertexDistance;
		float fogFactor;
		float fogDensity = 1.0 + rainStrength * 0.5; // Plus dense quand il pleut
		
		// Modifier la densité du brouillard selon le moment de la journée
		fogDensity = mix(fogDensity * 1.3, fogDensity, dayFactor); // Brouillard plus dense la nuit
		
		float x = fragmentDistance * fogDensity;
		fogFactor = exp(-x * x);
		fogFactor = clamp(fogFactor, 0.0, 1.0);

		// Obtenir la couleur des nuages avec une légère modulation temporelle
		vec3 cloudColor = getClouds() * timeVary;
		
		// Assombrir les nuages quand il pleut
		cloudColor = mix(cloudColor, cloudColor * 0.7, rainStrength);

		// blend clouds color and sky
		color.rgb = mix(getFinalSky(), mix(cloudColor, color.rgb, 0.25), fogFactor);
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = color; //gcolor
}