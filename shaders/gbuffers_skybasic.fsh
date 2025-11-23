#version 120

#include "/lib/uniforms.glsl"
#include "/lib/sky.glsl"

varying vec4 starData; // rgb = star color, a = flag for whether or not this pixel is a star.

void main() {
	vec3 color;
	if (starData.a > 0.5) {
		// Conserver le code des étoiles intact comme demandé
		color = starData.rgb;
		
		// Ajuster la luminosité des étoiles en fonction de l'heure
		float dayFactor = getDayFactor();
		float starVisibility = 1.0 - dayFactor;
		color *= starVisibility; 
	} else {
		// Utiliser la fonction améliorée pour le ciel
		color = getFinalSky();
	}

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0);
}