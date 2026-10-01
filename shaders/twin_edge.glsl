// Edge pass: reads the raw twinA (input 0: height, windows, -, solid) and writes the relief edge into .b
out vec4 fragColor;
void main(){
    ivec2 p = ivec2(gl_FragCoord.xy);
    vec4 c = texelFetch(sTD2DInputs[0], p, 0);
    float hx = texelFetch(sTD2DInputs[0], p + ivec2(2, 0), 0).x - texelFetch(sTD2DInputs[0], p - ivec2(2, 0), 0).x;
    float hy = texelFetch(sTD2DInputs[0], p + ivec2(0, 2), 0).x - texelFetch(sTD2DInputs[0], p - ivec2(0, 2), 0).x;
    fragColor = vec4(c.x, c.y, clamp(length(vec2(hx, hy)) * 5.0, 0.0, 1.0), c.w);
}
