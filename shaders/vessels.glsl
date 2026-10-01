//#INCLUDE common.glsl
// ARTERIES OF THE DOM: every vertical architectural pathway carries fluid. Alternate columns flow up (bright, oxygenated) and down
// (dark). Each kick launches a pressure wave from the heart that travels heart -> arteries -> columns -> windows -> towers.
// Bass = pressure pulses, mid = flow speed.   rgb = emissive, a = mask.
out vec4 fragColor;

void main(){
    vec2 uv = vUV.st;
    float amt = uC.y;
    if (amt < 0.002) { fragColor = vec4(0.0); return; }
    vec2 w = wuv(uv);
    float gap = G_GAP;
    vec2 s = toS(w);
    vec4 a = TA(w), b = TB(w), c = TC(w);

    // pressure wave from the heart. kick envelope decays like exp(-9 p): recover p, the time since the beat
    float kick = max(uH.z, 1e-4);
    float p = clamp(-log(kick) / 9.0, 0.0, 1.5);
    float dist = length(s - HEARTC);
    float radius = p * 2.4;
    float wave = exp(-pow((dist - radius) * 9.0, 2.0)) * (1.0 - clamp(p, 0.0, 1.0)) * clamp(kick * 6.0, 0.0, 1.0);
    wave *= 1.0 + uI.y * uH.y;                                   // bass: bigger pressure

    float id = floor(s.x * 70.0);
    float dir = mod(id, 2.0) < 1.0 ? 1.0 : -1.0;                // alternate columns flow up / down
    float ph = hash11(id) * 6.28;
    float speed = 1.2 + uI.z * uH.y * 3.0 + uR.w * 1.5;
    float flow = pow(max(0.0, sin(s.y * 38.0 - dir * uA.x * speed * 3.0 + ph)), 7.0);
    float flow2 = pow(max(0.0, sin(s.y * 91.0 - dir * uA.x * speed * 5.0 + ph * 1.7)), 14.0);
    vec3 up = mix(vec3(0.9, 0.18, 0.08), vec3(1.0, 0.85, 0.6), flow * 0.7);
    vec3 dn = mix(vec3(0.16, 0.05, 0.38), vec3(0.4, 0.3, 0.9), flow * 0.5);
    vec3 fluid = dir > 0.0 ? up : dn;

    // particles in the stream
    vec2 cell = vec2(id, floor(s.y * 150.0 + dir * uA.x * 22.0 * speed));
    float spark = step(0.972, hash21(cell)) * (dir > 0.0 ? 1.0 : 0.6);

    float vessel = c.y * a.w * (1.0 - gap);
    float base = 0.18 + 0.85 * flow + 0.5 * flow2 + 1.8 * spark;
    vec3 col = fluid * base * vessel;
    col *= 1.0 + 1.6 * wave;                                    // the wave lights the vessels as it passes
    col += vec3(1.0, 0.55, 0.3) * wave * vessel * 1.2;

    // wave reaches windows (tracery lights), then towers and ornaments
    float near = max(TA(w + vec2(7.0 * PX / AR, 0.0)).y, TA(w - vec2(7.0 * PX / AR, 0.0)).y);
    float winEdge = a.z * max(near, a.y);
    col += vec3(1.0, 0.45, 0.25) * wave * winEdge * 1.1 * a.w;
    col += vec3(0.8, 0.12, 0.08) * wave * (b.x + b.y) * 0.18 * a.w * (1.0 - gap);
    col += vec3(1.0, 0.7, 0.4) * wave * c.w * 0.7;

    float biology = 0.6 + 0.4 * uB.w;
    float m = clamp(vessel + winEdge * wave + c.w * wave * 0.5, 0.0, 1.0);
    fragColor = vec4(col * amt * biology, m * amt);
}
