#ifndef DYNAMIC_LIGHTING_GLSL
#define DYNAMIC_LIGHTING_GLSL

// Paramètres d'éclairage dynamique
#define TORCH_R 1.0         // Couleur rouge des torches [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define TORCH_G 0.8         // Couleur verte des torches [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define TORCH_B 0.6         // Couleur bleue des torches [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define TORCH_OUTER_R 1.0   // Couleur rouge externe [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define TORCH_OUTER_G 0.55  // Couleur verte externe [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define TORCH_OUTER_B 0.2   // Couleur bleue externe [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]

// Définir les constantes pour la lightmap
const vec2 TORCH_UV_SCALE = vec2(8.0/255.0, 231.0/255.0);
const vec3 TORCH_COLOR = vec3(TORCH_R, TORCH_G, TORCH_B);
const vec3 TORCH_OUTER_COLOR = vec3(TORCH_OUTER_R, TORCH_OUTER_G, TORCH_OUTER_B);

// Fonction utilitaire pour la luminosité
float luma(vec3 color) {
    return dot(vec3(0.299, 0.587, 0.114), color);
}

// Normaliser une valeur entre deux bornes
float rescale(float x, float a, float b) {
    return clamp((x - a) / (b - a), 0.0, 1.0);
}

// Fonction de lissage (smoothstep personnalisé)
float smoothe(float x) {
    return x*x*(3.0 - 2.0*x);
}

// Calcule l'intensité de la lumière de torche à partir des coordonnées de lightmap
float getTorchStrength(float torchLight) {
    return 1.1*rescale(torchLight, TORCH_UV_SCALE.x, TORCH_UV_SCALE.y);
}

// Calcule la couleur de la lumière de torche
vec3 getTorchColor(vec3 ambient, float torchStrength, vec3 worldPos) {
    float strength = torchStrength;
    
    #ifdef HAND_DYNAMIC_LIGHTING
        // Si l'éclairage dynamique de la main est activé
        float heldLightStrength = float(heldBlockLightValue);
        
        // Calculer la distance avec une atténuation modulable par DYNAMIC_LIGHT_DISTANCE
        // Une valeur plus élevée = lumière visible de plus loin
        float distanceFactor = 1.0 / (length(worldPos) * length(worldPos) / (DYNAMIC_LIGHT_DISTANCE * 1.5) + 1.5);
        
        strength = max(torchStrength, min(1.0, heldLightStrength * distanceFactor));
    #endif
    
    // Adoucir la transition
    strength = smoothe(strength);
    
    // Calculer la couleur finale
    return mix(TORCH_OUTER_COLOR, TORCH_COLOR, strength) * strength * max(0.0, 1.0 - luma(ambient));
}

// Calcule la couleur d'éclairage combinée (ambiante + torche)
vec3 calculateDynamicLighting(vec3 ambient, float torchLight, vec3 worldPos) {
    float strength = getTorchStrength(torchLight);
    return ambient + getTorchColor(ambient, strength, worldPos);
}

#endif // DYNAMIC_LIGHTING_GLSL