//#INCLUDE common.glsl
// STONE SHADER: masonry, relief lighting, ambient occlusion, edges. This is the "enhanced physical facade" layer.
// Breathing + opening warp come from wuv(); the first minute shows only this layer.
out vec4 fragColor;

vec3 masonry(vec2 s, float seedv){
    float row = floor(s.y / 0.0125);
    float off = hash11(row * 7.13) * 0.04;
    float bx = floor((s.x + off) / 0.034);
    vec2 cell = vec2(bx, row);
    vec2 f = vec2(fract((s.x + off) / 0.034), fract(s.y / 0.0125));
    float mortar = smoothstep(0.0, 0.07, f.x) * smoothstep(0.0, 0.07, 1.0 - f.x) * smoothstep(0.0, 0.1, f.y) * smoothstep(0.0, 0.1, 1.0 - f.y);
    float tone = 0.55 + 0.45 * hash21(cell + seedv);
    float grain = fbm(s * 90.0) * 0.5 + fbm(s * 400.0) * 0.25;
    float grime = fbm(s * vec2(9.0, 3.0) + 3.7);
    float v = (0.30 + 0.35 * tone) * (0.55 + 0.7 * grain) * mix(0.55, 1.0, mortar) * (0.7 + 0.5 * grime);
    return vec3(0.80, 0.74, 0.65) * v;
}

void main(){
    vec2 uv = vUV.st;
    float anomO = uN.y, anomS = uN.z, anomC = uN.w;
    vec2 w = wuv(uv);
    float gap = G_GAP;
    vec2 s = toS(w);

    vec4 a = TA(w), b = TB(w), c = TC(w);
    // anomaly: a stone ornament shifts by a couple of pixels
    if (anomO > 0.001) {
        vec2 oc = vec2(0.18 / AR, 0.60);
        float m = smoothstep(0.07, 0.02, length(toS(w) - toS(oc)));
        float dy = anomO * 3.0 * PX;
        c.w = mix(c.w, TC(w + vec2(0.0, dy * 3.0)).w, m);
        a.x += (TC(w + vec2(0.0, dy * 3.0)).w - TC(w).w) * 0.1 * m;
    }
    // anomaly: one column subtly expands
    if (anomC > 0.001) {
        float m = smoothstep(0.08, 0.02, abs(toS(w).x - (XTL - 0.067)) ) * step(toS(w).y, 0.58);
        float e = TC(w + vec2(anomC * 4.0 * PX, 0.0)).y;
        e = max(e, TC(w - vec2(anomC * 4.0 * PX, 0.0)).y);
        c.y = mix(c.y, max(c.y, e), m);
        a.x += 0.05 * anomC * m * e;
    }

    // normal from the height field (+ stone grain)
    vec2 e1 = vec2(2.0 * PX / AR * AR, 0.0);
    float hx = TA(w + vec2(2.0 * PX / AR, 0.0)).x - TA(w - vec2(2.0 * PX / AR, 0.0)).x;
    float hy = TA(w + vec2(0.0, 2.0 * PX)).x - TA(w - vec2(0.0, 2.0 * PX)).x;
    float bump = fbm(s * 140.0) - 0.5;
    vec3 n = normalize(vec3(-hx * 9.0 + bump * 0.12, -hy * 9.0 + bump * 0.12, 1.0));

    // light: a slow key light, with the anomaly where the right tower's shadow runs the wrong way
    float ang = 2.2 + 0.25 * sin(uA.x * 0.05);
    float flip = anomS * b.y;
    vec3 L = normalize(vec3(cos(ang + flip * PI), sin(ang + flip * PI) * 0.8 + 0.2, 0.75));
    float dif = clamp(dot(n, L), 0.0, 1.0);
    // soft AO: compare with a wide neighbourhood
    float blur = 0.0;
    for (int i = 0; i < 8; i++) {
        float aa_ = float(i) * 0.785398;
        blur += TA(w + vec2(cos(aa_) / AR, sin(aa_)) * 9.0 * PX).x;
    }
    blur /= 8.0;
    float ao = clamp(1.0 - (blur - a.x) * 2.6, 0.25, 1.0);
    // cast-ish shadow: march a few steps along L in the height field
    float sh = 1.0;
    for (int i = 1; i <= 5; i++) {
        vec2 q = w + vec2(L.x / AR, L.y) * float(i) * 4.0 * PX;
        sh = min(sh, clamp(1.0 - (TA(q).x - a.x - float(i) * 0.012) * 8.0, 0.2, 1.0));
    }

    vec3 alb = masonry(s, 1.7);
    alb *= mix(1.0, 1.5, c.w * 0.4);                                   // ornaments catch more light
    float edge = a.z;
    vec3 col = alb * (0.16 + 0.95 * dif * sh) * ao;
    col += vec3(0.95, 0.88, 0.78) * edge * 0.30 * (0.4 + 0.6 * dif);   // edge highlights
    col *= mix(1.0, 0.32, a.y * 0.9);                                  // glass reads dark
    col *= 1.0 - 0.55 * smoothstep(0.0, 0.2, (1.0 - uv.y)) * 0.0;

    // one faint pulse travelling through the stone (final sequence)
    float pr = uQ.w;
    if (pr > 0.0) {
        float d = length(toS(w) - HEARTC);
        col += vec3(0.9, 0.55, 0.35) * 0.35 * exp(-pow((d - pr * 1.2) * 14.0, 2.0)) * (1.0 - pr) * a.w;
    }

    col *= uB.x;                                                       // stone gain from the timeline
    col *= (1.0 - gap);
    fragColor = vec4(col * a.w, a.w * (1.0 - gap));
}
