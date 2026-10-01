// NORMAL MAP of the digital twin, derived from twinA's height. input 0 = twinA.
out vec4 fragColor;
void main(){
    ivec2 p = ivec2(gl_FragCoord.xy);
    float hx = texelFetch(sTD2DInputs[0], p + ivec2(1, 0), 0).x - texelFetch(sTD2DInputs[0], p - ivec2(1, 0), 0).x;
    float hy = texelFetch(sTD2DInputs[0], p + ivec2(0, 1), 0).x - texelFetch(sTD2DInputs[0], p - ivec2(0, 1), 0).x;
    vec3 n = normalize(vec3(-hx * 12.0, -hy * 12.0, 1.0));
    fragColor = vec4(n * 0.5 + 0.5, texelFetch(sTD2DInputs[0], p, 0).w);
}
