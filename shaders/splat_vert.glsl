//#INCLUDE common.glsl
//#INCLUDE pshapes.glsl
// GAUSSIAN SPLAT vertex shader: one billboard per particle, instanced from the position texture.
// Colour = the stone it came from (so the swap from solid twin to splats is invisible); during DNA / human phases the splats take the
// colour of their role (strands, bone, vessel, nerve, skin) and return to stone as the figure turns into the cathedral.
uniform sampler2D uPos;
uniform sampler2D uHomeA;
uniform sampler2D uHomeB;
uniform sampler2D uStone;
uniform vec4 uSP;       // x point radius (px), y gain, z, w
uniform vec4 uView;     // viewport px
out vec4 vCol;
out vec2 vUV;

void main(){
    ivec2 sz = textureSize(uPos, 0);
    ivec2 px = ivec2(gl_InstanceID % sz.x, gl_InstanceID / sz.x);
    uint id = uint(gl_InstanceID);
    vec3 pos = texelFetch(uPos, px, 0).xyz;
    vec4 hA = texelFetch(uHomeA, px, 0);
    vec4 hB = texelFetch(uHomeB, px, 0);
    float vis = uO.z * (1.0 - uQ.x);
    float t = uA.x;

    vec2 huv = vec2((hA.x + AR * 0.5) / AR, hA.y + 0.5);
    vec3 stone = texture(uStone, huv).rgb * 1.7 + vec3(0.02);
    vec3 col = stone;

    // DNA colouring
    float strand = R(id, 62u) < 0.5 ? 0.0 : 1.0;
    float rung = R(id, 63u) < 0.16 ? 1.0 : 0.0;
    vec3 dnaC = rung > 0.5 ? mix(vec3(0.3, 1.0, 0.4), vec3(1.0, 0.85, 0.2), R(id, 64u)) : (strand < 0.5 ? vec3(1.0, 0.35, 0.22) : vec3(0.25, 0.6, 1.0));
    col = mix(col, dnaC * 1.1, uK.x);

    // human colouring (role by class); roles appear one stage at a time
    float hcls;
    vec3 ht = humanTarget(id, hcls);
    vec3 roleC = hcls < 0.5 ? vec3(0.95, 0.9, 0.78) : (hcls < 1.5 ? vec3(1.0, 0.22, 0.15) : (hcls < 2.5 ? vec3(0.4, 0.8, 1.0) : vec3(0.95, 0.65, 0.5)));
    float roleVis = hcls < 0.5 ? smoothstep(-0.1, 0.6, uK.z) : (hcls < 1.5 ? smoothstep(0.8, 1.6, uK.z) : (hcls < 2.5 ? smoothstep(1.8, 2.6, uK.z) : smoothstep(2.8, 3.6, uK.z)));
    float dim = 1.0;
    if (uK.y > 0.001) {
        dim = mix(0.12, 1.0, roleVis);                                  // particles waiting for their role stay faint
        col = mix(col, roleC * (hcls > 2.5 ? 0.8 : 1.3) * (0.7 + 0.5 * sin(t * 2.0 + R(id, 70u) * 6.0 + pos.y * 8.0)), uK.y * (1.0 - uO.w));
        col *= mix(1.0, dim, uK.y);
    }
    // human -> stone: the same particles, now architecture
    col = mix(col, stone, uO.w * step(0.001, uO.w));

    float size = uSP.x * (0.75 + 0.7 * R(id, 98u));
    vec4 clip = TDWorldToProj(vec4(pos, 1.0));
    float rpx = clamp(size / max(clip.w, 0.2) * 1.6, 0.8, 7.0);
    vec2 corner = P.xy * 2.0;
    clip.xy += corner * rpx * (2.0 / uView.xy) * clip.w;
    gl_Position = vis < 0.003 ? vec4(2.0, 2.0, 2.0, 1.0) : clip;
    vUV = corner;
    vCol = vec4(col * uSP.y * vis, 1.0);
}
