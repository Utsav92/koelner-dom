"""
KOELNER DOM - THE CATHEDRAL IS ALIVE.  TouchDesigner network builder.
Run inside TouchDesigner (Textport, or via the MCP bridge):

    exec(open(r'C:\\Users\\Utsav\\koelner-dom\\build_dom.py', encoding='utf-8').read())

(Re)creates /project1/KOELNER_DOM with all 22 sub-networks, embeds shaders + scripts as DATs. Parameter names that differ on another TD
build are logged in WARN rather than aborting.
"""
import os
import re

DIR = os.environ.get('KOELNER_DIR', r'C:\Users\Utsav\koelner-dom')
ROOT = '/project1/KOELNER_DOM'
CW, CH = 720, 1280                     # master canvas (portrait facade). Non-Commercial TD caps resolution at 1280 on the long side.
QUAL = os.environ.get('KOELNER_QUALITY', 'low')
QRES = {'low': (360, 640), 'medium': (540, 960), 'high': (720, 1280)}
LRES = QRES[QUAL]                      # resolution of every per-frame layer (the twin stays full-res: it cooks once)
FULL = (CW, CH)
LAYERS = []
WARN = []
_pos = {}


def read(rel):
    with open(os.path.join(DIR, rel), 'r', encoding='utf-8') as f:
        txt = f.read()
    txt = re.sub(r'//#INCLUDE (\S+)', lambda m: read('shaders/' + m.group(1)), txt)
    return txt.replace('__ROOT__', ROOT)


def callback(name):
    txt = read('scripts/callbacks.py')
    parts = re.split(r'^#### (\w+)\n', txt, flags=re.M)
    return dict(zip(parts[1::2], parts[2::2]))[name]


def P(o, **kw):
    for k, v in kw.items():
        try:
            getattr(o.par, k).val = v
        except Exception as e:
            WARN.append('%s.%s = %r -> %s' % (o.path, k, v, e))


def X(o, **kw):
    for k, v in kw.items():
        try:
            getattr(o.par, k).expr = v
        except Exception as e:
            WARN.append('%s.%s expr %r -> %s' % (o.path, k, v, e))


def mk(parent, typ, name):
    o = parent.create(typ, name)
    i = _pos.get(parent.path, 0)
    _pos[parent.path] = i + 1
    o.nodeX = (i % 6) * 230
    o.nodeY = -(i // 6) * 150
    return o


def wire(src, dst, idx=0):
    try:
        if src.parent() != dst.parent():              # inputs must be siblings: bridge COMPs with a Select
            nm = 'in_%s_%s' % (src.parent().name.lower(), src.name)
            s = dst.parent().op(nm)
            if s is None:
                s = mk(dst.parent(), 'selectTOP', nm)
                P(s, top=src.path)
            src = s
        dst.inputConnectors[idx].connect(src)
    except Exception as e:
        WARN.append('wire %s -> %s[%d]: %s' % (src.path, dst.path, idx, e))


def glsl_top(parent, name, shader, inputs=(), res='layer', fmt='rgba16float', consts=None, mat_defs=''):
    """GLSL TOP whose input list (sTD2DInputs[0..]) is set through the TOPs parameter (works across COMPs)."""
    g = mk(parent, 'glslTOP', name)
    d = g.par.pixeldat.eval()
    if d is None:
        d = mk(parent, 'textDAT', name + '_pixel')
        P(g, pixeldat=d.path)
    d.text = read('shaders/' + shader)
    if inputs:
        P(g, tops=' '.join(s.path for s in inputs))
    if res == 'layer':
        res = LRES
        LAYERS.append(g.path)
    if res:
        P(g, outputresolution='custom', resolutionw=res[0], resolutionh=res[1])
    if fmt:
        P(g, format=fmt)
    if consts:                                      # constant vec uniforms: {'uMode': (0,0,0,0)}
        try:
            g.seq.vec.numBlocks = len(consts)
        except Exception as e:
            WARN.append('%s vec seq: %s' % (g.path, e))
        for i, (n, vals) in enumerate(consts.items()):
            P(g, **{'vec%dname' % i: n})
            for c, v in zip('xyzw', vals):
                P(g, **{'vec%dvalue%s' % (i, c): float(v)})
    return g


def null(parent, name, src=None, kind='TOP'):
    n = mk(parent, 'null' + kind, name)
    if src is not None:
        wire(src, n)
    return n


# ------------------------------------------------------------------ project root + the 22 networks
proj = op('/project1')
if proj is None:
    proj = op('/').create('baseCOMP', 'project1')
old = proj.op('KOELNER_DOM')
if old is not None:
    old.destroy()
_pos.clear()
R = mk(proj, 'baseCOMP', 'KOELNER_DOM')
NAMES = ['DOM_DIGITAL_TWIN', 'PROJECTOR_CALIBRATION', 'ARCH_MASKS', 'PHOTOGRAMMETRY', 'GAUSSIAN_SPLATS', 'STONE_SHADER', 'CRACK_ENGINE',
         'MACHINERY', 'SKELETON', 'ARTERIES', 'HEART', 'ROOTS', 'REACTION_DIFFUSION', 'NEURONS', 'EYES', 'CROWD_VISION', 'AUDIO_ANALYSIS',
         'PARTICLE_SIM', 'VOLUMETRICS', 'CAMERA', 'SHOW_CONTROL', 'OUTPUT_PROJECTORS']
B = {n: mk(R, 'baseCOMP', n) for n in NAMES}

# ================================================================== SHOW_CONTROL: master parameters, cues, brain, uniform texture
SC = B['SHOW_CONTROL']
SC.destroyCustomPars()
pg = SC.appendCustomPage('Dom')


def cpar(kind, name, label, default=0, lo=None, hi=None, menu=None):
    if kind == 'pulse':
        pg.appendPulse(name, label=label)
        return
    if kind == 'xy':
        p = pg.appendXY(name, label=label)
        for q in p:
            q.min, q.max, q.clampMin, q.clampMax = 0, 1, True, True
            q.default = default
            q.val = default
        return
    if kind == 'toggle':
        p = pg.appendToggle(name, label=label)
    elif kind == 'float':
        p = pg.appendFloat(name, label=label)
    elif kind == 'menu':
        p = pg.appendMenu(name, label=label)
        p[0].menuNames = menu
        p[0].menuLabels = [m.upper() for m in menu]
    par = p[0]
    if lo is not None:
        par.min, par.max, par.clampMin, par.clampMax = lo, hi, True, True
        par.normMin, par.normMax = lo, hi
    par.default = default
    par.val = default


cpar('menu', 'Mode', 'MODE (auto = timeline writes masters)', 'auto', menu=['auto', 'manual'])
cpar('toggle', 'Playing', 'PLAYING', 1)
cpar('toggle', 'Loop', 'LOOP', 1)
cpar('float', 'Showspeed', 'SHOW SPEED (x)', 1.0, 0.0, 12.0)
cpar('float', 'Showtime', 'SHOW TIME (s)', 0.0, 0.0, 905.0)
cpar('float', 'Seek', 'SEEK (s)', 0.0, 0.0, 900.0)
cpar('pulse', 'Goto', 'GO TO SEEK')
cpar('pulse', 'Restart', 'RESTART SHOW')
for cue in ('Stone', 'Awaken', 'Crack', 'Machine', 'Heart', 'Roots', 'Neural', 'Conscious', 'Dissolve', 'Dna', 'Rebirth', 'Reconstruct',
            'Sleep', 'Enter'):
    cpar('pulse', cue, 'CUE ' + cue.upper())
MP = [('Breath', 'BREATH', 0, 1), ('Heartrate', 'HEART_RATE', 40, 180), ('Crackgrowth', 'CRACK_GROWTH', 0, 1),
      ('Machinereveal', 'MACHINE_REVEAL', 0, 1), ('Biology', 'BIOLOGY', 0, 1), ('Rootgrowth', 'ROOT_GROWTH', 0, 1),
      ('Neuralactivity', 'NEURAL_ACTIVITY', 0, 1), ('Eyeopen', 'EYE_OPEN', 0, 1), ('Crowdenergy', 'CROWD_ENERGY', 0, 1),
      ('Splatdissolve', 'SPLAT_DISSOLVE', 0, 1), ('Gravity', 'GRAVITY', -1, 1), ('Turbulence', 'TURBULENCE', 0, 3),
      ('Returnstrength', 'RETURN_STRENGTH', 0, 1.5), ('Volumetricintensity', 'VOLUMETRIC_INTENSITY', 0, 1.5),
      ('Audioreactivity', 'AUDIO_REACTIVITY', 0, 1), ('Structuralstability', 'STRUCTURAL_STABILITY', 0, 1)]
for n, lab, lo, hi in MP:
    cpar('float', n, lab, lo if n == 'Heartrate' else 0, lo, hi)
cpar('xy', 'Eyetarget', 'EYE_TARGET (uv)', 0.5)
cpar('toggle', 'Demomode', 'Demo crowd + demo audio (no cameras / mic)', 1)
cpar('menu', 'Audiosource', 'Audio source', 'synth', menu=['synth', 'live'])
cpar('toggle', 'Mirror', 'Mirror crowd camera', 0)
cpar('float', 'Segthreshold', 'Silhouette threshold', 0.10, 0.01, 0.6)
cpar('float', 'Bglearn', 'Background learn rate', 0.004, 0.0, 0.1)
cpar('float', 'Crowdgain', 'Crowd energy gain', 1.0, 0.1, 6.0)
cpar('float', 'Volume', 'Audio out volume', 0.5, 0.0, 1.0)
cpar('menu', 'Quality', 'QUALITY (layer resolution: low 360x640 / medium 540x960 / high 720x1280)', QUAL, menu=['low', 'medium', 'high'])
cpar('toggle', 'Hud', 'Show status HUD', 1)
cpar('pulse', 'Openwindow', 'OPEN OUTPUT WINDOW')
cpar('pulse', 'Loadkantan', 'LOAD KANTAN MAPPER (palette) into PROJECTOR_CALIBRATION')

brain = mk(SC, 'textDAT', 'brain')
brain.text = read('scripts/brain.py')
info = mk(SC, 'textDAT', 'show_info')
ust = mk(SC, 'scriptTOP', 'ustate')
ud = mk(SC, 'textDAT', 'ustate_callbacks')
ud.text = callback('ustate_top')
P(ust, callbacks=ud.path)
for key in ('live', 'snap'):
    t = mk(SC, 'scriptTOP', 'crowd_' + key)
    d = mk(SC, 'textDAT', 'crowd_%s_callbacks' % key)
    d.text = callback('crowd_top').replace('__KEY__', key)
    P(t, callbacks=d.path)
try:
    brain.module.tick()
    ust.cook(force=True)
except Exception as e:
    WARN.append('dry-run tick: %r' % (e,))
USTATE = ust

# ================================================================== DOM_DIGITAL_TWIN  (representations of the cathedral)
Tw = B['DOM_DIGITAL_TWIN']
TW_DIR = os.path.join(DIR, 'twin')
os.makedirs(TW_DIR, exist_ok=True)
TW_EXT = 'exr'
TW_FILES = {k: os.path.join(TW_DIR, 'twin%s.%s' % (k, TW_EXT)) for k in 'ABC'}


def make_twin_files():
    """Compute the procedural twin ONCE (slow on a weak GPU), write it to EXR, then drop the procedural nodes."""
    a_raw = glsl_top(Tw, 'twinA_raw', 'twin.glsl', [], res=FULL, consts={'uMode': (0, 0, 0, 0)})
    a_ed = glsl_top(Tw, 'twinA_depth_edges_proc', 'twin_edge.glsl', [a_raw], res=FULL)
    b_ = glsl_top(Tw, 'twinB_proc', 'twin.glsl', [], res=FULL, consts={'uMode': (1, 0, 0, 0)})
    c_ = glsl_top(Tw, 'twinC_proc', 'twin.glsl', [], res=FULL, consts={'uMode': (2, 0, 0, 0)})
    for k, t in zip('ABC', (a_ed, b_, c_)):
        t.cook(force=True)
        t.save(TW_FILES[k])
    for t in (a_ed, a_raw, b_, c_):
        t.destroy()


if not all(os.path.exists(f) for f in TW_FILES.values()):
    make_twin_files()
twin_in = {}
for k, nm in zip('ABC', ('twinA_depth_edges', 'twinB_regions', 'twinC_members')):
    f = mk(Tw, 'moviefileinTOP', nm)
    P(f, file=TW_FILES[k])
    try:
        P(f, playmode='sequential', play=0)
    except Exception:
        pass
    try:
        f.par.reload.pulse()
        f.cook(force=True)
    except Exception as e:
        WARN.append('twin file load: %r' % (e,))
    twin_in[k] = f
twinA, twinB, twinC = twin_in['A'], twin_in['B'], twin_in['C']
TWIN = [USTATE, twinA, twinB, twinC]                    # the standard input list of every facade layer
depth_map = null(Tw, 'DEPTH_MAP', twinA)
normal_map = null(Tw, 'NORMAL_MAP', glsl_top(Tw, 'normal_map_gen', 'normal_map.glsl', [twinA], res=FULL))
for nm, h in (('HIGH_RES_MESH', (512, 1024)), ('LOW_RES_PROJECTION_MESH', (64, 128))):
    g = mk(Tw, 'gridSOP', nm.lower() + '_grid')
    P(g, rows=h[1], cols=h[0], sizex=0.5625, sizey=1.0)
    null(Tw, nm, g, kind='SOP')
tw_note = mk(Tw, 'textDAT', 'about')
tw_note.text = ('PROCEDURAL twin-tower Gothic facade standing in for a LiDAR/photogrammetry scan (none was available).\n'
                'Representations: HIGH_RES_MESH / LOW_RES_PROJECTION_MESH (grids to displace by DEPTH_MAP), POINT_CLOUD + GAUSSIAN_SPLAT_MODEL '
                '(PARTICLE_SIM home textures), DEPTH_MAP, NORMAL_MAP, ARCH_MASKS.\nTo use a real scan: bake its depth to twinA.r (height), '
                'windows to .g, solid to .a; regions to twinB; members to twinC, and replace the three GLSL TOPs with Movie File In TOPs.')

# ================================================================== ARCH_MASKS
AM = B['ARCH_MASKS']
MASKS = ['TOWER_LEFT', 'TOWER_RIGHT', 'CENTER', 'WINDOWS', 'PORTALS', 'COLUMNS', 'STATUES', 'ORNAMENTS', 'ROOF']
for i, nm in enumerate(MASKS):
    g = glsl_top(AM, nm.lower() + '_gen', 'mask_pick.glsl', TWIN, res=(360, 640), consts={'uMode': (i, 0, 0, 0)})
    null(AM, nm, g)

# ================================================================== PHOTOGRAMMETRY (scan ingest stubs)
Ph = B['PHOTOGRAMMETRY']
for nm, label in (('scan_mesh', 'photogrammetry / LiDAR mesh (.obj/.fbx)'), ('scan_pointcloud', 'LiDAR point cloud (.ply/.xyz)')):
    f = mk(Ph, 'fileinSOP', nm)
    f.comment = label + ' - set the File parameter after you have an authorised capture'
mk(Ph, 'textDAT', 'about').text = ('Ingest point for a properly authorised capture. Photogrammetry mesh -> scan_mesh; LiDAR cloud -> scan_pointcloud; '
                                   'Gaussian-splat .ply -> replace PARTICLE_SIM home textures (see shaders/home.glsl for the layout). '
                                   'Bake depth/normal/masks into the DOM_DIGITAL_TWIN textures so every layer stays aligned to the real stone.')

# ================================================================== PROJECTOR_CALIBRATION
PC = B['PROJECTOR_CALIBRATION']
proj_tbl = mk(PC, 'tableDAT', 'projectors')
HDR = ['name', 'px', 'py', 'pz', 'rx', 'ry', 'rz', 'throw', 'fov_h', 'w', 'h', 'k1', 'k2', 'cx', 'cy',
       'c00x', 'c00y', 'c10x', 'c10y', 'c01x', 'c01y', 'c11x', 'c11y', 'u0', 'u1', 'v0', 'v1', 'blend_b', 'blend_t']
proj_tbl.clear()
proj_tbl.appendRow(HDR)
proj_tbl.appendRow(['p1_lower', 0, 1.5, -60, 12, 0, 0, 1.6, 0, 720, 742, 0.0, 0.0, 0.5, 0.5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0.0, 0.58, 0.0, 0.14])
proj_tbl.appendRow(['p2_upper', 0, 12, -60, 28, 0, 0, 1.6, 0, 720, 742, 0.0, 0.0, 0.5, 0.5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0.42, 1.0, 0.14, 0.0])
mk(PC, 'textDAT', 'calibration_notes').text = (
    'One row per physical projector: position (m, relative to the facade centre), rotation (deg), throw ratio, lens k1/k2, 4 keystone corner '
    'offsets, the part of the master canvas it covers (u0..v1) and edge-blend widths. fov_h = 2*atan(0.5/throw). The OUTPUT_PROJECTORS '
    'warp shaders read this table live. Fine alignment: Kantan Mapper (loaded below if found) or edit c00..c11 against the real stone '
    'while the TEST pattern is on. These are placeholders until measured on site.')
# Kantan Mapper (4000+ operators) is NOT loaded by default; pulse SHOW_CONTROL > LOAD KANTAN MAPPER to load it from the palette.


def table_cell(col, row):
    return "op('%s/PROJECTOR_CALIBRATION/projectors')['%s','%s']" % (ROOT, row, col)


# ================================================================== REACTION_DIFFUSION + CRACK_ENGINE
Rd = B['REACTION_DIFFUSION']
Cr = B['CRACK_ENGINE']
rd_seed = mk(Rd, 'constantTOP', 'rd_seed')
P(rd_seed, outputresolution='custom', resolutionw=360, resolutionh=640, format='rgba32float', colorr=1, colorg=0, colorb=0, alpha=1)
rd_fb = mk(Rd, 'feedbackTOP', 'rd_fb')
wire(rd_seed, rd_fb)
crack = glsl_top(Cr, 'crack', 'crack.glsl', TWIN + [rd_fb])
crack_out = null(Cr, 'crack_out', crack)
prev = rd_fb
rd_passes = []
for i in range(6):
    g = glsl_top(Rd, 'rd_pass%d' % (i + 1), 'rd.glsl', TWIN + [prev, crack_out], res=(360, 640), fmt='rgba32float')
    rd_passes.append(g)
    prev = g
P(rd_fb, top=rd_passes[-1].path)
rd_out = null(Rd, 'rd_out', rd_passes[-1])
skin = glsl_top(Rd, 'skin', 'skin.glsl', TWIN + [rd_out])
skin_out = null(Rd, 'skin_out', skin)

# ================================================================== layers: machinery, skeleton, arteries, heart, roots, neurons, eyes
mach_out = null(B['MACHINERY'], 'machine_out', glsl_top(B['MACHINERY'], 'machine', 'machine.glsl', TWIN))
bone_out = null(B['SKELETON'], 'bone_out', glsl_top(B['SKELETON'], 'bones', 'bones.glsl', TWIN))
vess_out = null(B['ARTERIES'], 'vessel_out', glsl_top(B['ARTERIES'], 'vessels', 'vessels.glsl', TWIN))
heart_out = null(B['HEART'], 'heart_out', glsl_top(B['HEART'], 'heart', 'heart.glsl', TWIN))
root_out = null(B['ROOTS'], 'root_out', glsl_top(B['ROOTS'], 'roots', 'roots.glsl', TWIN))
neur_out = null(B['NEURONS'], 'neuron_out', glsl_top(B['NEURONS'], 'neurons', 'neurons.glsl', TWIN))
eye_out = null(B['EYES'], 'eye_out', glsl_top(B['EYES'], 'eyes', 'eyes.glsl', TWIN))

# ================================================================== STONE_SHADER
St = B['STONE_SHADER']
stone_out = null(St, 'stone_out', glsl_top(St, 'stone', 'stone.glsl', TWIN))

# ================================================================== CROWD_VISION  (movement + silhouettes only, no identification)
CV = B['CROWD_VISION']
cam_in = mk(CV, 'videodeviceinTOP', 'webcam')
cv_small = mk(CV, 'resolutionTOP', 'cv_small')
wire(cam_in, cv_small)
P(cv_small, outputresolution='custom', resolutionw=96, resolutionh=54)
mk(CV, 'textDAT', 'about').text = ('Demo mode (SHOW_CONTROL.Demomode) simulates a crowd. With a camera: cv_small -> frame-difference "optical flow" (CROWD_ENERGY, '
                                   'left/centre/right activity, centroid for EYE_TARGET) and background-subtracted silhouettes (crowd_live / crowd_snap in '
                                   'SHOW_CONTROL). No face detection or identification is performed.')
sil_out = null(CV, 'sil_out', glsl_top(CV, 'sil', 'sil.glsl', TWIN + [SC.op('crowd_live'), SC.op('crowd_snap')]))

# ================================================================== PARTICLE_SIM  (the Gaussian-splat model, GPU)
PS = B['PARTICLE_SIM']
NP = 256
homeA = glsl_top(PS, 'homeA_position', 'home.glsl', TWIN, res=(NP, NP), fmt='rgba32float', consts={'uMode': (0, 0, 0, 0)})
homeB = glsl_top(PS, 'homeB_class', 'home.glsl', TWIN, res=(NP, NP), fmt='rgba32float', consts={'uMode': (1, 0, 0, 0)})


def seedc(name):
    c = mk(PS, 'constantTOP', name)
    P(c, outputresolution='custom', resolutionw=NP, resolutionh=NP, format='rgba32float', colorr=0, colorg=0, colorb=0, alpha=0)
    return c


pos_seed, vel_seed = seedc('pos_seed'), seedc('vel_seed')
pos_fb, vel_fb = mk(PS, 'feedbackTOP', 'pos_fb'), mk(PS, 'feedbackTOP', 'vel_fb')
wire(pos_seed, pos_fb)
wire(vel_seed, vel_fb)
vel_sim = glsl_top(PS, 'vel_sim', 'vel.glsl', [USTATE, homeA, homeB, pos_fb, vel_fb], res=(NP, NP), fmt='rgba32float')
pos_sim = glsl_top(PS, 'pos_sim', 'pos.glsl', [USTATE, homeA, homeB, pos_fb, vel_sim], res=(NP, NP), fmt='rgba32float')
P(pos_fb, top=pos_sim.path)
P(vel_fb, top=vel_sim.path)
pos_out = null(PS, 'pos_out', pos_sim)
vel_out = null(PS, 'vel_out', vel_sim)

# ================================================================== CAMERA (3D camera for the splats + the virtual camera sequences)
Cm = B['CAMERA']
cam = mk(Cm, 'cameraCOMP', 'cam')
cam_t = mk(Cm, 'nullCOMP', 'cam_target')
CD = 1.6
import math as _m
P(cam, fov=2 * _m.degrees(_m.atan(0.5 * 0.5625 / CD)), near=0.05, far=50, lookat=cam_t.path, tz=CD)
BR = "op('%s/SHOW_CONTROL/brain').module.S" % ROOT
X(cam, tx=BR + ".get('camx',0)", tz='%s + %s.get("camz",0)' % (CD, BR))
scale_out = null(Cm, 'scale_out', glsl_top(Cm, 'scale', 'scale.glsl', [USTATE]))

# ================================================================== OUTPUT: composite stack
O = B['OUTPUT_PROJECTORS']
comp1 = glsl_top(O, 'comp_facade', 'comp1.glsl', TWIN + [stone_out, crack_out, mach_out, bone_out, vess_out, heart_out, root_out, skin_out])
comp2 = glsl_top(O, 'comp_effects', 'comp2.glsl', [USTATE, comp1, neur_out, eye_out, sil_out, scale_out])
enter_out = null(Cm, 'enter_out', glsl_top(Cm, 'enter', 'enter.glsl', [USTATE, comp2]))

# ================================================================== GAUSSIAN_SPLATS (instanced billboards from the particle textures)
G = B['GAUSSIAN_SPLATS']
quad = mk(G, 'rectangleSOP', 'quad')
P(quad, sizex=1, sizey=1)
STONE_FOR_SPLATS = stone_out


def additive(mat):
    P(mat, blending=1, srcblend='one', destblend='one', depthtest=0, depthwriting=0)


def splat_mat(name, vtext, ftext, samplers, vecs):
    m = mk(G, 'glslMAT', name)
    try:
        m.par.vdat.eval().text = '#define IS_MAT\n' + vtext
        m.par.pdat.eval().text = ftext
    except Exception as e:
        WARN.append('%s shader dats: %s' % (name, e))
    try:
        m.seq.sampler.numBlocks = len(samplers)
        m.seq.vec.numBlocks = len(vecs)
    except Exception as e:
        WARN.append('%s seq: %s' % (name, e))
    for i, (sn, top) in enumerate(samplers):
        P(m, **{'sampler%dname' % i: sn, 'sampler%dtop' % i: top.path})
    for i, (vn, vals) in enumerate(vecs):
        P(m, **{'vec%dname' % i: vn})
        for c, v in zip('xyzw', vals):
            P(m, **{'vec%dvalue%s' % (i, c): float(v)})
    additive(m)
    return m


def geo(name, mat, count):
    g = mk(G, 'geometryCOMP', name)
    for c in list(g.children):
        c.destroy()
    s = g.create('selectSOP', 'sel')
    P(s, sop=quad.path)
    s.display = True
    s.render = True
    P(g, material=mat.path, instancing=1, instancecountmode='manual', numinstances=count)
    return g


m_splat = splat_mat('m_splat', read('shaders/splat_vert.glsl'), read('shaders/splat_frag.glsl'),
                    [('uSt', USTATE), ('uPos', pos_out), ('uHomeA', homeA), ('uHomeB', homeB), ('uStone', stone_out)],
                    [('uSP', (2.0, 1.35, 0, 0)), ('uView', (LRES[0], LRES[1], 0, 0))])

g_splat = geo('g_splat', m_splat, NP * NP)
m_aud = splat_mat('m_aud', read('shaders/aud_vert.glsl'), read('shaders/splat_frag.glsl'),
                  [('uSt', USTATE), ('uLive', SC.op('crowd_live')), ('uSnap', SC.op('crowd_snap'))], [('uView', (LRES[0], LRES[1], 0, 0))])
g_aud = geo('g_aud', m_aud, 128 * 128)
render = mk(G, 'renderTOP', 'render')
P(render, geometry=G.path + '/g_*', camera=cam.path, outputresolution='custom', resolutionw=LRES[0], resolutionh=LRES[1],
  format='rgba16float', antialias='off', bgcolorr=0, bgcolorg=0, bgcolorb=0, bgcolora=1)
try:
    P(render, lights='')
except Exception:
    pass
LAYERS.append(render.path)
splat_out = null(G, 'splat_out', render)

# ================================================================== VOLUMETRICS + OUTPUT stack
comp3 = glsl_top(O, 'comp_blend', 'comp3.glsl', [USTATE, comp2, enter_out, splat_out])
Vo = B['VOLUMETRICS']
vol_out = null(Vo, 'volum_out', glsl_top(Vo, 'volum', 'volum.glsl', [USTATE, comp3]))
master = glsl_top(O, 'master', 'final.glsl', [USTATE, comp3, vol_out])
master_out = null(O, 'MASTER_OUT', master)

# projector outputs: crop + keystone + lens + edge blend, parameters live from PROJECTOR_CALIBRATION
for pi, row in enumerate(('p1_lower', 'p2_upper')):
    g = glsl_top(O, 'proj%d_warp' % (pi + 1), 'proj_warp.glsl', [master_out], res=(720, 742),
                 consts={'uReg': (0, 1, 0, 1), 'uLens': (0, 0, .5, .5), 'uCA': (0, 0, 0, 0), 'uCB': (0, 0, 0, 0), 'uBlend': (0, 0, 0, 0)})
    c = lambda col: table_cell(col, row)
    vexpr = {'uReg': [c('u0'), c('u1'), c('v0'), c('v1')], 'uLens': [c('k1'), c('k2'), c('cx'), c('cy')],
             'uCA': [c('c00x'), c('c00y'), c('c10x'), c('c10y')], 'uCB': [c('c01x'), c('c01y'), c('c11x'), c('c11y')],
             'uBlend': ['0', c('blend_t') if pi == 0 else '0', '0', '0']}
    if pi == 0:
        vexpr['uBlend'] = ['0', c('blend_t'), '0', '0']
    else:
        vexpr['uBlend'] = [c('blend_b'), '0', '0', '0']
    for i, name in enumerate(('uReg', 'uLens', 'uCA', 'uCB', 'uBlend')):
        for cc, e in zip('xyzw', vexpr[name]):
            X(g, **{'vec%dvalue%s' % (i, cc): e})
    null(O, 'PROJECTOR_%d' % (pi + 1), g)

# preview with HUD (not sent to projectors)
hud = mk(O, 'textTOP', 'hud_text')
LAYERS.append(hud.path)
P(hud, outputresolution='custom', resolutionw=LRES[0], resolutionh=LRES[1], bgalpha=0, fontsizex=15, alignx='left', aligny='top',
  fontcolorr=0.8, fontcolorg=0.9, fontcolorb=1.0)
X(hud, text="op('%s/SHOW_CONTROL/show_info').text if op('%s/SHOW_CONTROL').par.Hud else ''" % (ROOT, ROOT))
prev_c = mk(O, 'compositeTOP', 'preview')
wire(hud, prev_c, 0)
wire(master_out, prev_c, 1)
P(prev_c, operand='over')
outtop = mk(O, 'outTOP', 'out1')
wire(master_out, outtop)
win = mk(O, 'windowCOMP', 'window')
P(win, winw=432, winh=768)
try:
    win.par.winop = prev_c.path
except Exception as e:
    WARN.append('window op: %s' % e)

# ================================================================== AUDIO_ANALYSIS (live analysis + a generative score for demo mode)
AA = B['AUDIO_ANALYSIS']
try:
    ain = mk(AA, 'audiodeviceinCHOP', 'live_in')
    bands = []
    for nm, flt, cut in (('sub', 'lowpass', 70), ('bass', 'lowpass', 220), ('mid', 'bandpass', 1200), ('high', 'highpass', 4500)):
        f = mk(AA, 'audiofilterCHOP', nm + '_filter')
        wire(ain, f)
        P(f, filter=flt)
        try:
            P(f, cutofffrequency=cut)
        except Exception:
            pass
        an = mk(AA, 'analyzeCHOP', nm + '_rms')
        wire(f, an)
        P(an, function='rmspower')
        lg = mk(AA, 'lagCHOP', nm + '_lag')
        wire(an, lg)
        P(lg, lag1=0.05, lag2=0.25)
        rn = mk(AA, 'renameCHOP', nm)
        wire(lg, rn)
        P(rn, renameto=nm)
        bands.append(rn)
    mrg = mk(AA, 'mergeCHOP', 'bands')
    for i, b_ in enumerate(bands):
        wire(b_, mrg, i)
    msel = mk(AA, 'mathCHOP', 'master_sum')
    wire(mrg, msel)
    P(msel, chanop='add')
    mrn = mk(AA, 'renameCHOP', 'master')
    wire(msel, mrn)
    P(mrn, renameto='master')
    slope = mk(AA, 'slopeCHOP', 'master_slope')
    wire(mrn, slope)
    lim = mk(AA, 'limitCHOP', 'transient_pos')
    wire(slope, lim)
    P(lim, type='clamp', min=0, max=100)
    trn = mk(AA, 'renameCHOP', 'transient')
    wire(lim, trn)
    P(trn, renameto='transient')
    feat = mk(AA, 'mergeCHOP', 'features_merge')
    for i, o_ in enumerate((mrg, mrn, trn)):
        wire(o_, feat, i)
    null(AA, 'features', feat, kind='CHOP')
except Exception as e:
    WARN.append('audio analysis chain: %r' % (e,))

voices = []
try:
    def voice(name, wave, freq, amp_expr):
        o = mk(AA, 'audiooscillatorCHOP', name)
        P(o, wavetype=wave, rate=44100)
        P(o, frequency=freq)
        X(o, amp=amp_expr)
        voices.append(o)
    voice('synth_kick', 'sin', 48, BR + ".get('kick',0)*0.9")
    voice('synth_drone', 'sin', 55, BR + ".get('sub',0)*0.35+0.02")
    for i, f in enumerate((110.0, 164.8, 220.0)):
        voice('synth_pad%d' % i, 'tri', f * 1.0, BR + ".get('mid',0)*0.07")
    voice('synth_shimmer', 'sin', 1760, BR + ".get('high',0)*0.05")
    mix = mk(AA, 'mathCHOP', 'synth_mix')
    for i, v in enumerate(voices):
        wire(v, mix, i)
    P(mix, chopop='add')
    X(mix, gain="op('%s/SHOW_CONTROL').par.Volume * (1 if op('%s/SHOW_CONTROL').par.Audiosource == 'synth' else 0)" % (ROOT, ROOT))
    aout = mk(AA, 'audiodeviceoutCHOP', 'audio_out')
    wire(mix, aout)
except Exception as e:
    WARN.append('synth audio chain: %r' % (e,))

lt = mk(SC, 'tableDAT', 'layer_tops')
lt.clear()
for pth in LAYERS:
    lt.appendRow([pth])
# ================================================================== frame driver + pulse handler
fe = mk(SC, 'executeDAT', 'frame_exec')
fe.text = callback('frame_exec')
P(fe, framestart=1, active=1)
pe = mk(SC, 'parameterexecuteDAT', 'par_exec')
pe.text = callback('par_exec')
P(pe, op=SC.path, pars='Quality Goto Restart Openwindow Loadkantan Stone Awaken Crack Machine Heart Roots Neural Conscious Dissolve Dna Rebirth Reconstruct Sleep Enter',
  onpulse=1, valuechange=1, active=1)

result = 'BUILD DONE. WARN (%d):\n' % len(WARN) + '\n'.join(WARN)
print(result)
try:
    project.save(os.path.join(DIR, 'KOELNER_DOM.toe'))
    print('saved', os.path.join(DIR, 'KOELNER_DOM.toe'))
except Exception as e:
    print('save skipped:', e)
