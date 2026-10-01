// KOELNER DOM - shared GLSL.
// Space: uv in 0..1 (x right, y up). "s-space" = (uv.x * AR, uv.y): height 1, width AR, so circles are round.
// Convention for every facade layer TOP:  input0 = ustate (24x1 uniform texture), input1 = twinA, input2 = twinB, input3 = twinC.
//   twinA = (height, windows, edge, solid)   twinB = (towerL, towerR, center, roof)   twinC = (portals, columns, statues, ornaments)
// ustate packs (index: x y z w) - written once per frame by SHOW_CONTROL/brain.py:
//  0 A: time, showT, breath, beat             1 B: stone, crack, machine, bio
//  2 C: bone, artery, heart, root             3 D: rd, neural, sync, eyeMorph
//  4 E: eyeOpen, eyeX, eyeY, pupil            5 F: crowd, towerL, towerR, splatDissolve
//  6 G: stability, gravity, turbulence, returnStrength
//  7 H: volumetric, audioReact, kick, bpm     8 I: sub, bass, mid, high
//  9 J: transient, master, silence, split     10 K: dna, human, humanStage, audience
// 11 L: scaleAmt, scaleStage, enterProg, recursion   12 M: crowdL, crowdC, crowdR, destab
// 13 N: anomBlink, anomOrnament, anomShadow, anomColumn  14 O: rootBio, recon, splatVis, humanStone
// 15 P: breathCenter, breathTowers, breathColumns, breathWindows   16 Q: fade, gearAngle, lastLook, stonePulse
// 17 R: audT, enterAmt, crackPhase, vascularBoost
#ifdef IS_MAT
uniform sampler2D uSt;
vec4 U(int i){ return texelFetch(uSt, ivec2(i, 0), 0); }
#elif defined(NO_INPUTS)
vec4 U(int i){ return vec4(0.0); }
#else
vec4 U(int i){ return texelFetch(sTD2DInputs[0], ivec2(i, 0), 0); }
#endif
#define uA U(0)
#define uB U(1)
#define uC U(2)
#define uD U(3)
#define uE U(4)
#define uF U(5)
#define uG U(6)
#define uH U(7)
#define uI U(8)
#define uJ U(9)
#define uK U(10)
#define uL U(11)
#define uM U(12)
#define uN U(13)
#define uO U(14)
#define uP U(15)
#define uQ U(16)
#define uR U(17)

const float PI  = 3.14159265;
const float TAU = 6.2831853;
const float AR  = 0.5625;            // 720 / 1280
const float PX  = 1.0 / 1280.0;
const float CXM = 0.28125;           // facade centre line (s-space)
const float XTL = 0.105;             // left tower centre
const float XTR = 0.4575;            // right tower centre
const vec2  ROSE = vec2(0.28125, 0.485);
const float ROSER = 0.05;
const vec2  HEARTC = vec2(0.28125, 0.17);

// ---- hashing / noise -------------------------------------------------------------------------------
uint pcg(uint v){
    uint s = v * 747796405u + 2891336453u;
    uint w = ((s >> ((s >> 28u) + 4u)) ^ s) * 277803737u;
    return (w >> 22u) ^ w;
}
float R(uint id, uint k){ return float(pcg(id * 2654435761u + k * 97531u + 12345u)) * (1.0 / 4294967295.0); }
float hash11(float x){ return fract(sin(x * 12.9898) * 43758.5453); }
float hash21(vec2 p){ p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
vec2  hash22(vec2 p){ float n = hash21(p); return vec2(n, hash21(p + n + 17.17)); }
float vnoise(vec2 p){
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1, 0)), f.x), mix(hash21(i + vec2(0, 1)), hash21(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p){
    float a = 0.5, s = 0.0;
    for (int i = 0; i < 5; i++) { s += a * vnoise(p); p = p * 2.03 + 11.7; a *= 0.5; }
    return s;
}
mat2 rot(float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }
float sat(float x){ return clamp(x, 0.0, 1.0); }
float aa(float d){ return smoothstep(-PX * 1.2, PX * 1.2, d); }          // d > 0 inside (height units)
float sm01(float a, float b, float x){ return smoothstep(a, b, x); }
vec2 toS(vec2 uv){ return vec2(uv.x * AR, uv.y); }

// ---- Gothic primitives ----------------------------------------------------------------------------
// pointed (equilateral) arch: > 0 inside. spring line at y0 + h, apex at y0 + h + sqrt(3) w
float archSD(vec2 s, float cx, float y0, float w, float h){
    float dx = abs(s.x - cx);
    float top = y0 + h + sqrt(max(0.0, 4.0 * w * w - (dx + w) * (dx + w)));
    return min(min(w - dx, s.y - y0), top - s.y);
}
float sdSeg(vec2 p, vec2 a, vec2 b){
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-9), 0.0, 1.0);
    return length(pa - ba * h);
}

// Windows (lancets): cx, y0, w, h in s-space.  Index 0..12; the rose window is separate (ROSE).
const int NW = 13;
const vec4 WN[13] = vec4[13](
    vec4(0.070, 0.30, 0.026, 0.10), vec4(0.140, 0.30, 0.026, 0.10),
    vec4(AR - 0.070, 0.30, 0.026, 0.10), vec4(AR - 0.140, 0.30, 0.026, 0.10),
    vec4(0.075, 0.50, 0.022, 0.085), vec4(0.135, 0.50, 0.022, 0.085),
    vec4(AR - 0.075, 0.50, 0.022, 0.085), vec4(AR - 0.135, 0.50, 0.022, 0.085),
    vec4(XTL, 0.655, 0.014, 0.03), vec4(XTR, 0.655, 0.014, 0.03),
    vec4(CXM, 0.24, 0.05, 0.09),
    vec4(0.2145, 0.30, 0.022, 0.09), vec4(0.348, 0.30, 0.022, 0.09));

// window centre (s-space) and half-size, used by the eyes
vec2 winCenter(int i){ vec4 w = WN[i]; return vec2(w.x, w.y + (w.w + 1.732 * w.z) * 0.5); }
vec2 winHalf(int i){ vec4 w = WN[i]; return vec2(w.z, (w.w + 1.732 * w.z) * 0.5); }

// tower half-width at height y
float towerHW(float y){
    if (y < 0.58) return 0.075;
    if (y < 0.72) return 0.062;
    return 0.062 * clamp(1.0 - (y - 0.72) / 0.26, 0.0, 1.0);
}
// pier x positions in the central nave
float navePier(float x){
    float k = (x - 0.1805) / 0.0672;
    return abs(x - (0.1805 + floor(k + 0.5) * 0.0672));
}

// ---- facade maps (twin) sampling ------------------------------------------------------------------
#if !defined(IS_MAT) && !defined(NO_INPUTS) && !defined(NO_TWIN)
vec4 TA(vec2 uv){ return texture(sTD2DInputs[1], uv); }
vec4 TB(vec2 uv){ return texture(sTD2DInputs[2], uv); }
vec4 TC(vec2 uv){ return texture(sTD2DInputs[3], uv); }

// The breathing + opening warp: all surface layers sample the facade at the displaced uv, so the architecture inhales
// as one body.  G_GAP receives the "interior visible" amount (the opened central portal).
float G_GAP = 0.0;
float gapHalf(float y){                                                   // vesica (lens) slit in the centre of the nave
    float t = (y - 0.25) / 0.27;
    return max(0.0, 1.0 - t * t) * 0.082 * uJ.w;
}
vec2 wuv(vec2 uv){
    vec4 a = TA(uv), b = TB(uv), c = TC(uv);
    float h = a.x;
    float bw = b.z * uP.x + (b.x + b.y) * uP.y + c.y * uP.z + a.y * uP.w;
    vec2 d = (uv - vec2(0.5, 0.45)) * uA.z * 0.028 * h * clamp(bw, 0.0, 1.0);
    vec2 u2 = uv - d;
    // central facade opens: stone sections slide outward and the lens-shaped gap shows the interior
    vec2 s = toS(u2);
    float g = gapHalf(s.y);
    float dx = s.x - CXM;
    G_GAP = 0.0;
    float ax = abs(dx);
    if (uJ.w > 0.001 && s.y < 0.52 && g > 0.0 && ax < 0.1012) {   // only the nave slides; the towers stay put
        G_GAP = 1.0 - smoothstep(g - 0.004, g + 0.001, ax);
        if (ax >= g) u2.x -= sign(dx) * g / AR;                   // stone beyond the slit is read from further in: it moved outward
    }
    return u2;
}
#endif

vec3 pal(float t, vec3 a, vec3 b, vec3 c, vec3 d){ return a + b * cos(TAU * (c * t + d)); }
float luma(vec3 c){ return dot(c, vec3(0.299, 0.587, 0.114)); }
