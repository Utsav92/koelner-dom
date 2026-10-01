// Particle target shapes: the DNA double helix between the towers and the giant human built on the cathedral's proportions.
// World space: x in [-AR/2, AR/2], y in [-0.5, 0.5], z toward the viewer.  Requires common.glsl (R, TAU).

vec3 flow3(vec3 p, float t){
    return vec3(sin(p.y * 3.1 + t * 0.7) + sin(p.z * 2.3 - t * 0.5),
                sin(p.z * 2.9 + t * 0.6) + sin(p.x * 3.3 + t * 0.4),
                sin(p.x * 2.7 - t * 0.5) + sin(p.y * 2.1 + t * 0.3));
}

// two strands + rungs
vec3 dnaTarget(uint id, float t){
    float s = R(id, 61u);
    float strand = R(id, 62u) < 0.5 ? 0.0 : 1.0;
    float th = s * TAU * 5.5 + t * 0.55 + strand * 3.14159;
    float rad = 0.15;
    float y = -0.42 + s * 0.88;
    vec3 a = vec3(rad * cos(th), y, rad * sin(th));
    if (R(id, 63u) < 0.16) {                                   // base-pair rung
        float th2 = th + 3.14159;
        vec3 b = vec3(rad * cos(th2), y, rad * sin(th2));
        return mix(a, b, R(id, 64u));
    }
    return a + (vec3(R(id, 65u), R(id, 66u), R(id, 67u)) - 0.5) * 0.012;
}

// human: head, neck, torso, raised arms (the towers' vertical extensions), short legs
const vec4 SEGA[9] = vec4[9](vec4(0.0, 0.0, 0.0, 0.075), vec4(0.0, -0.05, 0.0, 0.03), vec4(0.0, -0.10, 0.0, 0.115),
                             vec4(-0.115, -0.12, 0.0, 0.035), vec4(-0.176, 0.06, 0.0, 0.033), vec4(0.115, -0.12, 0.0, 0.035),
                             vec4(0.176, 0.06, 0.0, 0.033), vec4(-0.05, -0.36, 0.0, 0.045), vec4(0.05, -0.36, 0.0, 0.045));
const vec3 SEGB[9] = vec3[9](vec3(0.0, 0.04, 0.0), vec3(0.0, -0.10, 0.0), vec3(0.0, -0.36, 0.0),
                             vec3(-0.176, 0.06, 0.0), vec3(-0.176, 0.46, 0.0), vec3(0.176, 0.06, 0.0),
                             vec3(0.176, 0.46, 0.0), vec3(-0.06, -0.50, 0.0), vec3(0.06, -0.50, 0.0));
const float SEGW[9] = float[9](0.14, 0.17, 0.44, 0.54, 0.67, 0.77, 0.90, 0.95, 1.0);   // cumulative

// returns position; cls = 0 bone, 1 vessel, 2 nerve, 3 skin
vec3 humanTarget(uint id, out float cls){
    float hv = R(id, 40u);
    cls = hv < 0.28 ? 0.0 : (hv < 0.50 ? 1.0 : (hv < 0.68 ? 2.0 : 3.0));
    float sw = R(id, 41u);
    int k = 0;
    for (int i = 0; i < 9; i++) { if (sw >= SEGW[i]) k = i + 1; }
    k = min(k, 8);
    vec3 a = vec3(SEGA[k].xy, 0.0), b = SEGB[k];
    float r = SEGA[k].w;
    float u = R(id, 42u);
    vec3 axis = mix(a, b, u);
    float ang = R(id, 43u) * 6.2831853;
    float rr;
    if (cls < 0.5) rr = 0.0;                                   // bone: along the axis
    else if (cls < 1.5) rr = r * 0.45;                         // vessels: inside
    else if (cls < 2.5) rr = r * 0.75;                         // nerves
    else rr = r;                                               // skin shell
    vec3 off = vec3(cos(ang) * rr, 0.0, sin(ang) * rr * 0.7);
    if (k == 2 && cls < 0.5 && R(id, 44u) < 0.5) {             // ribs on the chest
        float t = (R(id, 45u) - 0.5) * 2.0;
        float y = mix(-0.14, -0.30, R(id, 46u));
        axis = vec3(0.0, y, 0.0);
        off = vec3(sin(t * 1.3) * 0.105, 0.0, cos(t * 1.3) * 0.075 * sign(t + 1e-4));
    }
    if (k == 0) {                                              // the head is a sphere (centre = the central rose window, the mind)
        vec3 d = normalize(vec3(R(id, 47u) - 0.5, R(id, 51u) - 0.5, R(id, 52u) - 0.5) + vec3(1e-4));
        float rad2 = cls < 0.5 ? 0.0 : (cls < 1.5 ? r * 0.5 : (cls < 2.5 ? r * 0.8 : r));
        axis = vec3(0.0, 0.02, 0.0);
        off = d * rad2;
    }
    return axis + off + (vec3(R(id, 48u), R(id, 49u), R(id, 50u)) - 0.5) * 0.004;
}
