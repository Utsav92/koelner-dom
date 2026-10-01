#define NO_INPUTS
//#INCLUDE common.glsl
// DOM DIGITAL TWIN (procedural stand-in for a LiDAR / photogrammetry scan): height, windows, edges and architectural masks.
// Static: no ustate dependency, so it cooks once.  Mode (uMode.x): 0 = twinA, 1 = twinB, 2 = twinC.
// NOTE: this shader must not call U(); it has no ustate input.
uniform vec4 uMode;
out vec4 fragColor;

struct D { float h, win, solid, tl, tr, ce, roof, por, col, sta, orn; };

float towerSD(vec2 s, float xc){
    float hw = towerHW(s.y);
    return min(min(hw - abs(s.x - xc), s.y), 0.985 - s.y);
}

D dom(vec2 uv){
    vec2 s = toS(uv);
    D r;
    float dL = towerSD(s, XTL), dR = towerSD(s, XTR);
    r.tl = aa(dL); r.tr = aa(dR);

    // nave: straight to y = .50, then the gable; the flèche rises from the crossing
    float gx = 0.1012 * (1.0 - clamp((s.y - 0.50) / 0.16, 0.0, 1.0));
    float dC = min(min(s.y, 0.66 - s.y), (s.y < 0.50 ? 0.1012 : gx) - abs(s.x - CXM));
    float fl = min(min(s.y - 0.60, 0.86 - s.y), 0.012 * (1.0 - clamp((s.y - 0.60) / 0.26, 0.0, 1.0)) - abs(s.x - CXM));
    float ce = aa(dC);
    r.ce = ce * (1.0 - max(r.tl, r.tr));
    r.roof = max(aa(fl), ce * smoothstep(0.50, 0.505, s.y) * (1.0 - max(r.tl, r.tr)));
    r.solid = max(max(r.tl, r.tr), max(ce, aa(fl)));

    // windows
    float wd = -1.0;
    for (int i = 0; i < NW; i++) { vec4 w = WN[i]; wd = max(wd, archSD(s, w.x, w.y, w.z, w.w)); }
    wd = max(wd, ROSER - length(s - ROSE));
    r.win = aa(wd) * r.solid;

    // portals (three pointed arches)
    float pd = max(archSD(s, CXM, 0.0, 0.055, 0.13), max(archSD(s, XTL, 0.0, 0.035, 0.09), archSD(s, XTR, 0.0, 0.035, 0.09)));
    r.por = aa(pd) * r.solid;

    // columns / piers: tower edge piers + colonnettes (ribs converge along the spires), nave piers
    float ct = abs(s.x - XTL) / max(towerHW(s.y), 0.004);
    float ctr = abs(s.x - XTR) / max(towerHW(s.y), 0.004);
    float pier = 0.0;
    float tw = max(0.006, 0.0075 * (towerHW(s.y) / 0.075));
    pier = max(pier, aa(min(1.0 - 0.0, ct - 0.90) * 0.075 * 0.5) * r.tl);
    pier = max(pier, aa(min(1.0 - 0.0, ctr - 0.90) * 0.075 * 0.5) * r.tr);
    pier = max(pier, aa(tw - abs(ct - 0.42) * towerHW(s.y)) * r.tl * step(s.y, 0.58));
    pier = max(pier, aa(tw - abs(ctr - 0.42) * towerHW(s.y)) * r.tr * step(s.y, 0.58));
    pier = max(pier, aa(0.0055 - navePier(s.x)) * r.ce * step(s.y, 0.50));
    r.col = pier * r.solid;

    // statues: niches with a head + body
    float st = -1.0;
    for (int row = 0; row < 2; row++) {
        float y = row == 0 ? 0.075 : 0.135;
        for (int k = 0; k < 4; k++) {
            float x = CXM + (k < 2 ? -1.0 : 1.0) * (k % 2 == 0 ? 0.078 : 0.098);
            st = max(st, 0.012 - sdSeg(s, vec2(x, y - 0.012), vec2(x, y + 0.012)));
        }
    }
    for (int k = 0; k < 5; k++) {
        float tx = (float(k) - 2.0) * 0.028;
        st = max(st, 0.0095 - sdSeg(s, vec2(XTL + tx, 0.185), vec2(XTL + tx, 0.205)));
        st = max(st, 0.0095 - sdSeg(s, vec2(XTR + tx, 0.185), vec2(XTR + tx, 0.205)));
    }
    r.sta = aa(st) * r.solid * (1.0 - r.por);

    // ornaments: pinnacles on the setbacks, crockets on the spires and gable, openwork lacework in the upper stage
    float o = 0.0;
    for (int i = 0; i < 4; i++) {
        float px = (i < 2 ? XTL : XTR) + (i % 2 == 0 ? -0.067 : 0.067);
        float k = 1.0 - clamp((s.y - 0.58) / 0.07, 0.0, 1.0);
        o = max(o, aa(min(0.0085 * k - abs(s.x - px), min(s.y - 0.575, 0.65 - s.y))));
    }
    float ctMax = max(ct * r.tl, ctr * r.tr);
    float spire = step(0.72, s.y) * smoothstep(0.83, 0.93, ctMax) * step(0.001, ctMax);
    o = max(o, spire * step(0.55, fract(s.y * 46.0)) * (r.tl + r.tr));
    float gab = step(0.5, s.y) * smoothstep(0.88, 0.96, abs(s.x - CXM) / max(gx, 0.004)) * r.ce * step(s.y, 0.655);
    o = max(o, gab * step(0.55, fract(s.y * 70.0)));
    float lace = step(0.58, s.y) * step(s.y, 0.72) * (r.tl + r.tr);
    vec2 g = fract(s * 52.0) - 0.5;
    float lc = step(0.36, length(g)) * step(length(g), 0.46);
    o = max(o, lace * lc * 0.8);
    r.orn = clamp(o, 0.0, 1.0) * r.solid;

    // height field: the relief the projector shading and the particle depths use
    float h = 0.40 * r.solid;
    h += 0.20 * (r.tl + r.tr) * step(0.58, s.y) + 0.08 * (r.tl + r.tr);
    h += 0.10 * r.col + 0.17 * r.orn + 0.07 * r.sta;
    h -= 0.26 * r.win + 0.34 * r.por;
    h += 0.10 * r.roof;
    r.h = clamp(h / 0.9, 0.0, 1.0);
    return r;
}

void main(){
    vec2 uv = vUV.st;
    D d = dom(uv);
    int m = int(uMode.x + 0.5);
    if (m == 0) {
        fragColor = vec4(d.h, d.win, 0.0, d.solid);
    } else if (m == 1) {
        fragColor = vec4(d.tl, d.tr, d.ce, d.roof);
    } else {
        fragColor = vec4(d.por, d.col, d.sta, d.orn);
    }
}
