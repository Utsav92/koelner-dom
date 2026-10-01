// PROJECTOR OUTPUT: crops one projector's region of the master canvas, applies keystone (4 corner offsets), radial lens distortion
// and an edge-blend ramp (gamma-correct). input 0 = master.
uniform vec4 uReg;    // u0, u1, v0, v1  (region of the master canvas this projector covers)
uniform vec4 uLens;   // k1, k2, centre x, centre y
uniform vec4 uCA;     // corner offsets: c00.xy, c10.xy
uniform vec4 uCB;     // corner offsets: c01.xy, c11.xy
uniform vec4 uBlend;  // blend width bottom, top, left, right (0..0.5 of projector), gamma
out vec4 fragColor;
void main(){
    vec2 p = vUV.st;
    vec2 o = mix(mix(uCA.xy, uCA.zw, p.x), mix(uCB.xy, uCB.zw, p.x), p.y);
    vec2 q = p + o;
    vec2 r = q - uLens.zw;
    float r2 = dot(r, r);
    q = uLens.zw + r * (1.0 + uLens.x * r2 + uLens.y * r2 * r2);
    vec2 m = vec2(mix(uReg.x, uReg.y, q.x), mix(uReg.z, uReg.w, q.y));
    vec3 c = (m.x < 0.0 || m.x > 1.0 || m.y < 0.0 || m.y > 1.0) ? vec3(0.0) : texture(sTD2DInputs[0], m).rgb;
    float b = 1.0;
    if (uBlend.x > 0.0) b *= smoothstep(0.0, uBlend.x, p.y);
    if (uBlend.y > 0.0) b *= smoothstep(0.0, uBlend.y, 1.0 - p.y);
    if (uBlend.z > 0.0) b *= smoothstep(0.0, uBlend.z, p.x);
    if (uBlend.w > 0.0) b *= smoothstep(0.0, uBlend.w, 1.0 - p.x);
    c *= pow(b, 1.0 / 2.2);
    fragColor = vec4(c, 1.0);
}
