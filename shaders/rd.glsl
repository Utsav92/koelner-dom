//#INCLUDE common.glsl
// GRAY-SCOTT REACTION-DIFFUSION with per-region feed/kill: towers grow coral, nave cells divide, windows form worms,
// columns labyrinths, portals spots, ornaments coral. inputs: 0 ustate, 1 twinA, 2 twinB, 3 twinC, 4 own previous state (rg = U,V), 5 crack.
out vec4 fragColor;

vec2 Sx(ivec2 p, ivec2 r){ return texelFetch(sTD2DInputs[4], clamp(p, ivec2(0), r - 1), 0).rg; }

void main(){
    ivec2 r = textureSize(sTD2DInputs[4], 0);
    ivec2 p = ivec2(gl_FragCoord.xy);
    vec2 uv = (vec2(p) + 0.5) / vec2(r);
    float amt = uD.x;
    vec4 a = TA(uv), b = TB(uv), c = TC(uv);
    float solid = a.w;
    vec2 cv = Sx(p, r);
    if (amt < 0.002) { fragColor = vec4(1.0, 0.0, 0.0, 1.0); return; }

    vec2 lap = -cv;
    lap += 0.2 * (Sx(p + ivec2(1, 0), r) + Sx(p + ivec2(-1, 0), r) + Sx(p + ivec2(0, 1), r) + Sx(p + ivec2(0, -1), r));
    lap += 0.05 * (Sx(p + ivec2(1, 1), r) + Sx(p + ivec2(-1, 1), r) + Sx(p + ivec2(1, -1), r) + Sx(p + ivec2(-1, -1), r));

    // region-dependent parameters (feed, kill)
    vec2 fk = vec2(0.0), wsum = vec2(0.0);
    float wt;
    wt = b.x + b.y;      fk += wt * vec2(0.0545, 0.062);  wsum.x += wt;      // towers: coral
    wt = b.z;            fk += wt * vec2(0.0367, 0.0649); wsum.x += wt;      // nave: mitosis
    wt = a.y * 2.0;      fk += wt * vec2(0.078, 0.061);   wsum.x += wt;      // windows: worms
    wt = c.y * 2.0;      fk += wt * vec2(0.029, 0.057);   wsum.x += wt;      // columns: labyrinth
    wt = c.x * 2.0;      fk += wt * vec2(0.035, 0.065);   wsum.x += wt;      // portals: spots
    wt = c.w * 2.0;      fk += wt * vec2(0.0545, 0.062);  wsum.x += wt;      // ornaments: coral
    fk = wsum.x > 0.001 ? fk / wsum.x : vec2(0.0367, 0.0649);

    float Uc = cv.x, V = cv.y;
    float uvv = Uc * V * V;
    float rate = 1.0;
    Uc += (1.0 * lap.x - uvv + fk.x * (1.0 - Uc)) * rate;
    V += (0.5 * lap.y + uvv - (fk.x + fk.y) * V) * rate;

    // seeds: inside cracks first, then sparse spores across the stone
    float cr = texture(sTD2DInputs[5], uv).a;
    V += cr * amt * 0.12;
    float sp = hash21(floor(uv * vec2(180.0, 320.0)) + floor(uA.x * 2.0));
    if (sp > 0.9993 && amt > 0.2) V += 0.6 * solid;

    if (solid < 0.5) { Uc = 1.0; V = 0.0; }
    fragColor = vec4(clamp(Uc, 0.0, 1.0), clamp(V, 0.0, 1.0), 0.0, 1.0);
}
