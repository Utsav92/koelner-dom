//#INCLUDE common.glsl
// CRACK ENGINE. inputs: 0 ustate, 1 twinA, 2 twinB, 3 twinC, 4 rd_prev (previous-frame reaction-diffusion).
// Cracks are voronoi fractures + masonry-joint cracks. They start at architectural joints (window sills, portal feet, setbacks) and
// the front travels outwards: arrival = distance-to-nearest-joint, bent by the reaction-diffusion field (branching probability).
// Output: rgb = emissive glow (white -> amber -> deep red as growth rises), a = crack core darkness.
out vec4 fragColor;

vec2 vor(vec2 p, out vec2 id){                       // returns (F1, F2)
    vec2 ip = floor(p), fp = fract(p);
    float f1 = 9.0, f2 = 9.0;
    id = vec2(0.0);
    for (int j = -1; j <= 1; j++)
        for (int i = -1; i <= 1; i++) {
            vec2 g = vec2(float(i), float(j));
            vec2 o = hash22(ip + g);
            float d = length(g + o - fp);
            if (d < f1) { f2 = f1; f1 = d; id = ip + g; }
            else if (d < f2) f2 = d;
        }
    return vec2(f1, f2);
}

float joints(vec2 s){                                // distance to the nearest architectural joint
    float d = 9.0;
    for (int i = 0; i < NW; i++) { vec4 w = WN[i]; d = min(d, length(s - vec2(w.x, w.y))); }
    d = min(d, length(s - vec2(CXM, 0.0)));
    d = min(d, length(s - vec2(XTL, 0.0)));
    d = min(d, length(s - vec2(XTR, 0.0)));
    d = min(d, length(s - vec2(XTL - 0.075, 0.58)));
    d = min(d, length(s - vec2(XTR + 0.075, 0.58)));
    d = min(d, length(s - vec2(CXM, 0.50)));
    d = min(d, length(s - ROSE) - ROSER);
    return d;
}

void main(){
    vec2 uv = vUV.st;
    float g = uB.y;
    vec2 w = wuv(uv);
    float gap = G_GAP;
    vec2 s = toS(w);
    vec4 a = TA(w), c = TC(w);
    if (g < 0.002) { fragColor = vec4(0.0); return; }

    float rdV = texture(sTD2DInputs[4], w).g;
    float arr = joints(s) * 1.25 + fbm(s * 7.0) * 0.22 - rdV * 0.35;
    float reach = g * 1.35;
    float alive = 1.0 - smoothstep(reach - 0.05, reach, arr);
    float age = clamp((reach - arr) * 2.5, 0.0, 1.0);

    // fracture network: masonry-aligned (stretched along courses) + a finer branch network that opens later
    vec2 wp = s + (vec2(fbm(s * 11.0), fbm(s * 11.0 + 7.3)) - 0.5) * 0.03;
    vec2 id1; vec2 f = vor(wp * vec2(16.0, 24.0), id1);
    float e1 = f.y - f.x;
    vec2 id2; vec2 f2 = vor(wp * vec2(44.0, 66.0) + 3.1, id2);
    float e2 = f2.y - f2.x;
    float width = 0.020 + 0.05 * g;
    float main_ = 1.0 - smoothstep(width * 0.5, width, e1);
    float fine = (1.0 - smoothstep(width * 0.35, width * 0.8, e2)) * smoothstep(0.30, 0.55, g) * step(0.5, hash21(id2));
    // masonry joint cracks: some mortar lines open along the course
    float row = floor(s.y / 0.0125);
    float jl = 1.0 - smoothstep(0.0, 0.0022 + 0.002 * g, abs(fract(s.y / 0.0125) - 0.5) - 0.5 + 0.5);
    float jcell = hash21(vec2(row, floor(s.x * 9.0)));
    float joint = (1.0 - smoothstep(0.0, 0.003 + 0.002 * g, abs(fract(s.y / 0.0125))*0.0125)) * step(0.82, jcell);
    float crack = max(max(main_, fine), joint * 0.9) * alive;
    // columns resist, windows are glass
    crack *= 1.0 - 0.8 * c.y;
    crack *= (1.0 - a.y) * a.w * (1.0 - gap);

    // colour: white -> amber -> deep red as the thing beneath wakes up
    vec3 white = vec3(1.0, 0.97, 0.9), amber = vec3(1.0, 0.55, 0.08), red = vec3(0.75, 0.04, 0.02);
    vec3 col = mix(white, amber, smoothstep(0.22, 0.5, g));
    col = mix(col, red, smoothstep(0.62, 0.95, g));
    float pulse = 0.75 + 0.25 * sin(uA.x * 1.7 + arr * 12.0) + uA.w * 0.5;
    float halo = exp(-e1 * 30.0) * alive * 0.5 * a.w * (1.0 - gap) * (1.0 - a.y);
    float glow = (crack * 1.6 + halo * 0.5) * (0.35 + 0.65 * smoothstep(0.0, 0.5, age + g * 0.5)) * pulse;
    fragColor = vec4(col * glow, crack);
}
