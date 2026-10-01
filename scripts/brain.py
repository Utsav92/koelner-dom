"""
KOELNER DOM brain - runs once per frame (tick()) from the frame Execute DAT in /SHOW_CONTROL.
Owns: the 15-minute timeline, the 17 master parameters (AUTO writes them, MANUAL reads them), cue jumps, heartbeat + audio features
(synthetic or live), crowd vision (demo crowd or camera frame-difference), eye target, anomalies, and the packed uniform texture.
"""
import math
import numpy as np

ROOT = '__ROOT__'
SHOW_LEN = 900.0

# ============================================================================ timeline (seconds). Edit freely.
K = {
    # --- ACT I: awakening
    'stone':      [(0, 0.0), (6, 0.10), (60, 0.55), (100, 0.80), (876, 0.80), (900, 0.80)],
    'breath':     [(0, 0), (92, 0), (100, .5), (125, .8), (300, .8), (420, 1), (595, 1), (650, .6), (700, .3), (726, 0), (878, 0), (880, .0), (896, .12), (900, 0)],
    'bwC':        [(0, 0), (94, 0), (100, 1), (900, 1)],
    'bwT':        [(0, 0), (112, 0), (125, 1), (900, 1)],
    'bwCol':      [(0, 0), (130, 0), (140, 1), (900, 1)],
    'bwWin':      [(0, 0), (145, 0), (155, 1), (900, 1)],
    'eyeMorph':   [(0, 0), (125, 0), (150, .4), (170, .75), (190, 1), (650, 1), (700, 0), (900, 0)],
    'eyeOpen':    [(0, 0), (150, 0), (165, .2), (185, .7), (400, .8), (520, .9), (566, .9), (568, 0), (574, 0), (577, 1), (650, 1), (700, 0), (900, 0)],
    # --- ACT II: what lives under stone
    'crack':      [(0, 0), (176, 0), (235, .5), (300, .85), (400, 1), (595, 1), (652, .3), (690, 0), (900, 0)],
    'machine':    [(0, 0), (228, 0), (268, 1), (500, 1), (560, .3), (588, 0), (900, 0)],
    'machineSpd': [(0, 0), (228, 0), (260, 1), (290, 1), (325, .3), (345, .05), (900, 0)],
    'bone':       [(0, 0), (255, 0), (298, 1), (345, 1), (400, .8), (520, .4), (595, .2), (650, 0), (900, 0)],
    'bio':        [(0, 0), (280, 0), (310, .4), (345, .9), (400, 1), (650, 1), (700, 0), (900, 0)],
    'artery':     [(0, 0), (330, 0), (365, 1), (520, 1), (595, .9), (650, 0), (900, 0)],
    'heart':      [(0, 0), (362, 0), (395, 1), (595, 1), (650, 0), (900, 0)],
    # --- ACT III: growth
    'root':       [(0, 0), (402, 0), (460, 1), (525, 1), (595, .7), (650, 0), (900, 0)],
    'rootBio':    [(0, 0), (402, 0), (440, .25), (470, .55), (500, .8), (525, 1), (650, 1), (900, 1)],
    'rd':         [(0, 0), (428, 0), (450, .3), (500, 1), (595, 1), (650, 0), (900, 0)],
    'neural':     [(0, 0), (455, 0), (480, .5), (525, .9), (560, 1), (566, 1), (568, 0), (574, 0), (577, .6), (595, .8), (650, 0), (900, 0)],
    'sync':       [(0, 0), (500, 0), (560, 1), (566, 1), (568, .9), (574, .9), (577, .3), (595, .2), (650, 0), (900, 0)],
    'audience':   [(0, 0), (470, 0), (480, .25), (500, .3), (504, .7), (512, 1), (650, 1), (655, 0), (900, 0)],
    'crowdDemo':  [(0, .08), (100, .12), (200, .28), (300, .38), (400, .50), (450, .70), (500, .85), (525, .95), (560, .45), (590, .40),
                   (650, .55), (700, .75), (726, .95), (760, .12), (800, .25), (880, .10), (900, .05)],
    # --- ACT IV/V: consciousness, enter, death
    'enter':      [(0, 0), (590, 0), (594, 1), (646, 1), (651, 0), (900, 0)],
    'enterProg':  [(0, 0), (594, 0), (646, 1), (900, 1)],
    'recursion':  [(0, 0), (636, 0), (646, 1), (653, 0), (900, 0)],
    'scaleAmt':   [(0, 0), (196, 0), (200, 1), (212, 1), (217, 0), (500, 0), (504, 1), (530, 1), (535, 0), (900, 0)],
    'scaleStage': [(0, 0), (198, 0), (214, 1.1), (500, 0), (531, 4.0), (900, 4)],
    'splatVis':   [(0, 0), (648, 0), (666, 1), (845, 1), (846, 1), (878, 1), (884, 0), (900, 0)],
    'splat':      [(0, 0), (648, 0), (655, .03), (690, .35), (726, .7), (750, 1), (800, 1), (845, .6), (878, .0), (900, 0)],
    'towerL':     [(0, 0), (690, 0), (708, 1), (878, 1), (879, 0), (900, 0)],
    'towerR':     [(0, 0), (708, 0), (726, 1), (878, 1), (879, 0), (900, 0)],
    'stability':  [(0, 1), (726, 1), (750, 0), (878, 0), (879, 1), (900, 1)],
    'gravity':    [(0, 1), (690, 0), (726, 0), (735, -.6), (750, -.3), (752, 0), (900, 0)],
    'turb':       [(0, .2), (650, .3), (690, .6), (726, 1.2), (752, .4), (775, .25), (800, .35), (845, .22), (870, .12), (878, 0), (900, 0)],
    'returnStr':  [(0, .5), (655, .3), (690, .05), (726, .02), (775, 0), (845, .10), (852, .18), (862, .38), (872, .8), (878, 1.0), (900, 1.0)],
    'volum':      [(0, 0), (140, 0), (185, .4), (400, .5), (560, .6), (576, 1), (650, .7), (690, .7), (726, 1), (750, .8), (775, .6), (845, .8), (878, .2), (885, 0), (900, 0)],
    'audioReact': [(0, .6), (750, .2), (775, .3), (845, .7), (900, .5)],
    # --- ACT VI/VII: genesis, rebirth
    'dna':        [(0, 0), (770, 0), (790, 1), (808, 1), (814, 0), (900, 0)],
    'human':      [(0, 0), (808, 0), (814, 1), (836, 1), (846, 0), (900, 0)],
    'humanStage': [(0, 0), (808, 0), (812, 0.99), (816, 1.99), (820, 2.99), (826, 3.99), (900, 4)],
    'humanStone': [(0, 0), (826, 0), (846, 1), (900, 1)],
    'recon':      [(0, 0), (845, 0), (878, 1), (900, 1)],
    'fade':       [(0, 0), (1, 0), (898.2, 0), (900, 1)],
    'bpm':        [(0, 40), (90, 42), (360, 48), (395, 60), (500, 70), (560, 90), (566, 90), (574, 70), (650, 80), (700, 110), (726, 140),
                   (750, 40), (775, 40), (845, 60), (880, 40), (896, 36), (900, 36)],
}
STINGERS = [(574.0, 1.0), (726.0, 0.9), (750.0, 0.5), (808.0, 0.7), (845.0, 0.8), (574.8, 0.6), (650.0, 0.6), (690, .5)]
SILENCE = [(566.0, 574.0), (752.0, 774.0), (880.5, 899.0)]           # music drops out here (synthetic audio)
HEART_OFF = [(568.0, 574.0), (752.0, 774.0)]                          # no heartbeat in the pause and in zero gravity
SECTIONS = [(0, 60, 'I   STONE'), (60, 95, 'I   ANOMALIES'), (95, 130, 'I   THE FIRST BREATH'), (130, 175, 'I   WINDOWS BECOME EYES'),
            (175, 228, 'II  STONE CRACKS'), (228, 275, 'II  THE CATHEDRAL OPENS'), (275, 330, 'II  COLUMNS BECOME BONES / MACHINE -> ANATOMY'),
            (330, 362, 'II  ARTERIES'), (362, 402, 'II  THE HEART'), (402, 430, 'III ROOT INVASION'), (430, 460, 'III REACTION-DIFFUSION SKIN'),
            (460, 525, 'III NEURAL CATHEDRAL / AUDIENCE'), (525, 568, 'IV  THE CATHEDRAL THINKS'), (568, 576, 'IV  ...'),
            (576, 595, 'IV  THE EYES OPEN'), (595, 650, 'ENTER THE CATHEDRAL'), (650, 690, 'V   GAUSSIAN SPLAT TRANSFORMATION'),
            (690, 726, 'V   THE TOWERS DISAPPEAR'), (726, 752, 'V   TOTAL COLLAPSE'), (752, 775, 'V   ZERO GRAVITY'),
            (775, 808, 'VI  PARTICLES FORM DNA'), (808, 826, 'VI  DNA -> HUMAN'), (826, 845, 'VI  HUMAN -> CATHEDRAL'),
            (845, 880, 'VII PERFECT RECONSTRUCTION'), (880, 900.1, 'VII FINAL')]
CUES = {'Stone': 0.0, 'Awaken': 95.0, 'Crack': 176.0, 'Machine': 228.0, 'Heart': 362.0, 'Roots': 402.0, 'Neural': 455.0,
        'Conscious': 566.0, 'Dissolve': 650.0, 'Dna': 775.0, 'Rebirth': 826.0, 'Reconstruct': 845.0, 'Sleep': 880.0, 'Enter': 594.0}
CUES_PAR = {k: k for k in CUES}
# master parameter  ->  timeline key
MASTERS = {'Breath': 'breath', 'Crackgrowth': 'crack', 'Machinereveal': 'machine', 'Biology': 'bio', 'Rootgrowth': 'root',
           'Neuralactivity': 'neural', 'Eyeopen': 'eyeOpen', 'Splatdissolve': 'splat', 'Gravity': 'gravity', 'Turbulence': 'turb',
           'Returnstrength': 'returnStr', 'Volumetricintensity': 'volum', 'Audioreactivity': 'audioReact', 'Structuralstability': 'stability',
           'Heartrate': 'bpm'}

PACK = [('time', 'showT', 'breath', 'beat'), ('stone', 'crack', 'machine', 'bio'), ('bone', 'artery', 'heart', 'root'),
        ('rd', 'neural', 'sync', 'eyeMorph'), ('eyeOpen', 'eyeX', 'eyeY', 'pupil'), ('crowd', 'towerL', 'towerR', 'splat'),
        ('stability', 'gravity', 'turb', 'returnStr'), ('volum', 'audioReact', 'kick', 'bpm'), ('sub', 'bass', 'mid', 'high'),
        ('transient', 'master', 'silence', 'split'), ('dna', 'human', 'humanStage', 'audience'), ('scaleAmt', 'scaleStage', 'enterProg', 'recursion'),
        ('crowdL', 'crowdC', 'crowdR', 'destab'), ('aBlink', 'aOrn', 'aShadow', 'aCol'), ('rootBio', 'recon', 'splatVis', 'humanStone'),
        ('bwC', 'bwT', 'bwCol', 'bwWin'), ('fade', 'gear', 'lastLook', 'stonePulse'), ('audT', 'enterAmt', 'crackPhase', 'vascBoost'),
        ('z0', 'z1', 'z2', 'z3'), ('z0', 'z1', 'z2', 'z3'), ('z0', 'z1', 'z2', 'z3'), ('z0', 'z1', 'z2', 'z3'), ('z0', 'z1', 'z2', 'z3'), ('z0', 'z1', 'z2', 'z3')]

CVW, CVH = 96, 54
S = {}                                    # published scalars
UST = np.zeros((1, 24, 4), np.float32)
TEX = {'live': np.zeros((CVH, CVW, 4), np.float32), 'snap': np.zeros((CVH, CVW, 4), np.float32)}
_g = {'t': 0.0, 'last': None, 'beat': 0.0, 'kick': 0.0, 'gear': 0.0, 'prev_mask': np.zeros((CVH, CVW), np.float32),
      'ce': 0.1, 'cx': .5, 'cy': .5, 'cl': 0., 'cc': 0., 'cr': 0., 'bg': None, 'snapped': False, 'sub': 0., 'mid': 0., 'high': 0.,
      'walkers': None, 'frames': 0, 'info_t': -9, 'quiet': 0.0, 'eyeX': .5, 'eyeY': .15, 'lastpar': {}, 'cue_pending': None}
_rng = np.random.default_rng(11)


def interp(key, t):
    k = K[key]
    if t <= k[0][0]:
        return float(k[0][1])
    for (t0, v0), (t1, v1) in zip(k[:-1], k[1:]):
        if t < t1:
            return float(v0) if t1 == t0 else float(v0 + (v1 - v0) * (t - t0) / (t1 - t0))
    return float(k[-1][1])


def sstep(a, b, x):
    x = min(1.0, max(0.0, (x - a) / (b - a)))
    return x * x * (3 - 2 * x)


def bump(t, a, b):
    """0 -> 1 -> 0 smooth bump over [a, b]"""
    if t <= a or t >= b:
        return 0.0
    return math.sin(math.pi * (t - a) / (b - a)) ** 2


def C(name, default=None):
    try:
        return op(ROOT + '/SHOW_CONTROL').par[name].eval()
    except Exception:
        return default


def inside(t, spans):
    return any(a <= t < b for a, b in spans)


# ============================================================================ audio features (synthetic or live)
def audio_features(t, dt, bpm):
    g = _g
    silent = inside(t, SILENCE)
    muted_heart = inside(t, HEART_OFF)
    g['beat'] = (g['beat'] + dt * bpm / 60.0) % 1.0
    p = g['beat']
    lub = math.exp(-p * 9.0)
    dub = 0.6 * math.exp(-max(0.0, p - 0.32) * 10.0) if p > 0.32 else 0.0
    kick = 0.0 if muted_heart else max(lub, dub)
    g['kick'] += (kick - g['kick']) * min(1.0, dt * 40.0)
    act = sstep(60, 140, t) * (1 - sstep(870, 885, t))
    sub = (0.5 + 0.5 * math.sin(t * 0.97)) * act * (0.3 + 0.7 * sstep(300, 420, t))
    mid = (0.45 + 0.35 * math.sin(t * 0.31) + 0.2 * math.sin(t * 1.7)) * sstep(170, 300, t) * (1 - 0.8 * sstep(752, 775, t) * (1 - sstep(840, 850, t)))
    high = max(0.0, math.sin(t * 7.3) * math.sin(t * 2.9)) * interp('neural', t) * 1.1
    trans = 0.0
    for ts, a in STINGERS:
        if t >= ts:
            trans = max(trans, a * math.exp(-(t - ts) * 2.2))
    trans = max(trans, g['kick'] * 0.55)
    bass = g['kick'] * 0.9 + 0.25 * sub
    if silent:
        sub = mid = high = bass = trans = 0.0
        g['kick'] = 0.0
    g['sub'] += (sub - g['sub']) * min(1.0, dt * 3)
    g['mid'] += (mid - g['mid']) * min(1.0, dt * 4)
    g['high'] += (high - g['high']) * min(1.0, dt * 12)
    master = min(1.0, 0.5 * g['sub'] + 0.8 * g['kick'] + 0.5 * g['mid'] + 0.4 * g['high'] + 0.5 * trans)
    return g['sub'], bass, g['mid'], g['high'], trans, master, silent


def read_live_audio():
    try:
        c = op(ROOT + '/AUDIO_ANALYSIS/features')
        return [float(c[n][0]) for n in ('sub', 'bass', 'mid', 'high', 'transient', 'master')]
    except Exception:
        return None


# ============================================================================ crowd vision (no face identification, only movement + silhouettes)
def demo_crowd(t, dt, energy):
    g = _g
    if g['walkers'] is None:
        g['walkers'] = [{'p': _rng.random(2) * [.8, .3] + [.1, .5], 'v': (_rng.random(2) - .5) * .2, 'h': .14 + .06 * _rng.random()} for _ in range(9)]
    mask = np.zeros((CVH, CVW), np.float32)
    yy, xx = np.mgrid[0:CVH, 0:CVW].astype(np.float32)
    u, v = xx / CVW, yy / CVH
    for w in g['walkers']:
        sp = 0.05 + 0.5 * energy
        w['v'] += (_rng.random(2) - .5) * sp * dt * 6 - w['v'] * dt * 0.8
        w['p'] += w['v'] * dt * (0.5 + 2.0 * energy)
        w['p'][0] = min(.95, max(.05, w['p'][0]))
        w['p'][1] = min(.80, max(.45, w['p'][1]))
        if w['p'][0] in (.05, .95):
            w['v'][0] *= -1
        cx, cy = w['p']
        sway = 0.02 * math.sin(t * (1 + 3 * energy) + cx * 9) * energy
        head = ((u - cx - sway) / 0.025) ** 2 + ((v - cy) / 0.04) ** 2 < 1
        body = (np.abs(u - cx - sway * .5) < 0.04) & (v < cy - 0.03) & (v > cy - w['h'])
        mask = np.maximum(mask, (head | body).astype(np.float32))
    return mask


def read_cv(t, dt):
    g = _g
    demo = bool(C('Demomode', 1))
    e_target = interp('crowdDemo', t)
    if demo:
        mask = demo_crowd(t, dt, e_target)
    else:
        try:
            arr = op(ROOT + '/CROWD_VISION/cv_small').numpyArray()
            gray = arr[..., :3].mean(axis=2).astype(np.float32)
            if bool(C('Mirror', 1)):
                gray = gray[:, ::-1]
            if g['bg'] is None or g['bg'].shape != gray.shape:
                g['bg'] = gray.copy()
            g['bg'] += (gray - g['bg']) * (0.5 if g['frames'] < 20 else float(C('Bglearn', 0.004)))
            mask = (np.abs(gray - g['bg']) > float(C('Segthreshold', 0.1))).astype(np.float32)
            mask = np.resize(mask, (CVH, CVW)) if mask.shape != (CVH, CVW) else mask
        except Exception:
            mask = g['prev_mask'] * 0.95
    prev = g['prev_mask']
    flow = np.abs(mask - prev)                                    # frame-difference "optical flow" magnitude
    g['prev_mask'] = mask
    tot = max(1.0, float(mask.sum()))
    mot = float(flow.sum()) / max(8.0, tot) if not demo else None
    if demo:
        energy = e_target
    else:
        energy = min(1.0, (mot or 0.0) * 3.0 * float(C('Crowdgain', 1.0)))
    g['ce'] += (energy - g['ce']) * min(1.0, dt * 2.0)
    third = CVW // 3
    dens = [float(flow[:, :third].sum()), float(flow[:, third:2 * third].sum()), float(flow[:, 2 * third:].sum())]
    sm = max(1.0, sum(dens))
    for k, v in zip(('cl', 'cc', 'cr'), dens):
        g[k] += (min(1.0, 3.0 * v / sm * g['ce'] * 2.0) - g[k]) * min(1.0, dt * 3.0)
    ys, xs = np.nonzero(mask > 0.5)
    if len(xs) > 4:
        cx, cy = float(xs.mean()) / CVW, float(ys.mean()) / CVH
        g['cx'] += (cx - g['cx']) * min(1.0, dt * 1.5)
        g['cy'] += (cy - g['cy']) * min(1.0, dt * 1.5)
    live = TEX['live']
    live[..., 0] = mask
    live[..., 1] = np.clip(flow * 2.0, 0, 1)
    live[..., 3] = 1.0


# ============================================================================ per-frame
def reset():
    _g['t'] = 0.0
    _g['snapped'] = False


QRES = {'low': (360, 640), 'medium': (540, 960), 'high': (720, 1280)}


def apply_quality(q):
    """Rescale every per-frame layer (listed in SHOW_CONTROL/layer_tops) to the chosen tier."""
    w, h = QRES.get(q, QRES['low'])
    tbl = op(ROOT + '/SHOW_CONTROL/layer_tops')
    for r in range(tbl.numRows):
        o = op(tbl[r, 0].val)
        if o is not None:
            o.par.outputresolution = 'custom'
            o.par.resolutionw = w
            o.par.resolutionh = h
    for mn, vi in (('m_splat', 1), ('m_aud', 0)):               # splat billboard size needs the viewport (constants: an expression would loop)
        m = op(ROOT + '/GAUSSIAN_SPLATS/' + mn)
        if m is not None:
            setattr(m.par, 'vec%dvaluex' % vi, w)
            setattr(m.par, 'vec%dvaluey' % vi, h)


def load_kantan():
    import glob
    for pth in glob.glob(r'C:\Program Files\Derivative\TouchDesigner\Samples\Palette\**\*antan*.tox', recursive=True):
        op(ROOT + '/PROJECTOR_CALIBRATION').loadTox(pth)
        return pth
    return None


def seek(t):
    _g['t'] = float(t)
    _g['snapped'] = False                                 # tick() re-captures the audience snapshot if t >= 500


def jump(name):
    if name in CUES:
        seek(CUES[name])


def tick():
    g = _g
    now = absTime.seconds
    dt = 1.0 / 60.0 if g['last'] is None else min(0.1, max(1e-4, now - g['last']))
    g['last'] = now
    g['frames'] += 1
    playing = bool(C('Playing', 1))
    if playing:
        g['t'] += dt * float(C('Showspeed', 1.0))
    if g['t'] > SHOW_LEN + 2:
        g['t'] = 0.0 if bool(C('Loop', 1)) else SHOW_LEN
    pa = g.get('pause_at')
    if pa is not None and g['t'] >= pa:                   # test hook: freeze the show at a given second
        g['t'] = pa
        g['pause_at'] = None
        try:
            op(ROOT + '/SHOW_CONTROL').par.Playing.val = 0
        except Exception:
            pass
    t = g['t']

    try:                                                  # Showtime mirrors the clock (use Seek + Goto to scrub)
        op(ROOT + '/SHOW_CONTROL').par.Showtime.val = t
    except Exception:
        pass

    auto = (str(C('Mode', 'auto')) == 'auto')
    v = {k: interp(k, t) for k in K}

    bpm = v['bpm']
    live = (str(C('Audiosource', 'synth')) == 'live')
    la = read_live_audio() if live else None
    sub, bass, mid, high, trans, master, silent = audio_features(t, dt, bpm) if la is None else (la[0], la[1], la[2], la[3], la[4], la[5], la[5] < 0.02)
    if la is not None:
        g['kick'] = bass
    # silence timer (eyes close in sudden silence in live mode too)
    g['quiet'] = g['quiet'] + dt if master < 0.04 else 0.0
    sil = sstep(0.4, 1.2, g['quiet'])
    read_cv(t, dt)
    ce = g['ce']
    boost = sstep(0.45, 0.70, ce)
    neuro_boost = sstep(0.65, 0.85, ce)
    destab = sstep(0.85, 1.0, ce)

    # --- master parameters: AUTO writes them (so the UI mirrors the show); MANUAL reads them
    react = v['audioReact']
    final = {}
    final['Breath'] = v['breath']
    final['Crackgrowth'] = v['crack']
    final['Machinereveal'] = v['machine']
    final['Biology'] = v['bio']
    final['Rootgrowth'] = v['root']
    final['Neuralactivity'] = min(1.0, v['neural'] * (1 + 0.8 * neuro_boost))
    open_key = v['eyeOpen'] * (0.35 + 0.65 * sstep(0.03, 0.18, ce)) * (1 - sil * 0.9)
    open_key = max(open_key, 0.0 if v['eyeOpen'] < 0.05 else min(1.0, trans * 0.5 * v['eyeOpen']) + open_key)
    final['Eyeopen'] = min(1.0, open_key)
    final['Splatdissolve'] = v['splat']
    final['Gravity'] = v['gravity']
    final['Turbulence'] = v['turb'] * (1 + 0.6 * destab)
    final['Returnstrength'] = v['returnStr']
    final['Volumetricintensity'] = v['volum']
    final['Audioreactivity'] = v['audioReact']
    final['Structuralstability'] = v['stability']
    final['Heartrate'] = bpm
    final['Crowdenergy'] = ce
    ctl = op(ROOT + '/SHOW_CONTROL')
    if auto:
        for pn, val in final.items():
            try:
                ctl.par[pn].val = float(val)
            except Exception:
                pass
        m = final
    else:
        m = {}
        for pn, val in final.items():
            try:
                m[pn] = float(ctl.par[pn].eval())
            except Exception:
                m[pn] = val
        m['Crowdenergy'] = ce
    et = None
    if auto:
        g['eyeX'] += (g['cx'] - g['eyeX']) * min(1.0, dt * 1.8)
        g['eyeY'] += (0.10 + 0.25 * g['cy'] - g['eyeY']) * min(1.0, dt * 1.8)
        try:
            ctl.par.Eyetargetx.val = g['eyeX']
            ctl.par.Eyetargety.val = g['eyeY']
        except Exception:
            pass
    ex, ey = g['eyeX'], g['eyeY']
    if not auto:
        try:
            ex, ey = float(ctl.par.Eyetargetx.eval()), float(ctl.par.Eyetargety.eval())
        except Exception:
            pass

    # --- breath: slow cycle (inhale slower than exhale) + sub-bass structural breathing
    period = 6.5
    ph = (t / period) % 1.0
    wave = 0.5 - 0.5 * math.cos(math.pi * 2 * (ph ** 0.85))
    breath = m['Breath'] * wave + 0.22 * sub * m['Audioreactivity'] * (1 if m['Breath'] > 0.05 else 0)

    # --- anomalies (opening minute)
    a_blink = (bump(t, 58.0, 58.5) + bump(t, 63.0, 63.4) + bump(t, 190, 190.3) * 0.0) if t < 130 else 0.0
    a_blink = max(a_blink, bump(t, 889.8, 890.6) + bump(t, 891.0, 891.4) * 0.0)
    a_orn = bump(t, 66, 78)
    a_shadow = bump(t, 80, 92)
    a_col = bump(t, 92, 108)
    look = bump(t, 893.0, 897.0) if t > 880 else 0.0
    pulse = (t - 897.0) / 2.6 if 897.0 < t < 899.6 else 0.0
    beat_pulse = g['kick']
    # a heartbeat at the very end
    if 895.5 < t < 897.5:
        beat_pulse = max(beat_pulse, 0.35 * math.exp(-abs(t - 896.0) * 6))

    # --- machine gear angle accumulates with speed (machine -> biology slows it)
    g['gear'] += dt * (0.6 * v['machineSpd'] * (1 - 0.6 * m['Biology']) + 0.15 * sub)

    # --- audience release time
    aud_t = max(0.0, t - 504.0)
    if t >= 500.0 and not g['snapped']:
        TEX['snap'][...] = TEX['live']
        g['snapped'] = True
    if t < 480:
        g['snapped'] = False

    cw = sstep(726, 745, t) * (1 - sstep(770, 800, t))               # the camera drifts into the particle storm
    camx, camz = 0.22 * cw * math.sin(0.4 * (t - 726)), -0.35 * cw
    pupil = 0.35 + 0.5 * sstep(0.3, 0.9, ce) + 0.25 * g['kick'] * v['eyeMorph'] + 0.2 * trans
    vals = dict(time=t, showT=t, breath=breath, beat=beat_pulse,
                stone=v['stone'], crack=m['Crackgrowth'], machine=m['Machinereveal'], bio=m['Biology'],
                bone=v['bone'], artery=min(1.2, v['artery'] * (1 + 0.5 * boost)), heart=v['heart'], root=m['Rootgrowth'],
                rd=v['rd'], neural=m['Neuralactivity'], sync=v['sync'], eyeMorph=v['eyeMorph'],
                eyeOpen=m['Eyeopen'], eyeX=ex, eyeY=ey, pupil=min(1.0, pupil),
                crowd=ce, towerL=v['towerL'], towerR=v['towerR'], splat=m['Splatdissolve'],
                stability=m['Structuralstability'], gravity=m['Gravity'], turb=m['Turbulence'], returnStr=m['Returnstrength'],
                volum=m['Volumetricintensity'], audioReact=m['Audioreactivity'], kick=g['kick'], bpm=m['Heartrate'],
                sub=sub, bass=bass, mid=mid, high=high, transient=trans, master=master, silence=sil if la is not None else (1.0 if silent else 0.0),
                split=m['Machinereveal'], dna=v['dna'], human=v['human'], humanStage=v['humanStage'], audience=v['audience'],
                scaleAmt=v['scaleAmt'], scaleStage=v['scaleStage'], enterProg=v['enterProg'], recursion=v['recursion'],
                crowdL=g['cl'], crowdC=g['cc'], crowdR=g['cr'], destab=destab,
                aBlink=a_blink, aOrn=a_orn, aShadow=a_shadow, aCol=a_col,
                rootBio=v['rootBio'], recon=v['recon'], splatVis=v['splatVis'], humanStone=v['humanStone'],
                bwC=v['bwC'], bwT=v['bwT'], bwCol=v['bwCol'], bwWin=v['bwWin'],
                fade=v['fade'], gear=g['gear'], lastLook=look, stonePulse=pulse,
                audT=aud_t, enterAmt=v['enter'], crackPhase=m['Crackgrowth'], vascBoost=boost, camx=camx, camz=camz)
    S.clear()
    S.update(vals)
    for i, names in enumerate(PACK):
        for j, nm in enumerate(names):
            UST[0, i, j] = float(vals.get(nm, 0.0))
    try:
        op(ROOT + '/SHOW_CONTROL/ustate').cook(force=True)
    except Exception:
        pass

    # status line
    if now - g['info_t'] > 0.25:
        g['info_t'] = now
        sec = next((s[2] for s in SECTIONS if s[0] <= t < s[1]), '')
        txt = 'KOELNER DOM  %s  t=%5.1fs  %s  crowd %.2f  %s' % (sec, t, 'AUTO' if auto else 'MANUAL', ce, '' if playing else '[paused]')
        try:
            op(ROOT + '/SHOW_CONTROL/show_info').text = txt
        except Exception:
            pass
