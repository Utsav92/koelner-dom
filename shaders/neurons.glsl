//#INCLUDE common.glsl
// NEURAL CATHEDRAL: every architectural intersection (column feet, window edges, ornaments) becomes a node; tracery becomes axons.
// Crowd movement stimulates the matching side (left crowd -> left tower). High crowd energy -> a cascade. With SYNC the pulses
// converge on the central rose window (the processing core).   rgb = emissive, a = mask.
out vec4 fragColor;

const float CELL = 0.046;

bool nodeAt(vec2 cell, out vec2 pos){
    vec2 j = hash22(cell + 5.0);
    pos = (cell + 0.2 + 0.6 * j) * CELL;
    vec2 uv = vec2(pos.x / AR, pos.y);
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) return false;
    vec4 a = TA(uv), c = TC(uv);
    return a.w > 0.5 && (a.z > 0.10 || c.y > 0.5 || c.w > 0.5) && a.y < 0.5;
}

void main(){
    vec2 uv = vUV.st;
    float act = uD.y;
    if (act < 0.002) { fragColor = vec4(0.0); return; }
    vec2 w = wuv(uv);
    float gap = G_GAP;
    vec2 s = toS(w);
    vec4 a = TA(w);
    float sync = uD.z;
    float t = uA.x;
    vec2 base = floor(s / CELL);
    vec3 col = vec3(0.0);
    float mask = 0.0;
    float crowd = uF.x;

    for (int j = -1; j <= 1; j++)
        for (int i = -1; i <= 1; i++) {
            vec2 cell = base + vec2(float(i), float(j));
            vec2 p0;
            if (!nodeAt(cell, p0)) continue;
            float h0 = hash21(cell);
            // stimulation by the crowd: left / centre / right thirds of the facade
            float side = p0.x / AR;
            float stim = uM.x * smoothstep(0.55, 0.0, side) + uM.y * (1.0 - abs(side - 0.5) * 3.0) + uM.z * smoothstep(0.45, 1.0, side);
            float local = clamp(act + stim * 0.8, 0.0, 1.0);
            float dcore = length(p0 - ROSE);
            // node
            float dn = length(s - p0);
            float fire = pow(max(0.0, sin(t * (2.0 + 3.0 * local) + h0 * 40.0 * (1.0 - sync) - dcore * 14.0 * sync)), 10.0);
            float nodeGlow = exp(-dn * 220.0) * (0.35 + 1.8 * fire * local);
            col += mix(vec3(0.2, 0.6, 1.0), vec3(1.0, 0.95, 0.85), fire) * nodeGlow;
            mask = max(mask, nodeGlow);
            // axons to three neighbours
            for (int e = 0; e < 3; e++) {
                vec2 nc = cell + (e == 0 ? vec2(1.0, 0.0) : (e == 1 ? vec2(0.0, 1.0) : vec2(1.0, 1.0)));
                vec2 p1;
                if (!nodeAt(nc, p1)) continue;
                vec2 mid = 0.5 * (p0 + p1);
                vec4 am = TA(vec2(mid.x / AR, mid.y));
                if (am.w < 0.5) continue;
                vec2 pa = s - p0, ba = p1 - p0;
                float u = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
                float dl = length(pa - ba * u);
                float line = exp(-dl * 700.0);
                // signal direction: toward the core when synchronised
                float flip = (length(p1 - ROSE) < length(p0 - ROSE)) ? 0.0 : 1.0;
                float uu = mix(u, 1.0 - u, flip * sync);
                float he = hash21(cell * 3.1 + float(e));
                float ph = fract(t * (0.35 + 0.5 * local) * mix(0.6 + he, 1.0, sync) - he * 7.0 * (1.0 - sync) - dcore * 1.6 * sync);
                float sig = exp(-pow((uu - ph) * 7.0, 2.0)) * local;
                // cascade from crowd stimulation points
                sig += crowd * 0.6 * exp(-pow((dcore - fract(t * 0.4 + he) * 1.2) * 9.0, 2.0)) * smoothstep(0.55, 0.9, crowd);
                vec3 lc = mix(vec3(0.10, 0.35, 0.9), vec3(0.8, 0.95, 1.0), clamp(sig, 0.0, 1.0));
                col += lc * line * (0.18 + 2.2 * sig);
                mask = max(mask, line * (0.25 + sig));
            }
        }

    // brain-like folded tissue under the lines when the whole building is thinking
    float fold = 1.0 - abs(2.0 * fbm(s * 34.0 + 2.0) - 1.0);
    col += vec3(0.5, 0.25, 0.35) * pow(fold, 5.0) * smoothstep(0.7, 1.0, act) * 0.22 * a.w;
    // convergence on the core: signals pour into the rose window
    float dr = length(s - ROSE);
    col += vec3(0.6, 0.85, 1.0) * sync * exp(-pow((dr - fract(-t * 0.5) * 0.7) * 16.0, 2.0)) * 0.35 * a.w;
    col += vec3(0.8, 0.95, 1.0) * sync * exp(-dr * 18.0) * 0.8 * act;
    float vis = a.w * (1.0 - gap);
    fragColor = vec4(col * vis * (0.6 + 0.8 * uI.w * uH.y), clamp(mask, 0.0, 1.0) * vis);
}
