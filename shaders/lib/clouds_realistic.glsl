#include "/lib/settings.glsl"
#include "/lib/sky.glsl"

// Fonction de bruit améliorée pour plus de détail
float random(in vec2 p)
{
	// Utilisation de la seed pour modifier les coordonnées
	vec2 seeded_p = p;
	if (CLOUD_SEED > 0) {
		// Utiliser différentes valeurs selon la seed
		float seedValue = float(CLOUD_SEED) * 12.345;
		seeded_p += vec2(cos(seedValue), sin(seedValue)) * 100.0;
	}
	return fract(sin(dot(seeded_p, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 smoothv2(in vec2 v)
{
	return v*v*(3.-2.*v);
}

float smooth_noise(in vec2 p)
{
	vec2 f = smoothv2(fract(p));
	float a = random(floor(p));
	float b = random(vec2(ceil(p.x),floor(p.y)));
	float c = random(vec2(floor(p.x),ceil(p.y)));	
	float d = random(ceil(p));
	
	return mix(	mix(a,b,f.x),	mix(c,d,f.x),	f.y);
}

// Bruit fractal amélioré avec nombre d'octaves configurable
float fractal_noise(in vec2 p)
{
	float total = 0.5;
	float amplitude = 1.0;
	float frequency = 1.0;
	// Utilise CLOUD_DETAIL pour le nombre d'octaves
	float iterations = float(CLOUD_DETAIL);
	for(float i= 0; i < iterations; i++)
	{
		total += (smooth_noise(p*frequency)-.5)*amplitude;
		amplitude *= 0.45; // Atténuation plus lente pour plus de détails
		frequency *= 2.2; // Facteur légèrement plus élevé pour variations
	}
	
	// Normalisation pour que différents niveaux de détail donnent une intensité similaire
	return clamp(total * (1.0 + (6.0 - iterations) * 0.05), 0.0, 1.0);
}

// Fonction supplémentaire pour varier la forme des nuages
float cloud_shape(in vec2 p, in float time)
{
    // Appliquer des modifications basées sur la seed
    vec2 seeded_p = p;
    float seeded_time = time;
    if (CLOUD_SEED > 0) {
        // Chaque seed donne une rotation et un décalage différents
        float angle = float(CLOUD_SEED) * 0.2;
        float c = cos(angle);
        float s = sin(angle);
        seeded_p = vec2(
            p.x * c - p.y * s,
            p.x * s + p.y * c
        );
        
        // Modifier aussi la vitesse d'évolution selon la seed
        seeded_time = time + float(CLOUD_SEED) * 10.0;
    }
    
    float noise1 = fractal_noise(seeded_p);
    float noise2 = fractal_noise(seeded_p * 1.5 + vec2(seeded_time * 0.01, 0.0));
    
    // Mélange des bruits pour créer des formes plus organiques
    // Le ratio de mélange varie légèrement avec la seed
    float mixRatio = 0.35;
    if (CLOUD_SEED > 0) {
        mixRatio = 0.3 + float(CLOUD_SEED % 10) * 0.01;
    }
    
    return mix(noise1, noise2, mixRatio);
}

// Fonction pour calculer la couleur des nuages réalistes
vec4 getRealisticClouds(vec3 raydir, float frameTime) {
    // Variables pour contrôler la parallaxe et la hauteur des nuages
    float cloudScale = 0.8 + rainStrength * 0.4; // Nuages plus denses quand il pleut
    
    // Layer 1 - nuages principaux
    vec2 uv1 = raydir.xz * cloudScale / max(raydir.y, 0.001) + 0.05 * frameTime * CLOUD_SPEED;
    
    // Layer 2 - détails haute fréquence
    vec2 uv2 = raydir.xz * 3.0 * cloudScale / max(raydir.y, 0.001) - 0.02 * frameTime * CLOUD_PERMUTATION_SPEED;
    
    // Layer 3 - très haute fréquence pour texture fine
    vec2 uv3 = raydir.xz * 7.0 * cloudScale / max(raydir.y, 0.001) + 0.08 * frameTime * CLOUD_SPEED;
    
    // Add clouds
    vec4 clouds = vec4(0.0);
    if(raydir.y > 0.0) {
        // Forme de base des nuages
        float cloudBase = cloud_shape(uv1, frameTime);
        
        // Détails haute fréquence
        float cloudDetail = fractal_noise(uv2);
        
        // Très haute fréquence pour texture fine
        float cloudFine = fractal_noise(uv3) * 0.2;
        
        // Combiner les couches
        float cloudValue = cloudBase;
        cloudValue = cloudValue * 0.8 + cloudDetail * 0.2;
        cloudValue = cloudValue * 0.9 + cloudFine * 0.1;
        
        clouds = vec4(cloudValue);
    }
    
    return clouds;
}

// Fonction pour calculer le facteur de brouillard des nuages
float getCloudFogFactor(vec3 raydir) {
    // Facteur de brouillard pour nuages lointains - calcul amélioré avec progression naturelle
    float skyHeight = max(raydir.y, 0.001);
    float distanceFromCamera = 1.0 / skyHeight;
    
    // Paramètres de distance contrôlés par CLOUD_FOG_DISTANCE
    float fogStartDistance = 3.0;  // Début du fondu un peu plus près pour assurer visibilité des nuages proches
    float fogEndDistance = 10.0 + CLOUD_FOG_DISTANCE * 15.0;
    
    // Normaliser la distance pour calculer un facteur entre 0 et 1
    float normalizedDistance = clamp((distanceFromCamera - fogStartDistance) / (fogEndDistance - fogStartDistance), 0.0, 1.0);
    
    // Courbe de progression garantissant une transition graduelle
    // CLOUD_FOG_INTENSITY contrôle la pente de la courbe, pas le principe de progression
    float intensityFactor = max(0.5, CLOUD_FOG_INTENSITY); // Assurer une valeur minimale pour éviter fondu trop abrupt
    
    // Fonction sigmoïde modifiée pour garantir une progression douce
    // Cette fonction garantit une courbe en S avec une pente contrôlée par intensityFactor
    float fogFactor = 1.0 / (1.0 + exp(-(normalizedDistance - 0.5) * 5.0 * intensityFactor));
    
    // Ajustement supplémentaire pour s'assurer que les nuages proches restent visibles
    // et que les nuages lointains deviennent progressivement invisibles
    return fogFactor * min(1.0, distanceFromCamera / fogStartDistance);
}

// Fonction pour obtenir la couleur finale des nuages en fonction des paramètres
vec3 getCloudColor(float cloudValue) {
    // Jour/nuit et facteurs de transition
    float dayFactor = getDayFactor();
    float transitionFactor = getTransitionFactor();
    float isSunset = getSunsetFactor() > 0.0 ? 1.0 : 0.0;
    
    // Facteur de densité basé sur le paramètre CLOUD_DENSITY
    float densityFactor = CLOUD_DENSITY / 0.7;
    
    #if SKY_COLOR == 3 // Dramatique (haute dynamique)
        // Teintes de jour
        vec3 dayCloudColor = vec3(0.98, 0.82, 0.65);
        
        // Teintes de nuit - assombries
        vec3 nightCloudColor = vec3(0.18, 0.22, 0.32);
        
        // Teintes lever/coucher de soleil - coucher plus sombre
        vec3 sunriseCloudColor = vec3(1.0, 0.7, 0.75);
        vec3 sunsetCloudColor = vec3(0.85, 0.55, 0.6);
        
    #elif SKY_COLOR == 2 // Esthétique (pastel)
        // Couleurs de jour - plus rosées
        vec3 dayCloudColor = vec3(0.98, 0.94, 0.97);
        
        // Couleurs de nuit - plus violettes et assombries
        vec3 nightCloudColor = vec3(0.25, 0.22, 0.35);
        
        // Couleurs lever/coucher de soleil - coucher plus sombre
        vec3 sunriseCloudColor = vec3(1.0, 0.85, 0.9);
        vec3 sunsetCloudColor = vec3(0.85, 0.68, 0.75);
        
    #elif SKY_COLOR == 1 // Fantaisiste (dégradé)
        // Couleurs de jour
        vec3 dayCloudColor = vec3(0.95, 0.8, 0.7);
        
        // Couleurs de nuit - assombries
        vec3 nightCloudColor = vec3(0.2, 0.22, 0.32);
        
        // Couleurs lever/coucher de soleil - coucher plus sombre
        vec3 sunriseCloudColor = vec3(1.0, 0.75, 0.82);
        vec3 sunsetCloudColor = vec3(0.82, 0.58, 0.65);
        
    #else // Réaliste (par défaut)
        // Couleurs de jour
        vec3 dayCloudColor = vec3(0.95);
        
        // Couleurs de nuit - assombries
        vec3 nightCloudColor = vec3(0.15, 0.17, 0.22);
        
        // Couleurs lever/coucher de soleil - coucher plus sombre
        vec3 sunriseCloudColor = vec3(0.97, 0.82, 0.8);
        vec3 sunsetCloudColor = vec3(0.8, 0.65, 0.62);
    #endif
    
    // Sélection des couleurs de transition
    vec3 transCloudColor = mix(sunriseCloudColor, sunsetCloudColor, isSunset);
    
    // Mélange jour/nuit
    vec3 cloudColor = mix(nightCloudColor, dayCloudColor, dayFactor);
    
    // Mélange avec transition (assombrir si coucher de soleil)
    float sunsetDarkeningFactor = isSunset * 0.15; // 15% plus sombre au coucher qu'au lever
    cloudColor = mix(cloudColor, transCloudColor, transitionFactor) * (1.0 - sunsetDarkeningFactor * transitionFactor);
    
    // Ajuster luminosité en fonction de la densité
    cloudColor *= (1.05 - densityFactor * 0.05);
    
    // Ombrage pour donner du volume
    cloudColor *= 1.0 - clamp((cloudValue - 0.5) * 0.2, 0.0, 0.3);
    
    // Ajuster luminosité quand il pleut
    return cloudColor * mix(1.0, 0.7, rainStrength);
}

// Fonction pour appliquer les trous aux nuages
float applyCloudHoles(float cloudValue) {
    // Facteur de densité basé sur le paramètre CLOUD_DENSITY
    float densityFactor = CLOUD_DENSITY / 0.7;
    
    // Faire des trous et ajuster la densité
    // Utilisation du paramètre CLOUD_HOLES pour contrôler la densité des trous
    // La valeur est adaptée en fonction de la pluie
    float cloudThreshold = CLOUD_HOLES * (1.0 - rainStrength * 0.8);
    
    // Quand il pleut beaucoup, réduire davantage le nombre de trous
    if (rainStrength > 0.7) {
        cloudThreshold *= (1.0 - (rainStrength - 0.7) * 0.8);
    }
    
    return clamp((cloudValue - cloudThreshold) * 4.0 * densityFactor, 0.0, 2.0);
}

// Fonction pour ajouter des variations à la couleur des nuages
vec3 addCloudColorVariation(vec3 cloudColor, vec2 uv) {
    // Ajout de légères variations de couleurs pour plus de réalisme
    float colorVariation = fractal_noise(uv * 2.0) * 0.05;
    return cloudColor + colorVariation * vec3(0.02, 0.01, 0.03);
}

// Fonction principale pour le rendu complet des nuages réalistes
vec4 renderRealisticClouds(vec3 raydir) {
    // Obtenir les nuages bruts
    vec4 clouds = getRealisticClouds(raydir, frameTimeCounter);
    
    // Calculer le facteur de brouillard
    float fogFactor = getCloudFogFactor(raydir);
    
    // Appliquer les trous aux nuages
    clouds.a = applyCloudHoles(clouds.a);
    
    // Obtenir la couleur des nuages
    clouds.rgb = getCloudColor(clouds.a);
    
    // Ajouter des variations de couleur
    vec2 uv1 = raydir.xz * (0.8 + rainStrength * 0.4) / max(raydir.y, 0.001) + 0.05 * frameTimeCounter * CLOUD_SPEED;
    clouds.rgb = addCloudColorVariation(clouds.rgb, uv1);
    
    // Calculer l'opacité finale avec le facteur de brouillard
    float finalOpacity = min(clouds.a, 1.0) * (1.0 - fogFactor);
    
    // Retourner les nuages avec l'opacité finale
    return vec4(clouds.rgb, finalOpacity);
}