//#INCLUDE common.glsl
// LIVING SKIN: turns the reaction-diffusion field into tissue, with a different "species" per architectural region.
// inputs: 0 ustate, 1 twinA, 2 twinB, 3 twinC, 4 rd_out.   rgb = skin colour, a = skin coverage.
out vec4 fragColor;

void main(){
    vec2 uv = vUV.st;
    float amt = uD.x;
    vec2 w = wuv(uv);
    float gap = G_GAP;
    vec4 a = TA(w), b = TB(w), c = TC(w);
    vec2 rd = texture(sTD2DInputs[4], w).rg;
    float V = rd.g, Uu = rd.r;
    float tissue = smoothstep(0.08, 0.35, V);
    float rim = smoothstep(0.05, 0.2, V) - smoothstep(0.2, 0.4, V);

    vec3 coral   = mix(vec3(0.55, 0.12, 0.10), vec3(1.00, 0.55, 0.35), V * 2.0);          // towers: coral
    vec3 lichen  = mix(vec3(0.20, 0.30, 0.08), vec3(0.75, 0.85, 0.30), V * 2.0);          // portals: lichen
    vec3 cells   = mix(vec3(0.05, 0.25, 0.35), vec3(0.45, 0.95, 0.95), V * 2.0);          // windows: cell membranes
    vec3 fungus  = mix(vec3(0.55, 0.50, 0.42), vec3(0.98, 0.96, 0.88), V * 2.0);          // columns: fungal colonies
    vec3 pigment = mix(vec3(0.10, 0.06, 0.03), vec3(0.85, 0.50, 0.20), step(0.22, V));    // nave: animal pigmentation
    vec3 tower = b.x + b.y > 0.5 ? coral : pigment;
    vec3 col = tower;
    col = mix(col, lichen, c.x);
    col = mix(col, cells, a.y);
    col = mix(col, fungus, c.y);
    col = mix(col, coral * 1.2, c.w * 0.6);
    // wet sheen along the fronts + slow subsurface breathing
    col += vec3(1.0, 0.8, 0.7) * rim * 0.5;
    col *= 0.75 + 0.25 * sin(uA.x * 0.8 + V * 14.0) + uA.w * 0.4;
    float cover = tissue * amt * a.w * (1.0 - gap);
    fragColor = vec4(col * cover * 0.9, cover);
}
