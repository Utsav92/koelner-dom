//#INCLUDE common.glsl
// AUDIENCE SHADOWS: crowd silhouettes (no identification - binary mask only) enlarged as abstract shadows on the lower facade,
// then they erode into particles (see PARTICLE_SIM/aud_vert.glsl). inputs: 0 ustate, 1-3 twins, 4 crowd_live, 5 crowd_snap.
out vec4 fragColor;

float samp(vec2 m, bool snap){
    return snap ? texture(sTD2DInputs[5], m).r : texture(sTD2DInputs[4], m).r;
}

void main(){
    vec2 uv = vUV.st;
    float stage = uK.w;
    if (stage < 0.01 || uR.x > 40.0) { fragColor = vec4(0.0); return; }
    vec2 w = wuv(uv);
    float gap = G_GAP;
    vec4 a = TA(w);
    bool snap = uR.x > 0.0;
    // facade lower 55% <- crowd image rows 0.30 .. 0.90, mirrored to read as shadows cast on the stone
    vec2 mc = vec2(w.x, 0.30 + w.y * 1.1);
    float v = 0.0;
    for (int i = 0; i < 9; i++) {                                   // soft abstract blur
        vec2 o = vec2(float(i % 3 - 1), float(i / 3 - 1)) * 0.012;
        v += samp(mc + o, snap);
    }
    v /= 9.0;
    float body = smoothstep(0.35, 0.65, v);
    float edge = smoothstep(0.1, 0.5, v) * (1.0 - smoothstep(0.5, 0.9, v));
    // erosion into particles as the stage rises
    float n = fbm(w * vec2(30.0, 50.0) + uA.x * 0.3);
    float erode = smoothstep(0.30, 1.0, stage);
    body *= 1.0 - smoothstep(erode - 0.1, erode + 0.1, n) * erode;
    float vis = smoothstep(0.01, 0.25, stage) * (1.0 - smoothstep(0.85, 1.0, stage));
    vec3 col = vec3(0.45, 0.70, 1.0) * (body * 0.18 + edge * 0.6);
    float m = step(w.y, 0.6) * a.w * (1.0 - gap);
    fragColor = vec4(col * vis * m, body * vis * m);
}
