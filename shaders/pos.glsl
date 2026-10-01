//#INCLUDE common.glsl
// PARTICLE POSITION. inputs: 0 ustate, 1 homeA, 2 homeB, 3 pos (previous), 4 vel (this frame; w = leave flag).
// Locked particles sit exactly on P_original (with a granular shimmer that grows with SPLAT_DISSOLVE); free ones integrate.
out vec4 fragColor;

const float SEPTHR[7] = float[7](0.10, 0.80, 0.45, 0.60, 0.22, 0.30, 0.75);

void main(){
    ivec2 px = ivec2(gl_FragCoord.xy);
    ivec2 res = textureSize(sTD2DInputs[1], 0);
    uint id = uint(px.y * res.x + px.x);
    vec4 hA = texelFetch(sTD2DInputs[1], px, 0);
    vec4 hB = texelFetch(sTD2DInputs[2], px, 0);
    vec3 home = hA.xyz;
    vec3 p = texelFetch(sTD2DInputs[3], px, 0).xyz;
    vec4 vv = texelFetch(sTD2DInputs[4], px, 0);
    float t = uA.x;
    int cls = int(hB.y + 0.5);
    float hs = R(id, 7u);
    float sep = smoothstep(SEPTHR[cls] + 0.10 * hs, SEPTHR[cls] + 0.10 * hs + 0.25, uF.w);
    float shape = clamp(uK.x + uK.y, 0.0, 1.0);

    if (dot(p, p) < 1e-10 || any(isnan(p)) || dot(p, p) > 400.0) p = home;
    if (vv.w < 0.001 && shape < 0.001) {
        float f1 = 1.0 + R(id, 11u) * 2.0;
        vec3 j = vec3(sin(t * f1 + R(id, 12u) * 6.28), sin(t * f1 * 1.3 + R(id, 13u) * 6.28), sin(t * f1 * 0.7 + R(id, 14u) * 6.28));
        p = home + j * sep * 0.012;                                          // granular shimmer: the stone is made of splats
    } else {
        p += vv.xyz * (1.0 / 60.0);
        if (uG.w > 0.9 && shape < 0.001 && distance(p, home) < 0.006) p = home;    // the last particles snap into place
    }
    fragColor = vec4(p, 1.0);
}
