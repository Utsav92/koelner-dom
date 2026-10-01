//#INCLUDE common.glsl
// FACADE COMPOSITE (stage 1): stone + cracks + machine interior + skeleton + roots + living skin + heart + arteries.
// inputs: 0 ustate, 1-3 twins, 4 stone, 5 crack, 6 machine, 7 bones, 8 vessels, 9 heart, 10 roots, 11 skin.   rgb = light, a = facade solid.
out vec4 fragColor;

void main(){
    vec2 uv = vUV.st;
    vec4 st = texture(sTD2DInputs[4], uv);
    vec4 cr = texture(sTD2DInputs[5], uv);
    vec4 mc = texture(sTD2DInputs[6], uv);
    vec4 bn = texture(sTD2DInputs[7], uv);
    vec4 vs = texture(sTD2DInputs[8], uv);
    vec4 ht = texture(sTD2DInputs[9], uv);
    vec4 rt = texture(sTD2DInputs[10], uv);
    vec4 sk = texture(sTD2DInputs[11], uv);
    float solid = TA(uv).w;

    vec3 col = st.rgb;
    col = mix(col, mc.rgb, mc.a);                           // the opened interior replaces the slid-away stone
    col = mix(col, sk.rgb * (1.0 - 0.5 * uD.y), sk.a * (0.75 - 0.4 * uD.y));                    // living skin
    col = mix(col, bn.rgb, bn.a);                           // stone gives way to bone along the structural members
    col = mix(col, rt.rgb, rt.a);                           // roots (which are the building)
    col = col * (1.0 - cr.a * 0.85) + cr.rgb;               // cracks: dark core + the glow beneath
    col = mix(col, ht.rgb, ht.a);                           // the heart, inside the opening
    col += vs.rgb;                                          // arteries are emissive
    fragColor = vec4(col, max(solid, mc.a));
}
