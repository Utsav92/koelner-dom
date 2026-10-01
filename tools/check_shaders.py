"""
Compile every KOELNER DOM shader with WebGL2 (headless Chrome) behind a shim for TouchDesigner's built-ins.
Catches GLSL syntax / type errors without TouchDesigner.   usage:  python tools/check_shaders.py
Material shaders (*_vert / *_frag) are compiled with IS_MAT defined and a vertex shim.
"""
import glob
import json
import os
import re
import subprocess
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
SH = os.path.join(HERE, '..', 'shaders')
CHROME = r'C:\Program Files\Google\Chrome\Application\chrome.exe'

FRAG_SHIM = """#version 300 es
precision highp float;
precision highp int;
precision highp sampler2D;
in vec3 vUV;
struct TDTexInfo { vec4 res; vec4 depth; };
uniform TDTexInfo uTD2DInfos[16];
uniform TDTexInfo uTDOutputInfo;
uniform sampler2D sTD2DInputs[16];
#line 1
"""
VERT_SHIM = """#version 300 es
precision highp float;
precision highp int;
precision highp sampler2D;
#define IS_MAT
in vec3 P;
vec4 TDWorldToProj(vec4 v){ return v; }
#line 1
"""
MAT_FRAG_SHIM = """#version 300 es
precision highp float;
precision highp int;
precision highp sampler2D;
#define IS_MAT
#line 1
"""


def read(name):
    txt = open(os.path.join(SH, name), encoding='utf-8').read()
    return re.sub(r'//#INCLUDE (\S+)', lambda m: open(os.path.join(SH, m.group(1)), encoding='utf-8').read(), txt)


shaders = {}
for f in sorted(glob.glob(os.path.join(SH, '*.glsl'))):
    n = os.path.basename(f)
    if n in ('common.glsl', 'pshapes.glsl'):
        continue
    if n.endswith('_vert.glsl'):
        shaders[n] = ('vertex', VERT_SHIM + read(n))
    elif n.endswith('_frag.glsl'):
        shaders[n] = ('fragment', MAT_FRAG_SHIM + read(n))
    else:
        shaders[n] = ('fragment', FRAG_SHIM + read(n))

html = """<!doctype html><body><pre id=o>running</pre><script>
const S = %s;
const gl = document.createElement('canvas').getContext('webgl2');
let out = [];
if (!gl) { out.push('NO WEBGL2'); }
else for (const [name, [kind, src]] of Object.entries(S)) {
  const sh = gl.createShader(kind === 'vertex' ? gl.VERTEX_SHADER : gl.FRAGMENT_SHADER);
  gl.shaderSource(sh, src); gl.compileShader(sh);
  const ok = gl.getShaderParameter(sh, gl.COMPILE_STATUS);
  out.push((ok ? 'OK   ' : 'FAIL ') + name + (ok ? '' : '\\n' + gl.getShaderInfoLog(sh)));
}
document.getElementById('o').textContent = 'RESULT\\n' + out.join('\\n');
</script></body>""" % json.dumps(shaders)

p = os.path.join(tempfile.gettempdir(), 'koelner_dom_check.html')
open(p, 'w', encoding='utf-8').write(html)
r = subprocess.run([CHROME, '--headless=new', '--disable-gpu-sandbox', '--use-angle=swiftshader',
                    '--enable-unsafe-swiftshader', '--virtual-time-budget=8000', '--dump-dom',
                    'file:///' + p.replace('\\', '/')], capture_output=True, text=True, timeout=120)
dom = r.stdout
i = dom.find('RESULT')
print(dom[i:dom.find('</pre>', i)] if i >= 0 else dom[:2000] + r.stderr[:1000])
