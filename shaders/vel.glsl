//#INCLUDE common.glsl
//#INCLUDE pshapes.glsl
// PARTICLE VELOCITY. inputs: 0 ustate, 1 homeA, 2 homeB, 3 pos (previous), 4 vel (previous).  out = (velocity, leaveFlag).
// A particle is LOCKED to its P_original until it is released: by SPLAT_DISSOLVE (class by class: edges leak first, then statues,
// ornaments, columns, windows), by the tower fronts (top down), or by STRUCTURAL_STABILITY -> 0 (everything).
// Free particles feel  F_return = (P_original - P_current) * RETURN_STRENGTH,  gravity (negative = float up), curl turbulence.
// While DNA / human shapes are active, a strong spring pulls each particle to its target in the shape.
out vec4 fragColor;

const float SEPTHR[7] = float[7](0.10, 0.80, 0.45, 0.60, 0.22, 0.30, 0.75);

void main(){
    ivec2 px = ivec2(gl_FragCoord.xy);
    ivec2 res = textureSize(sTD2DInputs[1], 0);
    uint id = uint(px.y * res.x + px.x);
    vec4 hA = texelFetch(sTD2DInputs[1], px, 0);
    vec4 hB = texelFetch(sTD2DInputs[2], px, 0);
    vec3 p = texelFetch(sTD2DInputs[3], px, 0).xyz;
    vec3 v = texelFetch(sTD2DInputs[4], px, 0).xyz;
    vec3 home = hA.xyz;
    float q = hA.w;
    float region = hB.x;
    int cls = int(hB.y + 0.5);
    float t = uA.x;
    float dt = 1.0 / 60.0;
    float hs = R(id, 7u);

    float sep = smoothstep(SEPTHR[cls] + 0.10 * hs, SEPTHR[cls] + 0.10 * hs + 0.25, uF.w);
    float leave = 0.0;
    float thr = (1.0 - (home.y + 0.5)) * 0.7 + hs * 0.3;                      // top of the tower first
    if (region < 1.5 && region > 0.5) leave = max(leave, smoothstep(thr, thr + 0.05, uF.y));
    if (region > 1.5 && region < 2.5) leave = max(leave, smoothstep(thr, thr + 0.05, uF.z));
    float thr2 = hs * 0.6 + (1.0 - (home.y + 0.5)) * 0.4;
    leave = max(leave, smoothstep(thr2, thr2 + 0.06, 1.0 - uG.x));
    if (R(id, 9u) < 0.18 * sep && uF.w > 0.05) leave = max(leave, 1.0);        // leakage from the dissolving classes
    float shape = clamp(uK.x + uK.y, 0.0, 1.0);
    if (shape > 0.001) leave = 1.0;

    float RS = uG.w;
    // coarse placement error: the rebuilt stone is imprecise until its class is reconstructed
    float coarse = (0.008 + 0.034 * q) * (1.0 - smoothstep(q, q + 0.15, uO.y)) * step(0.5, uO.w);
    vec3 target = home + (vec3(R(id, 3u), R(id, 4u), R(id, 5u)) - 0.5) * 2.0 * coarse;
    float hcls;
    vec3 ht = humanTarget(id, hcls);
    vec3 dnaT = dnaTarget(id, t);
    // shape blending: facade -> DNA -> human -> facade
    vec3 tgt = mix(target, dnaT, uK.x);
    tgt = mix(tgt, ht, uK.y);

    vec3 acc = vec3(0.0);
    float damp;
    if (shape > 0.001) {
        acc = (tgt - p) * 14.0;
        damp = 5.5;
        acc += flow3(p * 2.0, t) * 0.03;
    } else {
        acc = (target - p) * RS * 40.0;                                       // F_return = (P_original - P_current) * RETURN_STRENGTH
        damp = 0.25 + RS * 9.0;
        acc.y -= uG.y * 0.35;                                                 // gravity (negative lifts the building into the sky)
        acc += flow3(p * 2.0 + float(id % 7u), t * 0.4) * uG.z * 0.22;               // turbulence
        float tl = (region < 1.5 && region > 0.5) ? smoothstep(0.0, 0.2, uF.y) : 0.0;
        float tr = (region > 1.5 && region < 2.5) ? smoothstep(0.0, 0.2, uF.z) : 0.0;
        acc += vec3(0.22, 0.34, 0.05) * (tl + tr) * (0.4 + hs);              // the particle wind that carries the towers away
    }
    v += acc * dt;
    v *= exp(-damp * dt);
    if (leave < 0.001 || dot(p, p) < 1e-10) v = vec3(0.0);
    if (any(isnan(v)) || dot(v, v) > 400.0) v = vec3(0.0);
    fragColor = vec4(v, leave);
}
