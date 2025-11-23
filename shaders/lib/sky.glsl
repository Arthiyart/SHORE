#include "/lib/settings.glsl"

// Fonctions temporelles pour le cycle jour/nuit
float getDayTime() {
    // Convertit worldTime (0-24000) en valeur entre 0.0 et 1.0
    return mod(worldTime, 24000) / 24000.0;
}

// Fonction pour calculer un temps circulaire sans discontinuité à minuit
float getWrappedTime(float centerTime, float width) {
    float time = getDayTime();
    float distFromCenter = abs(time - centerTime);
    
    // Si la distance est plus grande que 0.5, c'est qu'on est plus proche
    // en passant de l'autre côté de minuit
    if (distFromCenter > 0.5) {
        distFromCenter = 1.0 - distFromCenter;
    }
    
    // Retourne 1.0 au centre et 0.0 à distance 'width'
    return 1.0 - smoothstep(0.0, width, distFromCenter);
}

float getDayFactor() {
    float time = getDayTime();
    float dayFactor;
    
    // Jour complet: 0.075 à 0.5 (1800 à 12000 ticks)
    // Nuit complète: 0.58 à 0.92 (14000 à 22000 ticks)
    // Lever de soleil: 0.92 à 0.075 (22000 à 1800 ticks, en passant par minuit)
    // Coucher de soleil: 0.5 à 0.58 (12000 à 14000 ticks)
    
    // Si on est entre 0.075 et 0.5, c'est le jour
    if (time >= 0.075 && time <= 0.5) {
        dayFactor = 1.0;
    }
    // Si on est entre 0.58 et 0.92, c'est la nuit
    else if (time >= 0.58 && time <= 0.92) {
        dayFactor = 0.0;
    }
    // Transition jour->nuit (coucher)
    else if (time > 0.5 && time < 0.58) {
        dayFactor = 1.0 - smoothstep(0.5, 0.58, time);
    }
    // Transition nuit->jour (lever) qui traverse minuit
    else {
        // Avant minuit (0.92 à 1.0)
        if (time > 0.92) {
            // Progression de 0 à 0.33 (premier tiers du lever)
            dayFactor = smoothstep(0.92, 1.0, time) * 0.33;
        } 
        // Après minuit (0.0 à 0.075)
        else {
            // Progression de 0.33 à 1.0 (deux derniers tiers du lever)
            dayFactor = 0.33 + smoothstep(0.0, 0.075, time) * 0.67;
        }
    }
    
    // Réduire l'intensité sous la pluie
    dayFactor = mix(dayFactor, dayFactor * 0.7, rainStrength);
    
    // Compenser avec night vision
    dayFactor = mix(dayFactor, 1.0, nightVision);
    
    return dayFactor;
}

float getSunriseFactor() {
    float time = getDayTime();
    
    // Lever de soleil de 0.92 à 0.075 (22000 à 1800 ticks), en passant par minuit
    float factor = 0.0;
    
    // Avant minuit (0.92 à 1.0)
    if (time >= 0.92 && time <= 1.0) {
        // Début du lever de soleil avant minuit
        factor = smoothstep(0.92, 0.97, time);
    } 
    // Après minuit (0.0 à 0.075)
    else if (time >= 0.0 && time <= 0.075) {
        // Maximum au milieu de la transition, puis diminution
        factor = 1.0 - smoothstep(0.03, 0.075, time);
    }
    
    return factor;
}

float getSunsetFactor() {
    float time = getDayTime();
    // Coucher de soleil: 0.48 - 0.58 (11500 - 14000)
    return smoothstep(0.48, 0.52, time) * (1.0 - smoothstep(0.54, 0.58, time));
}

float getTransitionFactor() {
    // Combine les facteurs d'aube et de crépuscule
    float sunriseFactor = getSunriseFactor();
    float sunsetFactor = getSunsetFactor();
    return max(sunriseFactor, sunsetFactor);
}

vec3 getNormal() {
   vec4 pos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight) * 2.0 - 1.0, 1.0, 1.0);
   pos = gbufferProjectionInverse * pos;
   return normalize((gbufferModelViewInverse * pos).rgb);
}

// Fonction pour calculer la diffusion atmosphérique de Rayleigh
vec3 calculateAtmosphericScattering(vec3 rayDir, vec3 sunDir) {
    const float rayleighStrength = 0.5;
    
    // Calcul du facteur de diffusion basé sur l'angle entre le rayon et le soleil
    float cosTheta = dot(rayDir, sunDir);
    float rayleighFactor = 0.75 * (1.0 + cosTheta * cosTheta);
    
    // Couleurs de diffusion adaptées au moment de la journée
    float dayFactor = getDayFactor();
    float transitionFactor = getTransitionFactor();
    
    // Variations de couleurs selon le moment
    vec3 daytimeScatter = vec3(0.3, 0.5, 1.0);
    vec3 nightScatter = vec3(0.1, 0.2, 0.4);
    vec3 sunriseScatter = vec3(0.8, 0.5, 0.3);
    vec3 sunsetScatter = vec3(0.9, 0.4, 0.2);
    
    // Mélange entre le jour et la nuit
    vec3 scatterColor = mix(nightScatter, daytimeScatter, dayFactor);
    
    // Ajouter les teintes de lever/coucher
    vec3 transitionColor = mix(sunriseScatter, sunsetScatter, getSunsetFactor() > 0.0);
    scatterColor = mix(scatterColor, transitionColor, transitionFactor);
    
    // Plus forte diffusion à l'horizon
    float horizonFactor = 1.0 - abs(rayDir.y);
    horizonFactor = pow(horizonFactor, 2.0);
    
    return scatterColor * rayleighStrength * rayleighFactor * horizonFactor;
}

#if SKY_COLOR == 3 // Dramatique (haute dynamique)
   vec3 getSky() {
      vec3 normal = getNormal();
      // Ciel dramatique avec forte dynamique mais plus harmonieux
      float horizon = pow(1.0 - abs(normal.y), 3.0);
      
      // Direction pour variation horizontale (est-ouest)
      float direction = normal.x * 0.5 + 0.5;
      
      // Facteurs temporels
      float dayFactor = getDayFactor();
      float transitionFactor = getTransitionFactor();
      float isSunset = getSunsetFactor() > 0.0 ? 1.0 : 0.0;
      
      // Jour - couleurs plus harmonieuses mais toujours dynamiques
      vec3 dayZenith = vec3(0.15, 0.25, 0.55);
      vec3 dayHorizonBase = vec3(0.85, 0.55, 0.45);
      vec3 dayHorizonAccent = vec3(0.95, 0.75, 0.45);
      vec3 dayMidColor = vec3(0.45, 0.35, 0.65);
      
      // Nuit - couleurs profondes mais détaillées
      vec3 nightZenith = vec3(0.02, 0.05, 0.15);
      vec3 nightHorizonBase = vec3(0.1, 0.15, 0.3);
      vec3 nightHorizonAccent = vec3(0.15, 0.2, 0.4);
      vec3 nightMidColor = vec3(0.08, 0.1, 0.25);
      
      // Lever de soleil
      vec3 sunriseZenith = vec3(0.2, 0.2, 0.45);
      vec3 sunriseHorizonBase = vec3(0.95, 0.65, 0.4);
      vec3 sunriseHorizonAccent = vec3(1.0, 0.8, 0.4);
      vec3 sunriseMidColor = vec3(0.5, 0.3, 0.4);
      
      // Coucher de soleil - légèrement plus rouge que le lever
      vec3 sunsetZenith = vec3(0.2, 0.15, 0.4);
      vec3 sunsetHorizonBase = vec3(0.95, 0.5, 0.3);
      vec3 sunsetHorizonAccent = vec3(1.0, 0.7, 0.3);
      vec3 sunsetMidColor = vec3(0.55, 0.25, 0.35);
      
      // Sélection des couleurs de transition selon sunrise/sunset
      vec3 transZenith = mix(sunriseZenith, sunsetZenith, isSunset);
      vec3 transHorizonBase = mix(sunriseHorizonBase, sunsetHorizonBase, isSunset);
      vec3 transHorizonAccent = mix(sunriseHorizonAccent, sunsetHorizonAccent, isSunset);
      vec3 transMidColor = mix(sunriseMidColor, sunsetMidColor, isSunset);
      
      // Mélange jour/nuit
      vec3 zenithColor = mix(nightZenith, dayZenith, dayFactor);
      vec3 horizonBaseColor = mix(nightHorizonBase, dayHorizonBase, dayFactor);
      vec3 horizonAccentColor = mix(nightHorizonAccent, dayHorizonAccent, dayFactor);
      vec3 midColor = mix(nightMidColor, dayMidColor, dayFactor);
      
      // Mélange avec transition (lever/coucher)
      zenithColor = mix(zenithColor, transZenith, transitionFactor);
      horizonBaseColor = mix(horizonBaseColor, transHorizonBase, transitionFactor);
      horizonAccentColor = mix(horizonAccentColor, transHorizonAccent, transitionFactor);
      midColor = mix(midColor, transMidColor, transitionFactor);
      
      // Mélange final des couleurs d'horizon selon direction
      vec3 horizonColor = mix(horizonBaseColor, horizonAccentColor, smoothstep(0.2, 0.8, direction));
      
      // Teinte intermédiaire
      float midSky = smoothstep(0.1, 0.4, abs(normal.y - 0.3)) * 0.7;
      
      // Construction finale avec transitions adoucies
      vec3 finalColor = mix(zenithColor, midColor, midSky);
      return mix(finalColor, horizonColor, smoothstep(0.1, 0.9, horizon));
   }
   
#elif SKY_COLOR == 2 // Esthétique (pastel)
   vec3 getSky() {
      vec3 normal = getNormal();
      float t = clamp(normal.y * 0.3 + 0.1, 0.0, 1.0);
      
      // Facteurs temporels
      float dayFactor = getDayFactor();
      float transitionFactor = getTransitionFactor();
      float isSunset = getSunsetFactor() > 0.0 ? 1.0 : 0.0;
      
      // Couleurs pastel de jour - plus rosé
      vec3 dayZenith = vec3(0.85, 0.91, 0.98);
      vec3 dayHorizon = vec3(0.98, 0.82, 0.9);
      
      // Couleurs pastel de nuit - plus profondes avec touches violettes
      vec3 nightZenith = vec3(0.15, 0.18, 0.35);
      vec3 nightHorizon = vec3(0.32, 0.28, 0.48);
      
      // Couleurs lever de soleil - plus rosées et vibrantes
      vec3 sunriseZenith = vec3(0.85, 0.82, 0.95);
      vec3 sunriseHorizon = vec3(0.98, 0.82, 0.9);
      
      // Couleurs coucher de soleil - plus intenses
      vec3 sunsetZenith = vec3(0.8, 0.75, 0.85);
      vec3 sunsetHorizon = vec3(0.98, 0.8, 0.85);
      
      // Sélection des couleurs de transition
      vec3 transZenith = mix(sunriseZenith, sunsetZenith, isSunset);
      vec3 transHorizon = mix(sunriseHorizon, sunsetHorizon, isSunset);
      
      // Mélange jour/nuit
      vec3 zenith = mix(nightZenith, dayZenith, dayFactor);
      vec3 horizon = mix(nightHorizon, dayHorizon, dayFactor);
      
      // Mélange avec transition
      zenith = mix(zenith, transZenith, transitionFactor);
      horizon = mix(horizon, transHorizon, transitionFactor);
      
      return mix(horizon, zenith, t);
   }
   
#elif SKY_COLOR == 1 // Fantaisiste (dégradé)
   vec3 getSky() {
      vec3 normal = getNormal();
      float horizon = pow(1.0 - abs(normal.y), 2.0);
      float t = clamp(normal.x * 0.5 + 0.5, 0.0, 1.0);
      
      // Facteurs temporels
      float dayFactor = getDayFactor();
      float transitionFactor = getTransitionFactor();
      float isSunset = getSunsetFactor() > 0.0 ? 1.0 : 0.0;
      
      // Couleurs de jour
      vec3 dayMorningZenith = vec3(0.7, 0.4, 0.3);
      vec3 dayMorningHorizon = vec3(0.9, 0.6, 0.3);
      vec3 dayEveningZenith = vec3(0.4, 0.4, 0.7);
      vec3 dayEveningHorizon = vec3(0.5, 0.35, 0.55);
      
      // Couleurs de nuit
      vec3 nightMorningZenith = vec3(0.1, 0.15, 0.3);
      vec3 nightMorningHorizon = vec3(0.2, 0.25, 0.4);
      vec3 nightEveningZenith = vec3(0.15, 0.1, 0.3);
      vec3 nightEveningHorizon = vec3(0.3, 0.2, 0.4);
      
      // Couleurs lever/coucher
      vec3 sunriseMorningZenith = vec3(0.8, 0.5, 0.3);
      vec3 sunriseMorningHorizon = vec3(1.0, 0.7, 0.3);
      vec3 sunriseEveningZenith = vec3(0.5, 0.4, 0.7);
      vec3 sunriseEveningHorizon = vec3(0.7, 0.5, 0.8);
      
      vec3 sunsetMorningZenith = vec3(0.7, 0.4, 0.2);
      vec3 sunsetMorningHorizon = vec3(0.95, 0.6, 0.2);
      vec3 sunsetEveningZenith = vec3(0.4, 0.3, 0.6);
      vec3 sunsetEveningHorizon = vec3(0.6, 0.4, 0.7);
      
      // Mélange jour/nuit
      vec3 morningZenith = mix(nightMorningZenith, dayMorningZenith, dayFactor);
      vec3 morningHorizon = mix(nightMorningHorizon, dayMorningHorizon, dayFactor);
      vec3 eveningZenith = mix(nightEveningZenith, dayEveningZenith, dayFactor);
      vec3 eveningHorizon = mix(nightEveningHorizon, dayEveningHorizon, dayFactor);
      
      // Couleurs de transition (lever/coucher)
      vec3 transitionMorningZenith = mix(sunriseMorningZenith, sunsetMorningZenith, isSunset);
      vec3 transitionMorningHorizon = mix(sunriseMorningHorizon, sunsetMorningHorizon, isSunset);
      vec3 transitionEveningZenith = mix(sunriseEveningZenith, sunsetEveningZenith, isSunset);
      vec3 transitionEveningHorizon = mix(sunriseEveningHorizon, sunsetEveningHorizon, isSunset);
      
      // Mélange avec transition
      morningZenith = mix(morningZenith, transitionMorningZenith, transitionFactor);
      morningHorizon = mix(morningHorizon, transitionMorningHorizon, transitionFactor);
      eveningZenith = mix(eveningZenith, transitionEveningZenith, transitionFactor);
      eveningHorizon = mix(eveningHorizon, transitionEveningHorizon, transitionFactor);
      
      // Mélange final
      vec3 morningColor = mix(morningZenith, morningHorizon, horizon);
      vec3 eveningColor = mix(eveningZenith, eveningHorizon, horizon);
      
      return mix(morningColor, eveningColor, t);
   }
   
#else // Réaliste
   vec3 getSky() {
      vec3 normal = getNormal();
      float horizonFactor = 1.0 - max(normal.y, 0.0);
      float horizonPower = pow(horizonFactor, 2.0);
      
      // Facteurs temporels
      float dayFactor = getDayFactor();
      float transitionFactor = getTransitionFactor();
      float isSunset = getSunsetFactor() > 0.0 ? 1.0 : 0.0;
      
      // Couleurs de jour
      vec3 dayZenith = vec3(0.5, 0.7, 0.95);
      vec3 dayHorizon = vec3(0.8, 0.85, 0.95);
      
      // Couleurs de nuit
      vec3 nightZenith = vec3(0.05, 0.1, 0.2);
      vec3 nightHorizon = vec3(0.1, 0.15, 0.3);
      
      // Couleurs lever de soleil
      vec3 sunriseZenith = vec3(0.3, 0.4, 0.6);
      vec3 sunriseHorizon = vec3(0.9, 0.6, 0.4);
      
      // Couleurs coucher de soleil
      vec3 sunsetZenith = vec3(0.3, 0.3, 0.5);
      vec3 sunsetHorizon = vec3(0.9, 0.5, 0.3);
      
      // Sélection des couleurs de transition
      vec3 transZenith = mix(sunriseZenith, sunsetZenith, isSunset);
      vec3 transHorizon = mix(sunriseHorizon, sunsetHorizon, isSunset);
      
      // Mélange jour/nuit
      vec3 zenithColor = mix(nightZenith, dayZenith, dayFactor);
      vec3 horizonColor = mix(nightHorizon, dayHorizon, dayFactor);
      
      // Mélange avec transition
      zenithColor = mix(zenithColor, transZenith, transitionFactor);
      horizonColor = mix(horizonColor, transHorizon, transitionFactor);
      
      return mix(zenithColor, horizonColor, horizonPower);
   }
   
#endif

vec3 getFinalSky() {
   vec3 color = getSky();
   
   // Ajuster en fonction de la luminosité du ciel et du temps
   float dayFactor = getDayFactor();
   
   // Facteur luminosité variable entre jour/nuit
   float skyLuminosity = mix(0.25, 0.75, dayFactor);
   float baseLuminosity = 0.25 + min((skyColor.r + skyColor.g + skyColor.b) / 2.0, 0.75);
   
   color *= mix(skyLuminosity, baseLuminosity, 0.7);
   
   // Assombrir par temps de pluie
   color *= 1.0 - rainStrength * 0.3;
   
   // Appliquer la diffusion atmosphérique si activée
   #if ATMOSPHERIC_SCATTERING == 1
   vec3 normal = getNormal();
   vec3 lightDir = normalize(mix(moonPosition, sunPosition, dayFactor));
   vec3 scattering = calculateAtmosphericScattering(normal, lightDir);
   
   // Réduire l'effet par temps de pluie
   scattering *= (1.0 - rainStrength * 0.7);
   
   // Appliquer la diffusion
   color += scattering;
   #endif
   
   return color;
}