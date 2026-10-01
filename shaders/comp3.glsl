#define NO_TWIN
//#INCLUDE common.glsl
// PRE-OUTPUT BLEND: facade <-> Gaussian-splat render, the flight into the portal, and the infinite recursion (the Dom inside its
// own central portal).  inputs: 0 ustate, 1 comp2, 2 enter, 3 splat render.
out vec4 fragColor;

vec3 fac(vec2 uv){ return texture(sTD2DInputs[1], uv).rgb; }

void main(){
    vec2 uv = vUV.st;
    // crowd-driven destabilisation: the picture trembles
    float ds = uM.w;
    vec2 j = (vec2(vnoise(uv * 40.0 + uA.x * 9.0), vnoise(uv * 40.0 + 7.0 - uA.x * 9.0)) - 0.5) * ds * 0.006;
    vec2 u = uv + j;

    vec3 col = fac(u);
    // recursion: the facade inside the central portal, nested
    float rec = uL.w;
    if (rec > 0.002) {
        vec2 uu = u;
        float amtf = 1.0;
        for (int i = 0; i < 3; i++) {
            vec2 s = toS(uu);
            if (archSD(s, CXM, 0.0, 0.055, 0.13) <= 0.0) break;
            uu = vec2(0.5, 0.5) + (uu - vec2(0.5, 0.115)) / 0.2;
            amtf *= 0.9;
            col = mix(col, fac(uu), rec * amtf);
        }
    }
    // Gaussian splats replace the facade as splatVis rises (crossfade is invisible because splat colour = stone colour)
    float sv = uO.z;
    vec4 sp = texture(sTD2DInputs[3], uv);
    col = col * (1.0 - sv) + sp.rgb;
    // enter-the-cathedral flight
    vec4 en = texture(sTD2DInputs[2], uv);
    col = mix(col, en.rgb, clamp(uR.y, 0.0, 1.0));
    fragColor = vec4(col, 1.0);
}
