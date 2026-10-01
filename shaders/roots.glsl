//#INCLUDE common.glsl
// ROOT INVASION: roots grow from under the cathedral up the vertical architectural pathways, wrapping columns, statues and windows,
// branching as they climb. They are not attacking the building - ornament morphs INTO roots. Stone -> wood -> veins -> neurons
// (uO.x = rootBio).  rgb = colour, a = coverage.
out vec4 fragColor;

const int NS = 14;
const float XS[14] = float[14](0.038, 0.070, 0.105, 0.140, 0.172, 0.1805, 0.2477, 0.3149, 0.382, AR - 0.172, AR - 0.140, AR - 0.105, AR - 0.070, AR - 0.038);

float rootField(vec2 s, float g, out float tip, out float age){
    float best = 1.0;
    tip = 0.0;
    age = 0.0;
    for (int i = 0; i < NS; i++) {
        float fi = float(i);
        float h = hash11(fi * 3.7);
        float top = g * (0.55 + 0.45 * h) * 1.02;                       // growth head height of this strand
        if (s.y > top + 0.01) continue;
        float wob = 0.011 * sin(s.y * 17.0 + fi * 2.1 + uA.x * 0.15) + 0.006 * sin(s.y * 61.0 + fi * 5.3);
        float x = XS[i] + wob * smoothstep(0.0, 0.25, s.y);
        float thick = (0.0042 - 0.0026 * clamp(s.y / 1.0, 0.0, 1.0)) * (0.7 + 0.5 * h);
        float slope = 0.011 * 17.0 * 0.5;
        float dl = abs(s.x - x) / sqrt(1.0 + slope * slope);
        float dd = dl - thick;
        float tipf = 1.0 - smoothstep(0.0, 0.03, top - s.y);
        if (dd < best) { best = dd; tip = tipf; age = s.y / max(top, 0.01); }
        // branches: lateral limbs that reach out and wrap
        for (int k = 0; k < 4; k++) {
            float yb = 0.10 + 0.17 * float(k) + 0.06 * hash11(fi + float(k) * 9.1);
            if (s.y < yb || s.y > yb + 0.14 || yb > top) continue;
            float sg = hash11(fi * 1.3 + float(k) * 4.4) > 0.5 ? 1.0 : -1.0;
            float u = s.y - yb;
            float xb = XS[i] + wob * smoothstep(0.0, 0.25, yb) + sg * (u * 0.40 + 0.012 * sin(u * 70.0 + fi));
            float db = abs(s.x - xb) / 1.08 - thick * 0.55 * (1.0 - u / 0.14);
            if (db < best) { best = db; tip = 0.0; age = 0.5; }
        }
    }
    return best;
}

void main(){
    vec2 uv = vUV.st;
    float g = uC.w;
    if (g < 0.002) { fragColor = vec4(0.0); return; }
    vec2 w = wuv(uv);
    float gap = G_GAP;
    vec2 s = toS(w);
    vec4 a = TA(w), b = TB(w), c = TC(w);
    float tip, age;
    float d = rootField(s, g, tip, age);
    float body = 1.0 - smoothstep(0.0, 0.0022, d);
    // ornaments morph into roots: they thicken, gnarl and branch with noise
    float orn = c.w * smoothstep(0.1, 0.5, g) * (0.45 + 0.55 * vnoise(s * 180.0 + uA.x * 0.2));
    float cov = max(body, orn * 0.8);
    // statues and window frames get wrapped
    float wrap = (c.z + a.z * max(a.y, 0.0)) * smoothstep(0.3, 0.9, g) * (0.5 + 0.5 * sin(s.y * 90.0 + s.x * 40.0));
    cov = max(cov, wrap * 0.45);
    cov *= a.w * (1.0 - gap) * (1.0 - a.y * 0.7);

    float bio = uO.x;
    float grain = 0.5 + 0.5 * sin(s.y * 520.0 + fbm(s * 60.0) * 8.0);
    vec3 wood = mix(vec3(0.20, 0.11, 0.05), vec3(0.50, 0.32, 0.16), grain);
    float pulse = pow(max(0.0, sin(s.y * 22.0 - uA.x * 3.0 * (1.0 + uI.z) + age * 6.0)), 6.0);
    vec3 vein = mix(vec3(0.55, 0.05, 0.07), vec3(1.0, 0.35, 0.25), pulse) * (0.7 + uA.w);
    vec3 neuron = mix(vec3(0.2, 0.55, 1.0), vec3(0.9, 1.0, 1.0), pulse) * (0.8 + 1.4 * pulse);
    vec3 col = mix(wood, vein, smoothstep(0.15, 0.5, bio));
    col = mix(col, neuron, smoothstep(0.55, 0.95, bio));
    col += vec3(0.7, 1.0, 0.6) * tip * body * 0.9;                     // living growth tips
    float rimlight = (1.0 - smoothstep(0.0, 0.004, abs(d))) * 0.25;
    col += col * rimlight;
    fragColor = vec4(col * cov, cov);
}
