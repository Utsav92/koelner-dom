#define NO_TWIN
//#INCLUDE common.glsl
// ENTER THE CATHEDRAL: a virtual camera flies into the central portal and through stone, machinery, arteries, the heart, cells, DNA,
// neurons (which become Gothic arches), then pulls out to reveal the Dom again - inside itself.
// inputs: 0 ustate, 1 facade (comp2 colour).  uL.z = flight progress 0..1, uR.y = visibility.
out vec4 fragColor;

const int NSEG = 8;
const float SEGLEN = 1.0;

float ridge(vec2 p){ return 1.0 - abs(2.0 * fbm(p) - 1.0); }

vec2 ring(float ang, float z, float f){ return vec2(cos(ang), sin(ang)) * f + vec2(z * 1.7, z * 0.9); }

vec3 seg(int k, float ang, float z, float r, float beat){
    float u = ang / TAU * 24.0;                    // around the tunnel wall
    float t = uA.x;
    if (k == 0) {                                  // stone: masonry + Gothic ribs every unit of depth
        vec2 g = vec2(u, z * 8.0);
        float row = floor(g.y);
        vec2 f = fract(g);
        float blk = hash21(vec2(floor(g.x + hash11(row) * 5.0), row));
        float mortar = smoothstep(0.0, 0.08, f.x) * smoothstep(0.0, 0.1, f.y);
        vec3 c = vec3(0.55, 0.5, 0.44) * (0.3 + 0.5 * blk) * mix(0.4, 1.0, mortar);
        float rib = pow(max(0.0, cos(z * TAU)), 18.0) * (0.6 + 0.4 * sin(ang * 6.0));
        return c + vec3(1.0, 0.8, 0.5) * rib * 0.7;
    } else if (k == 1) {                           // machinery
        vec2 g = vec2(u * 0.5, z * 3.0);
        vec2 cell = floor(g), f = fract(g) - 0.5;
        float h = hash21(cell);
        float a = atan(f.y, f.x) + uQ.y * (h > 0.5 ? 1.0 : -1.0) * 3.0;
        float rad = 0.22 + 0.15 * h;
        float d = length(f) - rad - 0.05 * smoothstep(-0.3, 0.3, sin(a * 12.0));
        float body = (1.0 - smoothstep(0.0, 0.02, d)) * smoothstep(0.0, 0.02, length(f) - rad * 0.35);
        return mix(vec3(0.03, 0.02, 0.02), vec3(0.75, 0.48, 0.18) * (0.6 + 0.6 * h), body);
    } else if (k == 2) {                           // arteries: streaming red wall
        float f = pow(max(0.0, sin(z * 24.0 - t * 5.0 + fbm(ring(ang, z, 3.0)) * 6.0)), 4.0);
        return mix(vec3(0.25, 0.01, 0.03), vec3(1.0, 0.25, 0.15), f) * (0.6 + beat);
    } else if (k == 3) {                           // the heart: muscle folds + valves, pulsing
        float folds = ridge(ring(ang, z * 0.5, 2.0) + t * 0.05);
        vec3 c = mix(vec3(0.3, 0.0, 0.02), vec3(1.0, 0.2, 0.12), folds * folds);
        float valve = pow(abs(sin(ang * 3.0 + z * 4.0)), 8.0);
        return c * (0.5 + 1.2 * beat) + vec3(1.0, 0.7, 0.3) * valve * 0.4;
    } else if (k == 4) {                           // cells
        vec2 g = vec2(u * 0.5, z * 2.2);
        vec2 cell = floor(g), f = fract(g) - 0.5;
        vec2 o = (hash22(cell) - 0.5) * 0.4;
        float d = length(f - o);
        float memb = 1.0 - smoothstep(0.0, 0.03, abs(d - 0.3));
        float nuc = exp(-d * 18.0);
        return vec3(0.1, 0.5, 0.6) * (0.2 + memb) + vec3(0.9, 0.5, 0.9) * nuc * 0.8;
    } else if (k == 5) {                           // DNA: two helices along the tunnel axis with rungs
        float th = z * TAU * 0.6;
        float d1 = abs(sin((ang - th) * 0.5)), d2 = abs(sin((ang - th - PI) * 0.5));
        float s1 = exp(-d1 * 18.0), s2 = exp(-d2 * 18.0);
        float rung = step(0.93, fract(z * 14.0)) * smoothstep(0.0, 0.5, abs(cos((ang - th) * 0.5)));
        return vec3(1.0, 0.35, 0.2) * s1 + vec3(0.2, 0.55, 1.0) * s2 + vec3(0.7, 1.0, 0.5) * rung * 0.8;
    } else if (k == 6) {                           // neurons: branching filaments with travelling spikes
        float rr = ridge(ring(ang, z * 1.3, 2.5) + 2.0);
        float ax = pow(rr, 14.0);
        float spk = pow(max(0.0, sin(z * 30.0 - t * 8.0 + u)), 12.0);
        return vec3(0.2, 0.5, 1.0) * ax * (0.5 + 2.5 * spk) + vec3(0.8, 0.95, 1.0) * ax * spk;
    }
    // neurons organised into Gothic arches (the cathedral inside the neuron)
    float zf = fract(z * 2.0);
    vec2 pp = vec2(cos(ang), sin(ang)) * r * 4.0;
    float arch = archSD(pp * 0.25 + vec2(0.0, 0.5), 0.0, 0.0, 0.5 * (1.0 - zf * 0.6), 0.2);
    float line = 1.0 - smoothstep(0.0, 0.03, abs(arch));
    float spk2 = pow(max(0.0, sin(z * 22.0 - t * 6.0)), 10.0);
    return vec3(0.4, 0.75, 1.0) * line * (0.5 + 1.5 * spk2) + vec3(0.1, 0.2, 0.5) * pow(ridge(ring(ang, z * 2.0, 3.0)), 10.0);
}

void main(){
    vec2 uv = vUV.st;
    float amt = uR.y;
    if (amt < 0.002) { fragColor = vec4(0.0); return; }
    float prog = uL.z;
    vec2 c = vec2(0.5, 0.115);
    vec2 p = (uv - c) * vec2(AR, 1.0) * vec2(1.0, 0.9);
    float r = max(length(p), 0.004);
    float ang = atan(p.y, p.x);
    float beat = uA.w;
    // tunnel depth: nearer the centre = farther away; the camera advances with progress
    float z = 0.07 / r + prog * float(NSEG) * SEGLEN * 0.85;
    float zs = z / SEGLEN;
    int k0 = int(floor(zs)) % NSEG;
    int k1 = (k0 + 1) % NSEG;
    float zf = fract(zs);
    vec3 c0 = seg(k0, ang, z, r, beat);
    vec3 c1 = seg(k1, ang, z, r, beat);
    vec3 col = mix(c0, c1, smoothstep(0.75, 1.0, zf));
    col *= smoothstep(0.0, 0.22, r) * (0.35 + 0.65 * (1.0 - exp(-r * 6.0)));
    col += vec3(1.0, 0.9, 0.75) * exp(-r * 22.0) * 0.5 * (0.3 + prog);              // light at the end of the passage

    // pull-out: the Dom appears small at the centre of the tunnel and grows until it IS the picture
    float outro = smoothstep(0.86, 1.0, prog);
    float sc = mix(10.0, 1.0, outro * outro);
    vec2 fuv = (uv - c) * sc + c;
    vec4 fac = texture(sTD2DInputs[1], vec2(fuv.x, fuv.y + (0.5 - c.y) * (1.0 - 1.0 / sc) * 0.0));
    bool inFrame = fuv.x > 0.0 && fuv.x < 1.0 && fuv.y > 0.0 && fuv.y < 1.0;
    float edgeF = smoothstep(0.0, 0.03, fuv.x) * smoothstep(0.0, 0.03, 1.0 - fuv.x) * smoothstep(0.0, 0.03, fuv.y) * smoothstep(0.0, 0.03, 1.0 - fuv.y);
    float showFac = outro * (inFrame ? edgeF : 0.0);
    col = mix(col, fac.rgb, showFac);
    fragColor = vec4(col * amt, amt);
}
