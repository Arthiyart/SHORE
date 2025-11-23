//all uniforms

uniform float viewHeight;
uniform float viewWidth;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform vec3 skyColor;
uniform vec3 fogColor;
uniform float rainStrength;
uniform vec3 sunPosition;
uniform sampler2D texture;
uniform float frameTimeCounter;
uniform int worldTime;        // Temps du monde (0-24000)
uniform vec3 moonPosition;    // Position de la lune
uniform float nightVision;    // Effet de night vision
uniform int moonPhase;        // Phase de la lune
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;
uniform vec3 cameraPosition;    // Position de la caméra
uniform mat4 gbufferModelView;
uniform sampler2D colortex6; // Normales
uniform sampler2D colortex7; // Info
uniform sampler2D lightmap; // Carte d'éclairage (lumière du soleil + torches)
uniform mat4 gbufferProjection;
uniform sampler2D noisetex; // Texture de bruit
uniform int isEyeInWater;

// Pour l'éclairage dynamique
#ifdef HAND_DYNAMIC_LIGHTING
    uniform int heldBlockLightValue; // Valeur d'éclairage du bloc tenu
    uniform int heldBlockLightValue2; // Valeur d'éclairage du bloc tenu dans la main secondaire
#endif

uniform float frameCounter;