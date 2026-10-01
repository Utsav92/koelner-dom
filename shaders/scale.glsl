#define NO_TWIN
//#INCLUDE common.glsl
// SCALE ILLUSION without cuts: ONE ridged branching field is re-read at four scales. A crack becomes a canyon, the canyon walls
// round into a blood vessel, the vessel thins into a neuron, the neuron fires as lightning, and zooming outward the lightning is
// seen to be travelling through the whole cathedral.   uL.y = stage 0..4  (0 canyon, 1 vessel, 2 neuron, 3 lightning, 4 zoomed out).
// input 0 ustate only.
out vec4 fragColor;

float ridge(vec2 p){ return 1.0 - abs(2.0 * fbm(p) - 1.0); }

void main(){
    vec2 uv = vUV.st;
    float amt = uL.x;
    if (amt < 0.002) { fragColor = vec4(0.0); return; }
    float st = uL.y, t = uA.x;
    vec2 p = (uv - 0.5) * vec2(AR, 1.0);
    // camera: dives in until stage 3, then pulls far back
    float zoomIn = exp(-min(st, 3.0) * 0.62);
    float zoomOut = exp(max(st - 3.0, 0.0) * 1.55);
    p *= zoomIn * zoomOut * 5.0;
    p += vec2(0.0, -t * 0.05);
    p += 0.25 * vec2(sin(t * 0.07), cos(t * 0.06));

    vec2 wp = p + 0.35 * vec2(fbm(p * 1.3 + 3.0), fbm(p * 1.3 + 9.0));
    float r = ridge(wp * 0.9);                                   // 1 on the ridge line
    float dline = 1.0 - r;                                       // distance-like field: 0 on the line
    float wc = 1.0 - smoothstep(0.6, 1.1, st);
    float wv = smoothstep(0.6, 1.1, st) * (1.0 - smoothstep(1.6, 2.1, st));
    float wn = smoothstep(1.6, 2.1, st) * (1.0 - smoothstep(2.6, 3.1, st));
    float wl = smoothstep(2.6, 3.1, st);

    // canyon: steep stone walls, red glow at the bottom
    float depth = smoothstep(0.0, 0.5, dline);
    float wall = pow(depth, 0.7);
    vec3 stone = vec3(0.50, 0.45, 0.40) * (0.15 + 0.85 * wall) * (0.6 + 0.8 * fbm(p * 14.0));
    vec3 canyon = stone + vec3(1.0, 0.25, 0.05) * exp(-dline * 14.0) * 1.3;

    // vessel: tube profile, flowing cells
    float tube = sqrt(max(0.0, 1.0 - pow(clamp(dline / 0.22, 0.0, 1.0), 2.0)));
    float cells = pow(max(0.0, sin((wp.y + wp.x * 0.3) * 40.0 - t * 4.0 + fbm(wp * 6.0) * 5.0)), 5.0);
    vec3 vessel = (vec3(0.55, 0.03, 0.05) * (0.3 + tube) + vec3(1.0, 0.3, 0.2) * cells * 0.7 * tube) * step(dline, 0.22);
    vessel += vec3(0.4, 0.0, 0.02) * exp(-dline * 10.0) * 0.4;

    // neuron: thin glowing axon, somas at nodes, travelling spikes
    float axon = exp(-dline * 55.0);
    vec2 sc = floor(wp * 2.2), sf = fract(wp * 2.2) - 0.5;
    float soma = exp(-length(sf + 0.2 * (hash22(sc) - 0.5)) * 14.0) * step(0.55, hash21(sc));
    float spike = pow(max(0.0, sin((wp.x + wp.y) * 9.0 - t * 5.0)), 10.0);
    vec3 neuron = vec3(0.15, 0.45, 1.0) * (axon * (0.4 + 2.0 * spike) + soma * 0.9) + vec3(0.9, 1.0, 1.0) * axon * spike * 1.5;

    // lightning: jagged bolts, flicker
    vec2 jp = wp + 0.25 * vec2(fbm(wp * 8.0 + t * 2.0), fbm(wp * 8.0 + 4.0 - t * 2.0));
    float bolt = pow(ridge(jp * 1.4), 18.0);
    float flick = 0.5 + 0.5 * sin(t * 23.0 + floor(t * 7.0) * 3.0);
    vec3 lightning = vec3(0.7, 0.85, 1.0) * bolt * (1.2 + 2.0 * flick) + vec3(0.2, 0.3, 0.9) * exp(-dline * 20.0) * 0.4;

    vec3 col = canyon * wc + vessel * wv + neuron * wn + lightning * wl;
    // at the far zoom-out the lightning is confined to the cathedral's silhouette (so it reads as travelling through the building)
    float far = smoothstep(3.3, 4.0, st);
    fragColor = vec4(col * amt * mix(1.0, 1.0 - far * 0.0, far), amt * (1.0 - far));
}
