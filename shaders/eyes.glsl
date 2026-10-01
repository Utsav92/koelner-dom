//#INCLUDE common.glsl
// WINDOWS BECOME EYES. The existing tracery is the anatomy: stone mullions -> iris spokes + rings, the round geometry -> pupil,
// ornamental arches -> eyelids. Stages (uD.w = eyeMorph): window -> iris-like geometry -> pupil -> living eye.
// Gaze follows the crowd (uE.yz), pupils dilate with crowd energy (uE.w), eyes close in silence and all open on impacts (uE.x).
// rgb = colour, a = coverage (replaces the window glass).
out vec4 fragColor;

vec4 eye(vec2 s, vec2 c, vec2 hs, float idx, float morph, float openAmt, bool rose){
    vec2 d = s - c;
    float R2 = rose ? ROSER : 1.0;
    vec2 q = rose ? d / vec2(ROSER) : d / hs;
    if (abs(q.x) > 1.25 || abs(q.y) > 1.25) return vec4(0.0);
    float hi = hash11(idx * 7.7 + 1.3);
    float s1 = smoothstep(0.0, 0.35, morph), s2 = smoothstep(0.30, 0.60, morph), s3 = smoothstep(0.55, 0.90, morph);
    float t = uA.x;

    // blink: slow independent blinks every few seconds
    float period = 5.0 + 5.0 * hi;
    float bt = mod(t + hi * 20.0, period);
    float blink = 1.0 - exp(-pow(bt * 6.0, 2.0)) * 0.0;
    float bl = smoothstep(0.0, 0.12, bt) * (1.0 - smoothstep(0.12, 0.3, bt));
    float op = clamp(openAmt * (1.0 - 0.95 * bl * s3), 0.0, 1.0);

    // eyelid aperture: almond aligned with the window's long axis
    float prof = rose ? sqrt(max(0.0, 1.0 - q.y * q.y)) : pow(max(0.0, 1.0 - q.y * q.y), 0.8);
    float aperture = op * prof;
    float inside = 1.0 - smoothstep(aperture - 0.03, aperture + 0.01, abs(q.x));
    float lid = (1.0 - smoothstep(0.0, 0.07, abs(abs(q.x) - aperture))) * step(abs(q.y), 0.97);   // ornamental lid line

    // gaze
    vec2 target = toS(uE.yz);
    vec2 gdir = target - c;
    float gl = length(gdir);
    vec2 g = gl > 1e-4 ? gdir / gl : vec2(0.0, -1.0);
    g += (vec2(vnoise(vec2(t * 0.6, idx)), vnoise(vec2(t * 0.5, idx + 9.0))) - 0.5) * 0.4;        // saccades
    float reach = 0.22 * min(1.0, gl * 4.0 + 0.3);
    vec2 gaze = vec2(g.x * hs.x * 0.45, g.y * hs.y * 0.35) * reach * 4.0;
    if (rose) gaze = g * ROSER * 0.3 * reach * 4.0;
    vec2 pr = d - gaze;
    float irisR = (rose ? ROSER : hs.x) * 0.82;
    float rr = length(pr);
    float ang = atan(pr.y, pr.x);
    float iris = 1.0 - smoothstep(irisR - 0.002, irisR, rr);
    float pupilR = irisR * (0.22 + 0.55 * uE.w);
    float pupil = 1.0 - smoothstep(pupilR - 0.002, pupilR + 0.0015, rr);
    float spokes = pow(max(0.0, abs(sin(ang * 8.0 + 0.5 * sin(rr * 80.0))) ), 3.0);
    float rings = 0.5 + 0.5 * sin(rr * 420.0);
    float tracery = max(spokes * smoothstep(pupilR, irisR * 0.9, rr), (1.0 - smoothstep(0.0, 0.0018, abs(rr - irisR * 0.85))));

    // stage 1: the stone tracery lights up as iris geometry on the glass
    vec3 col = vec3(0.0);
    float cov = 0.0;
    vec3 stoneLine = vec3(1.0, 0.7, 0.35);
    col += stoneLine * tracery * iris * s1 * 0.55;
    cov = max(cov, tracery * iris * s1 * 0.8);
    // stage 2: pupil forms in the round geometry
    col = mix(col, vec3(0.0), pupil * s2);
    cov = max(cov, pupil * s2 * iris);
    // stage 3: the living eye: sclera, iris colour, wet highlight
    float inEye = inside * s3;
    vec3 sclera = vec3(0.92, 0.78, 0.66) - vec3(0.0, 0.25, 0.25) * pow(max(0.0, sin(ang * 14.0 + rr * 90.0)), 4.0) * (1.0 - iris);
    vec3 irisC = mix(vec3(0.95, 0.55, 0.12), vec3(0.2, 0.75, 0.55), smoothstep(0.35, 1.0, rr / irisR)) * (0.55 + 0.7 * spokes) * (0.7 + 0.3 * rings);
    vec3 eyeC = mix(sclera * 0.55, irisC, iris);
    eyeC = mix(eyeC, vec3(0.0), pupil);
    eyeC += vec3(1.0) * exp(-length(pr - vec2(irisR * 0.3, irisR * 0.3)) * 400.0) * 0.8 * iris;     // specular
    eyeC *= 0.45 + 0.8 * op;
    col = mix(col, eyeC, inEye);
    cov = max(cov, inEye);
    // closed / sleeping eye: only the lid seam glows
    float seam = (1.0 - smoothstep(0.0, 0.05, abs(q.x))) * step(abs(q.y), 0.92) * (1.0 - op) * s3 * 0.6;
    col += vec3(1.0, 0.55, 0.2) * seam;
    cov = max(cov, seam * 0.7);
    // eyelid ornament ring
    col += vec3(1.0, 0.8, 0.55) * lid * s3 * op * 0.5;
    // light emerging from the pupil
    col += vec3(1.0, 0.8, 0.6) * exp(-rr * (rose ? 25.0 : 70.0)) * s3 * op * uH.x * 0.35;
    return vec4(col, clamp(cov, 0.0, 1.0));
}

void main(){
    vec2 uv = vUV.st;
    vec2 w = wuv(uv);
    float gap = G_GAP;
    vec2 s = toS(w);
    float morph = uD.w;
    float openA = uE.x;
    vec4 a = TA(w);
    vec3 col = vec3(0.0);
    float cov = 0.0;

    // anomaly: one window blinks (glass flashes pale) in the opening minute
    float blinkW = uN.x;
    if (blinkW > 0.001) {
        vec4 w5 = WN[5];
        float m5 = aa(archSD(s, w5.x, w5.y, w5.z, w5.w));
        col += vec3(0.75, 0.85, 1.0) * m5 * blinkW * 0.55;
        cov = max(cov, m5 * blinkW * 0.6);
    }
    // final sequence: another window looks toward the audience
    float look = uQ.z;

    if (morph > 0.003 || look > 0.003) {
        for (int i = 0; i < NW; i++) {
            float m = morph;
            float o = openA;
            if (i == 7) { m = max(m, look > 0.003 ? 0.95 : 0.0); o = max(o * step(0.003, morph), look * 0.55); }
            else if (morph <= 0.003) continue;
            if (m < 0.003) continue;
            vec4 e = eye(s, winCenter(i), winHalf(i), float(i), m, o, false);
            col += e.rgb;
            cov = max(cov, e.a);
        }
        if (morph > 0.003) {
            vec4 e = eye(s, ROSE, vec2(ROSER), 20.0, morph, openA, true);
            col += e.rgb;
            cov = max(cov, e.a);
        }
    }
    float vis = a.w * (1.0 - gap);
    fragColor = vec4(col * vis, cov * vis);
}
