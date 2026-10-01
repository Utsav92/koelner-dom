//#INCLUDE common.glsl
// AUDIENCE PARTICLES: the (enlarged, abstract) silhouettes dissolve into particles, which rise through the pillars into the arteries and
// circulate in the cathedral's vascular system. Stateless: position is a closed-form function of the particle id, the silhouette
// snapshot and the time since release (uR.x). Instanced from a 128x128 grid.
uniform sampler2D uLive;
uniform sampler2D uSnap;
uniform vec4 uView;
out vec4 vCol;
out vec2 vUV;

const float XS[14] = float[14](0.038, 0.070, 0.105, 0.140, 0.172, 0.1805, 0.2477, 0.3149, 0.382, AR - 0.172, AR - 0.140, AR - 0.105, AR - 0.070, AR - 0.038);

void main(){
    uint id = uint(gl_InstanceID);
    float stage = uK.w;
    float tr = uR.x;
    bool off = stage < 0.02;
    // silhouette sample (rejection sampling of the mask)
    vec2 m = vec2(0.5);
    bool ok = false;
    for (int k = 0; k < 14; k++) {
        vec2 c = vec2(R(id, uint(2 * k)), 0.30 + 0.6 * R(id, uint(2 * k + 1)));
        float v = tr > 0.0 ? texture(uSnap, c).r : texture(uLive, c).r;
        if (v > 0.5) { m = c; ok = true; break; }
    }
    if (!ok) off = true;
    vec3 sil = vec3((m.x - 0.5) * AR, (m.y - 0.30) / 1.1 - 0.5, 0.06);
    float rel = tr;                                                       // seconds since release
    float t0 = R(id, 5u) * 9.0;
    float u = clamp((rel - t0) / 6.0, 0.0, 1.0);
    int ci = int(floor(R(id, 6u) * 14.0)) % 14;
    float colx = XS[ci] - AR * 0.5 + (R(id, 8u) - 0.5) * 0.006;
    float dir = (mod(floor((XS[ci]) * 70.0), 2.0) < 1.0) ? 1.0 : -1.0;
    float speed = 0.045 * (1.0 + uR.w) * (0.6 + R(id, 9u));
    float yc = fract((sil.y + 0.5) + dir * max(rel - t0 - 6.0, 0.0) * speed) - 0.5;
    vec3 flowP = vec3(colx + 0.004 * sin(yc * 40.0 + float(id % 9u)), yc, 0.05);
    vec3 pos = mix(sil + (vec3(R(id, 15u), R(id, 16u), 0.0) - 0.5) * 0.006, flowP, smoothstep(0.0, 1.0, u));
    pos.z += (1.0 - u) * 0.0 + 0.02 * sin(uA.x + float(id % 13u));
    if (rel <= 0.0) pos = sil + (vec3(R(id, 15u), R(id, 16u), 0.0) - 0.5) * 0.004;

    float up = dir > 0.0 ? 1.0 : 0.0;
    vec3 warm = vec3(1.0, 0.92, 0.8);
    vec3 art = mix(vec3(0.25, 0.1, 0.55), vec3(1.0, 0.35, 0.15), up);
    vec3 col = mix(warm, art, smoothstep(0.0, 1.0, u)) * (0.5 + 0.9 * pow(max(0.0, sin(yc * 30.0 - uA.x * 3.0 * dir)), 4.0) * u);
    float fadeIn = smoothstep(0.05, 0.3, stage) * (1.0 - uQ.x) * (1.0 - uO.z);      // splat phase takes over the whole building
    vec4 clip = TDWorldToProj(vec4(pos, 1.0));
    float rpx = 1.8 + 1.2 * R(id, 98u);
    vec2 corner = P.xy * 2.0;
    clip.xy += corner * rpx * (2.0 / uView.xy) * clip.w;
    gl_Position = (off || fadeIn < 0.003) ? vec4(2.0, 2.0, 2.0, 1.0) : clip;
    vUV = corner;
    vCol = vec4(col * fadeIn * 0.7, 1.0);
}
