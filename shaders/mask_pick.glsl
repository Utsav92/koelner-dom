//#INCLUDE common.glsl
// ARCH_MASKS: pick one architectural mask from the twin. uMode.x: 0 TOWER_LEFT 1 TOWER_RIGHT 2 CENTER 3 WINDOWS 4 PORTALS 5 COLUMNS 6 STATUES 7 ORNAMENTS 8 ROOF
uniform vec4 uMode;
out vec4 fragColor;
void main(){
    vec2 uv = vUV.st;
    vec4 a = TA(uv), b = TB(uv), c = TC(uv);
    int k = int(uMode.x + 0.5);
    float m = k == 0 ? b.x : k == 1 ? b.y : k == 2 ? b.z : k == 3 ? a.y : k == 4 ? c.x : k == 5 ? c.y : k == 6 ? c.z : k == 7 ? c.w : b.w;
    fragColor = vec4(vec3(m), 1.0);
}
