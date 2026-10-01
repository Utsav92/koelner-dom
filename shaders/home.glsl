//#INCLUDE common.glsl
// GAUSSIAN-SPLAT HOME POSITIONS ("P_original"): every particle owns one texel and one fixed place on the facade, found by
// rejection-sampling the twin (denser on edges, columns, ornaments). Static: cooks once.
// uMode.x = 0 -> (x, y, z, reconstruction threshold q)   1 -> (region, classId, seed, outerEdge)
// regions: 1 left tower, 2 right tower, 3 nave, 4 roof.  classes: 0 outer edge, 1 tower, 2 column, 3 window, 4 statue, 5 ornament, 6 rest
uniform vec4 uMode;
out vec4 fragColor;

void main(){
    ivec2 px = ivec2(gl_FragCoord.xy);
    ivec2 res = ivec2(uTDOutputInfo.res.zw);
    uint id = uint(px.y * res.x + px.x);
    vec2 uv = vec2(0.5, 0.3);
    for (int k = 0; k < 24; k++) {
        vec2 c = vec2(R(id, uint(2 * k)), R(id, uint(2 * k + 1)));
        vec4 a = TA(c), cc = TC(c);
        float detail = clamp(a.z * 3.0 + cc.y + cc.w + cc.z, 0.0, 1.0);
        if (a.w > 0.5 && R(id, uint(100 + k)) < 0.38 + 0.62 * detail) { uv = c; break; }
        uv = c;
    }
    vec4 a = TA(uv), b = TB(uv), c = TC(uv);
    float e = 5.0 * PX;
    float outer = (a.w > 0.5 && (TA(uv + vec2(e / AR, 0.0)).w < 0.5 || TA(uv - vec2(e / AR, 0.0)).w < 0.5 ||
                   TA(uv + vec2(0.0, e)).w < 0.5 || TA(uv - vec2(0.0, e)).w < 0.5)) ? 1.0 : 0.0;
    float cls = 6.0;
    if (outer > 0.5) cls = 0.0;
    else if (c.w > 0.4) cls = 5.0;
    else if (c.z > 0.4) cls = 4.0;
    else if (c.y > 0.4) cls = 2.0;
    else if (a.y > 0.4) cls = 3.0;
    else if (b.x + b.y > 0.5) cls = 1.0;
    float region = b.x > 0.5 ? 1.0 : (b.y > 0.5 ? 2.0 : (b.w > 0.5 ? 4.0 : 3.0));
    float hs = R(id, 7u);
    float q;
    if (cls < 0.5) q = 0.05 * hs;
    else if (cls < 1.5) q = 0.14 + 0.06 * hs;
    else if (cls < 2.5) q = 0.32 + 0.06 * hs;
    else if (cls < 3.5) q = 0.46 + 0.06 * hs;
    else if (cls < 4.5) q = 0.60 + 0.06 * hs;
    else if (cls < 5.5) q = 0.72 + 0.06 * hs;
    else q = 0.80 + 0.18 * hs;
    vec3 home = vec3(uv.x * AR - AR * 0.5, uv.y - 0.5, (a.x - 0.4) * 0.12);
    if (uMode.x < 0.5) fragColor = vec4(home, q);
    else fragColor = vec4(region, cls, hs, outer);
}
