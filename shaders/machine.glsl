//#INCLUDE common.glsl
// THE INTERNAL MACHINE, seen through the lens-shaped opening of the central facade (G_GAP).
// Parallax layers of gears, rotating rings, pistons and chains. BIOLOGY (uB.w) softens it: teeth vanish, brass turns to wet tissue,
// pistons become arteries that pulse with the heartbeat.  rgb = colour, a = interior visibility.
out vec4 fragColor;

float gearSD(vec2 p, float r, float teeth, float depth, float ang){
    float a = atan(p.y, p.x) + ang;
    float tooth = smoothstep(-0.3, 0.3, sin(a * teeth)) * depth;
    return length(p) - (r + tooth);
}

vec4 layer(vec2 q, float k, float seedv, float bio, float gearA, out float lit){
    float grid = 1.6 + k * 0.7;
    vec2 cell = floor(q * grid);
    vec2 f = fract(q * grid) - 0.5;
    float h = hash21(cell + seedv);
    float h2 = hash21(cell + seedv + 3.3);
    float h3 = hash21(cell + seedv + 7.7);
    float dir = h2 > 0.5 ? 1.0 : -1.0;
    float teeth = floor(8.0 + 14.0 * h);
    float r = 0.16 + 0.16 * h3;
    float tdepth = 0.05 * (1.0 - bio * 0.95);
    float d = gearSD(f, r, teeth, tdepth, gearA * dir * (9.0 / teeth) + h * 6.0);
    float hole = length(f) - r * 0.38;
    float spokes = step(0.35, abs(sin(atan(f.y, f.x) * 3.0 + gearA * dir * 0.7))) * step(r * 0.38, length(f)) * step(length(f), r * 0.85);
    float body = (1.0 - smoothstep(0.0, 0.015, d)) * smoothstep(0.0, 0.015, hole);
    float rim = (1.0 - smoothstep(0.0, 0.03, abs(d))) * 0.6;
    float isGear = step(0.25, h2);
    // pistons (become arteries with biology)
    float colx = abs(f.x) - 0.05 * (1.0 + bio * 0.8);
    float py = 0.5 + 0.38 * sin(gearA * 3.0 + h * 9.0);
    float piston = (1.0 - smoothstep(0.0, 0.012, colx)) * step(f.y + 0.5, py) * (1.0 - isGear);
    // chains: dashed sinusoid
    float cy = f.y - 0.12 * sin(f.x * 6.0 + gearA);
    float chain = (1.0 - smoothstep(0.012, 0.02, abs(cy))) * step(0.5, fract(f.x * 14.0 + gearA * dir)) * step(0.7, h3) * (1.0 - bio * 0.7);
    float m = max(max(body * isGear, piston), chain);
    float shade = 0.55 + 0.45 * smoothstep(-0.05, 0.1, -d) + rim;
    vec3 brass = vec3(0.62, 0.40, 0.17) * shade;
    vec3 steel = vec3(0.35, 0.40, 0.48) * shade;
    vec3 metal = mix(brass, steel, step(0.5, h));
    metal *= 0.75 + 0.25 * spokes;
    vec3 flesh = vec3(0.55, 0.06, 0.07) * (0.7 + 0.6 * shade) + vec3(0.5, 0.15, 0.12) * pow(max(0.0, sin(uA.x * 2.0 + h * 6.0 - f.y * 6.0)), 6.0) * uA.w;
    vec3 c = mix(metal, flesh, bio);
    lit = shade;
    return vec4(c, m);
}

void main(){
    vec2 uv = vUV.st;
    vec2 w = wuv(uv);
    float gap = G_GAP;
    if (gap < 0.002) { fragColor = vec4(0.0); return; }
    vec2 s = toS(w);
    float bio = uB.w, gearA = uQ.y;
    vec2 q0 = (s - vec2(CXM, 0.26)) * 5.5;
    vec2 cam = vec2(sin(uA.x * 0.07), cos(uA.x * 0.09)) * 0.35 + (uv - 0.5) * 0.0;

    // hot core behind everything: the thing beneath the stone
    float core = exp(-length(s - vec2(CXM, 0.24)) * 5.0);
    vec3 col = mix(vec3(0.02, 0.01, 0.01), vec3(0.9, 0.22, 0.05), core * 0.5) * (0.5 + uB.y * 0.8);
    // rotating rings behind the gears
    float rr = length(s - vec2(CXM, 0.26));
    float ring = 0.0;
    for (int i = 0; i < 4; i++) {
        float r0 = 0.05 + float(i) * 0.045;
        float a = atan(s.y - 0.26, s.x - CXM) + gearA * (i % 2 == 0 ? 0.6 : -0.45);
        ring = max(ring, (1.0 - smoothstep(0.0, 0.004, abs(rr - r0))) * step(0.3, abs(sin(a * (6.0 + float(i) * 3.0)))));
    }
    col += mix(vec3(0.6, 0.35, 0.12), vec3(0.8, 0.12, 0.1), bio) * ring * 0.5;
    // parallax layers, back to front
    for (int k = 3; k >= 0; k--) {
        float kk = float(k);
        vec2 q = q0 * (1.0 - kk * 0.12) + cam * (kk * 0.4 + 0.2) + vec2(0.0, kk * 0.37);
        float lit;
        vec4 L = layer(q, kk, 11.0 + kk * 5.0, bio, gearA * (1.0 + kk * 0.2), lit);
        float dark = 0.45 + 0.55 * (1.0 - kk / 4.0);                    // depth cue
        float glowEdge = (1.0 - smoothstep(0.0, 0.3, L.a)) * 0.0;
        col = mix(col, L.rgb * dark * (0.6 + core * 1.2), L.a);
    }
    // vignette inside the slit so the opening reads as depth
    float edge = smoothstep(0.0, 1.0, gap);
    col *= 0.35 + 0.65 * (1.0 - pow(abs(s.x - CXM) / max(gapHalf(s.y), 0.01), 3.0));
    fragColor = vec4(col * edge, gap);
}
