//#INCLUDE common.glsl
// THE HEART OF THE CATHEDRAL: a biomechanical Gothic heart behind the central portal, built from nested pointed arches (ribs), stone,
// veins, metal bands and glowing particles. Each beat swells it and launches the pressure wave (see vessels.glsl).
// Visible through the opened nave. rgb = colour, a = coverage.
out vec4 fragColor;

float dot2(vec2 v){ return dot(v, v); }
float sdHeart(vec2 p){
    p.x = abs(p.x);
    if (p.y + p.x > 1.0) return sqrt(dot2(p - vec2(0.25, 0.75))) - sqrt(2.0) / 4.0;
    return sqrt(min(dot2(p - vec2(0.0, 1.0)), dot2(p - 0.5 * max(p.x + p.y, 0.0)))) * sign(p.x - p.y);
}

void main(){
    vec2 uv = vUV.st;
    float amt = uC.z;
    vec2 w = wuv(uv);
    float gap = G_GAP;
    if (amt < 0.002 || gap < 0.002) { fragColor = vec4(0.0); return; }
    vec2 s = toS(w);
    float beat = uA.w;
    float R0 = 0.100 * (1.0 + 0.10 * beat) * (0.55 + 0.45 * smoothstep(0.0, 0.6, amt));
    vec2 c0 = vec2(CXM, 0.155);
    vec2 q = (s - c0) / R0 + vec2(0.0, 0.52);
    float d = sdHeart(q * 0.82) * R0;                                // distance in height units, < 0 inside
    float inside = 1.0 - smoothstep(-0.001, 0.002, d);

    // gothic ribs: nested pointed arches rise through the muscle
    float ribs = 0.0;
    for (int i = 0; i < 4; i++) {
        float wd = 0.012 + float(i) * 0.012;
        float v = archSD(s, CXM, c0.y - 0.06, wd, 0.03 + float(i) * 0.012);
        ribs = max(ribs, 1.0 - smoothstep(0.0, 0.0022, abs(v)));
    }
    // veins: ridged noise network that thickens with the beat
    vec2 vp = (s - c0) * 38.0;
    float vein = 1.0 - smoothstep(0.04, 0.16 + 0.1 * beat, abs(fbm(vp + vec2(0.0, uA.x * 0.15)) - 0.5));
    // muscle texture
    float mus = fbm((s - c0) * vec2(60.0, 26.0));
    vec3 flesh = mix(vec3(0.35, 0.02, 0.03), vec3(0.85, 0.12, 0.08), mus);
    vec3 col = flesh * (0.6 + 0.8 * beat);
    col += vec3(1.0, 0.35, 0.18) * vein * 0.55 * (0.5 + beat);
    col = mix(col, vec3(1.0, 0.72, 0.30), ribs * 0.85);                // gilded stone-metal ribs
    // metal rim + glow
    float rim = exp(-abs(d) * 90.0);
    col += vec3(1.0, 0.65, 0.25) * rim * 0.9;
    float aura = exp(-max(d, 0.0) * 28.0) * (0.35 + 0.8 * beat);
    // aorta tubes up into the arteries
    float aorta = max(1.0 - smoothstep(0.0, 0.004, abs(abs(s.x - CXM) - 0.018)), 0.0) * step(c0.y + 0.07, s.y) * step(s.y, 0.50);
    col += vec3(0.9, 0.2, 0.1) * aorta * (0.5 + 1.2 * pow(max(0.0, sin(s.y * 40.0 - uA.x * 6.0)), 6.0));
    // gaussian sparkles orbiting
    vec2 cell = floor((s - c0) * 120.0 + vec2(0.0, uA.x * 6.0));
    float spark = step(0.985, hash21(cell)) * exp(-length(s - c0) * 9.0);
    col += vec3(1.0, 0.8, 0.5) * spark * 1.5;
    float cov = clamp(inside + aorta * 0.8 + aura * 0.0, 0.0, 1.0);
    vec3 rgb = col * inside + vec3(1.0, 0.3, 0.1) * aura * 0.5 + col * aorta * (1.0 - inside);
    fragColor = vec4(rgb * amt * gap, clamp(cov + aura * 0.4, 0.0, 1.0) * amt * gap);
}
