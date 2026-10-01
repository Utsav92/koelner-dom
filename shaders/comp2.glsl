//#INCLUDE common.glsl
// FACADE COMPOSITE (stage 2): + neurons, eyes (replace the window glass), audience shadows, scale illusion.
// inputs: 0 ustate, 1 comp1, 2 neurons, 3 eyes, 4 sil, 5 scale.
out vec4 fragColor;

void main(){
    vec2 uv = vUV.st;
    vec4 base = texture(sTD2DInputs[1], uv);
    vec4 nr = texture(sTD2DInputs[2], uv);
    vec4 ey = texture(sTD2DInputs[3], uv);
    vec4 sl = texture(sTD2DInputs[4], uv);
    vec4 sc = texture(sTD2DInputs[5], uv);
    vec3 col = base.rgb + nr.rgb;
    col = mix(col, ey.rgb, ey.a);
    col += sl.rgb;
    col = mix(col, sc.rgb, clamp(sc.a, 0.0, 1.0));
    fragColor = vec4(col, 1.0);
}
