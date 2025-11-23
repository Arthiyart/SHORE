// Normalise un vecteur 4D homogène vers 3D 
vec3 nvec3(vec4 pos) {
   return pos.xyz / pos.w;
}

// Convertit des coordonnées écran en coordonnées UV (0-1)
vec2 screen2uv(vec3 screen) {
   return (0.5*nvec3(gbufferProjection * vec4(screen, 1.0)) + 0.5).st;
}

// Convertit des coordonnées UV et profondeur en coordonnées écran
vec3 uv2screen(vec2 uv, float depth) {
   return nvec3(gbufferProjectionInverse * vec4(2.0*vec3(uv, depth) - 1.0, 1.0));
}

// Transforme un vecteur de l'espace monde vers l'espace écran
vec3 world2screen(vec3 world) {
   return mat3(gbufferModelView) * world;
}

// Calcule le carré de la longueur d'un vecteur (optimisation)
float squaredLength(vec3 v) {
   return dot(v, v);
}