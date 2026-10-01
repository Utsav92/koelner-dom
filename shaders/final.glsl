#define NO_TWIN
//#INCLUDE common.glsl
// FINAL OUTPUT: pre + volumetrics, tone map, black fade.  inputs: 0 ustate, 1 pre, 2 volum.
out vec4 fragColor;

void main(){
    vec2 uv = vUV.st;
    vec3 col = texture(sTD2DInputs[1], uv).rgb + texture(sTD2DInputs[2], uv).rgb;
    col = col / (1.0 + col * 0.22) * 1.12;                              // soft shoulder so projected highlights don't clip hard
    col *= 1.0 - uQ.x;                                                  // BLACK
    fragColor = vec4(col, 1.0);
}
