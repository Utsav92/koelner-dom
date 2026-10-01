#define NO_TWIN
//#INCLUDE common.glsl
// VOLUMETRIC LIGHT: radial light shafts. Sources: the eyes (pupils / rose window), the heart, and - during the Gaussian collapse -
// the whole building, so the beams reveal particle depth. During reconstruction the shafts converge on the building: light that
// appears to pull the particles back.   inputs: 0 ustate, 1 pre (blended picture).
out vec4 fragColor;

vec3 shafts(vec2 uv, vec2 src, float dens, float pull){
    vec3 acc = vec3(0.0);
    float decay = 1.0;
    vec2 d = (src - uv) * dens / 24.0;
    vec2 p = uv;
    for (int i = 0; i < 24; i++) {
        p += d;
        vec3 c = texture(sTD2DInputs[1], p).rgb;
        float l = max(max(c.r, c.g), c.b);
        acc += c * smoothstep(0.6, 1.6, l) * decay;
        decay *= 0.94;
    }
    return acc / 24.0;
}

void main(){
    vec2 uv = vUV.st;
    float inten = uH.x;
    if (inten < 0.002) { fragColor = vec4(0.0, 0.0, 0.0, 1.0); return; }
    float eyes = uE.x * uD.w;
    float heart = uC.z;
    float splat = uO.z * smoothstep(0.02, 0.4, uF.w + uF.y + uF.z);
    float recon = uO.y;
    vec3 col = vec3(0.0);
    if (eyes > 0.01) col += shafts(uv, vec2(0.5, 0.485), 0.85, 0.0) * eyes * vec3(1.0, 0.85, 0.65) * 1.3;
    if (heart > 0.01) col += shafts(uv, vec2(0.5, 0.17), 0.75, 0.0) * heart * vec3(1.0, 0.35, 0.2) * 0.3;
    if (splat > 0.01) col += shafts(uv, vec2(0.5, 0.52), 0.9, 0.0) * splat * vec3(0.7, 0.8, 1.0) * 0.45;
    if (recon > 0.01 && recon < 1.0) col += shafts(uv, vec2(0.5, 0.45), -0.7, 1.0) * sin(recon * PI) * vec3(1.0, 0.9, 0.75) * 1.0;
    fragColor = vec4(col * inten, 1.0);
}
