//#INCLUDE common.glsl
// SKELETON: the architecture IS the skeleton. Columns -> vertebral stacks, window/portal arches -> ribs, spire ridges -> tendons.
// Proportions are untouched; stone simply gives way to bone along the structural members.  rgb = bone colour, a = coverage.
out vec4 fragColor;

void main(){
    vec2 uv = vUV.st;
    float amt = uC.x;
    if (amt < 0.002) { fragColor = vec4(0.0); return; }
    vec2 w = wuv(uv);
    float gap = G_GAP;
    vec2 s = toS(w);
    vec4 a = TA(w), b = TB(w), c = TC(w);

    // reveal sweeps up the structure
    float reveal = clamp(amt * 1.5 - s.y * 0.5, 0.0, 1.0);

    // columns -> vertebrae: stacked discs with notches and lateral shading
    float col = c.y;
    float segf = fract(s.y * 30.0);
    float disc = smoothstep(0.0, 0.18, segf) * smoothstep(1.0, 0.82, segf);
    float lat = clamp(c.y - 0.5 * (TC(w + vec2(3.0 * PX / AR, 0.0)).y + TC(w - vec2(3.0 * PX / AR, 0.0)).y) + 0.5, 0.0, 1.0);
    vec3 ivory = vec3(0.93, 0.88, 0.76);
    vec3 vert = ivory * (0.35 + 0.65 * disc) * (0.7 + 0.5 * lat);
    vert += vec3(1.0, 0.95, 0.85) * smoothstep(0.85, 1.0, disc) * 0.25;
    float vertA = col;

    // arches -> ribs: relief edges that sit next to windows / portals, with fine transverse ridges
    float near = 0.0;
    for (int i = 0; i < 4; i++) {
        float ang = float(i) * 1.5708;
        near = max(near, max(TA(w + vec2(cos(ang) / AR, sin(ang)) * 9.0 * PX).y, TC(w + vec2(cos(ang) / AR, sin(ang)) * 9.0 * PX).x));
    }
    float ridge = 0.5 + 0.5 * sin((s.x + s.y) * 900.0 + fbm(s * 40.0) * 6.0);
    vec3 rib = ivory * (0.45 + 0.5 * ridge);
    float ribA = clamp(a.z * 1.6, 0.0, 1.0) * near * (1.0 - a.y);

    // spire ridges + ornaments -> tendons: fibrous striations
    float fib = 0.5 + 0.5 * sin(s.x * 1400.0 + sin(s.y * 35.0) * 3.0);
    vec3 tendon = mix(vec3(0.85, 0.55, 0.50), vec3(1.0, 0.92, 0.85), fib);
    float tendA = max(c.w * 0.9, col * step(0.58, s.y));

    vec3 colr = vert;
    float cov = vertA;
    colr = mix(colr, rib, ribA);
    cov = max(cov, ribA);
    colr = mix(colr, tendon, tendA);
    cov = max(cov, tendA * 0.9);
    cov *= reveal * a.w * (1.0 - gap);
    // faint marrow glow under the bone as biology rises
    colr += vec3(0.5, 0.08, 0.05) * uB.w * 0.25 * (0.5 + 0.5 * sin(uA.x * 1.1 + s.y * 20.0));
    fragColor = vec4(colr * 0.8 * cov, cov);
}
