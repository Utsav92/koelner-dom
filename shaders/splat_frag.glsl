// Gaussian splat: soft round falloff on an instanced billboard, additively blended.
in vec4 vCol;
in vec2 vUV;
out vec4 fragColor;
void main(){
    float r2 = dot(vUV, vUV);
    if (r2 > 1.0) discard;
    float g = exp(-r2 * 2.6);
    fragColor = vec4(vCol.rgb * g, 1.0);
}
