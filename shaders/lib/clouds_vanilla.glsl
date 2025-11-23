#include "/lib/sky.glsl"
#include "/lib/settings.glsl"

#if SKY_COLOR == 3 // Dramatique (haute dynamique)
   vec3 getClouds() {
      vec3 normal = getNormal();
      // Variation directionnelle pour les nuages
      float dirFactor = normal.x * 0.5 + 0.5;
      
      // Facteurs temporels
      float dayFactor = getDayFactor();
      float transitionFactor = getTransitionFactor();
      float isSunset = getSunsetFactor() > 0.0 ? 1.0 : 0.0;
      
      // Teintes de jour
      vec3 dayBrightEdge = vec3(0.98, 0.82, 0.65); // Bord doré plus subtil
      vec3 dayDarkPart = vec3(0.75, 0.55, 0.65);   // Rose pâle plus harmonieux
      vec3 dayAccentColor = vec3(0.82, 0.65, 0.75); // Accent rosé plus doux
      
      // Teintes de nuit
      vec3 nightBrightEdge = vec3(0.3, 0.35, 0.45); // Bleu-gris
      vec3 nightDarkPart = vec3(0.2, 0.25, 0.35);   // Bleu foncé
      vec3 nightAccentColor = vec3(0.25, 0.3, 0.4); // Bleu-violet
      
      // Teintes lever de soleil
      vec3 sunriseBrightEdge = vec3(1.0, 0.8, 0.6); // Orange doré
      vec3 sunriseDarkPart = vec3(0.85, 0.6, 0.5);  // Rose-orange
      vec3 sunriseAccentColor = vec3(0.9, 0.7, 0.55); // Orange rosé
      
      // Teintes coucher de soleil
      vec3 sunsetBrightEdge = vec3(1.0, 0.75, 0.55); // Plus orangé
      vec3 sunsetDarkPart = vec3(0.8, 0.5, 0.45);    // Plus pourpre
      vec3 sunsetAccentColor = vec3(0.85, 0.6, 0.5); // Plus violacé
      
      // Sélection des couleurs de transition
      vec3 transBrightEdge = mix(sunriseBrightEdge, sunsetBrightEdge, isSunset);
      vec3 transDarkPart = mix(sunriseDarkPart, sunsetDarkPart, isSunset);
      vec3 transAccentColor = mix(sunriseAccentColor, sunsetAccentColor, isSunset);
      
      // Mélange jour/nuit
      vec3 brightEdge = mix(nightBrightEdge, dayBrightEdge, dayFactor);
      vec3 darkPart = mix(nightDarkPart, dayDarkPart, dayFactor);
      vec3 accentColor = mix(nightAccentColor, dayAccentColor, dayFactor);
      
      // Mélange avec transition
      brightEdge = mix(brightEdge, transBrightEdge, transitionFactor);
      darkPart = mix(darkPart, transDarkPart, transitionFactor);
      accentColor = mix(accentColor, transAccentColor, transitionFactor);
      
      // Mélange multi-tons pour nuages élégants
      float t = smoothstep(0.2, 0.8, abs(normal.y));
      vec3 baseCloud = mix(brightEdge, darkPart, t);
      
      // Ajout d'un accent subtil pour plus d'élégance
      vec3 cloudColor = mix(baseCloud, accentColor, pow(dirFactor, 2.0) * (1.0 - t) * 0.25);
      
      // Ajuster la luminosité en fonction de la densité des nuages
      float densityFactor = CLOUD_DENSITY / 0.7; // Normalisation par rapport à la valeur par défaut de 0.7
      cloudColor *= (1.2 - densityFactor * 0.2); // Nuages plus denses sont légèrement plus sombres
      
      return cloudColor;
   }

#elif SKY_COLOR == 2 // Esthétique (pastel)
   vec3 getClouds() {
      // Facteurs temporels
      float dayFactor = getDayFactor();
      float transitionFactor = getTransitionFactor();
      float isSunset = getSunsetFactor() > 0.0 ? 1.0 : 0.0;
      
      // Couleurs de jour - plus rosées
      vec3 dayCloudColor = vec3(0.98, 0.94, 0.97);
      
      // Couleurs de nuit - plus violettes
      vec3 nightCloudColor = vec3(0.4, 0.38, 0.5);
      
      // Couleurs lever de soleil - plus chaudes
      vec3 sunriseCloudColor = vec3(0.99, 0.9, 0.88);
      
      // Couleurs coucher de soleil - plus rosées
      vec3 sunsetCloudColor = vec3(0.98, 0.87, 0.85);
      
      // Sélection des couleurs de transition
      vec3 transCloudColor = mix(sunriseCloudColor, sunsetCloudColor, isSunset);
      
      // Mélange jour/nuit
      vec3 cloudColor = mix(nightCloudColor, dayCloudColor, dayFactor);
      
      // Mélange avec transition
      cloudColor = mix(cloudColor, transCloudColor, transitionFactor);
      
      // Ajuster la luminosité en fonction de la densité des nuages
      float densityFactor = CLOUD_DENSITY / 0.7;
      cloudColor *= (1.1 - densityFactor * 0.1);
      
      return cloudColor;
   }
   
#elif SKY_COLOR == 1 // Fantaisiste (dégradé)
   vec3 getClouds() {
      vec3 normal = getNormal();
      float t = clamp(normal.x * 0.5 + 0.5, 0.0, 1.0);
      
      // Facteurs temporels
      float dayFactor = getDayFactor();
      float transitionFactor = getTransitionFactor();
      float isSunset = getSunsetFactor() > 0.0 ? 1.0 : 0.0;
      
      // Couleurs de jour
      vec3 dayCloud1 = vec3(0.95, 0.8, 0.7);
      vec3 dayCloud2 = vec3(0.8, 0.7, 0.9);
      
      // Couleurs de nuit
      vec3 nightCloud1 = vec3(0.3, 0.35, 0.45);
      vec3 nightCloud2 = vec3(0.25, 0.3, 0.5);
      
      // Couleurs lever de soleil
      vec3 sunriseCloud1 = vec3(0.98, 0.8, 0.7);
      vec3 sunriseCloud2 = vec3(0.9, 0.75, 0.85);
      
      // Couleurs coucher de soleil
      vec3 sunsetCloud1 = vec3(0.97, 0.75, 0.65);
      vec3 sunsetCloud2 = vec3(0.85, 0.7, 0.8);
      
      // Sélection des couleurs de transition
      vec3 transCloud1 = mix(sunriseCloud1, sunsetCloud1, isSunset);
      vec3 transCloud2 = mix(sunriseCloud2, sunsetCloud2, isSunset);
      
      // Mélange jour/nuit
      vec3 cloud1 = mix(nightCloud1, dayCloud1, dayFactor);
      vec3 cloud2 = mix(nightCloud2, dayCloud2, dayFactor);
      
      // Mélange avec transition
      cloud1 = mix(cloud1, transCloud1, transitionFactor);
      cloud2 = mix(cloud2, transCloud2, transitionFactor);
      
      vec3 cloudColor = mix(cloud1, cloud2, t);
      
      // Ajuster la luminosité et la saturation en fonction de la densité des nuages
      float densityFactor = CLOUD_DENSITY / 0.7;
      cloudColor *= (1.1 - densityFactor * 0.1);
      
      // Ajuster également la saturation pour les nuages fantaisistes
      cloudColor = mix(vec3((cloudColor.r + cloudColor.g + cloudColor.b) / 3.0), cloudColor, 1.0 - (densityFactor - 1.0) * 0.2);
      
      return cloudColor;
   }
   
#else // Réaliste
   vec3 getClouds() {
      // Facteurs temporels
      float dayFactor = getDayFactor();
      float transitionFactor = getTransitionFactor();
      float isSunset = getSunsetFactor() > 0.0 ? 1.0 : 0.0;
      
      // Couleurs de jour
      vec3 dayCloudColor = vec3(0.95);
      
      // Couleurs de nuit
      vec3 nightCloudColor = vec3(0.25, 0.27, 0.3);
      
      // Couleurs lever de soleil
      vec3 sunriseCloudColor = vec3(0.95, 0.85, 0.75);
      
      // Couleurs coucher de soleil
      vec3 sunsetCloudColor = vec3(0.9, 0.8, 0.7);
      
      // Sélection des couleurs de transition
      vec3 transCloudColor = mix(sunriseCloudColor, sunsetCloudColor, isSunset);
      
      // Mélange jour/nuit
      vec3 cloudColor = mix(nightCloudColor, dayCloudColor, dayFactor);
      
      // Mélange avec transition
      cloudColor = mix(cloudColor, transCloudColor, transitionFactor);
      
      // Ajuster la luminosité en fonction de la densité des nuages
      float densityFactor = CLOUD_DENSITY / 0.7;
      cloudColor *= (1.05 - densityFactor * 0.05);
      
      return cloudColor;
   }
   
#endif

// Fonction pour calculer l'opacité des nuages
float getCloudOpacity(float distance, float densityFactor) {
    // Facteurs temporels
    float dayFactor = getDayFactor();
    
    // Base opacity calculation
    float baseOpacity = clamp(0.3 + 0.7 * (1.0 - distance * 0.1), 0.0, 1.0);
    
    // Scale by density
    baseOpacity *= densityFactor;
    
    // Légère variation d'opacité entre jour et nuit (plus transparents la nuit)
    baseOpacity = mix(baseOpacity * 0.85, baseOpacity, dayFactor);
    
    // Adjust for rain
    baseOpacity = mix(baseOpacity, baseOpacity * 1.5, rainStrength);
    
    return baseOpacity;
}