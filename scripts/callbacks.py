"""Callback bodies embedded by the builder. Sections are split on lines that start with '#### name'."""

#### ustate_top
import numpy as np
def onCook(scriptOp):
    b = op('__ROOT__/SHOW_CONTROL/brain').module
    scriptOp.copyNumpyArray(b.UST.astype(np.float32))

#### crowd_top
import numpy as np
def onCook(scriptOp):
    b = op('__ROOT__/SHOW_CONTROL/brain').module
    scriptOp.copyNumpyArray(b.TEX['__KEY__'].astype(np.float32))

#### frame_exec
_errs = [0]
def onFrameStart(frame):
    try:
        op('__ROOT__/SHOW_CONTROL/brain').module.tick()
    except Exception as e:
        _errs[0] += 1
        if _errs[0] < 6:
            import traceback
            print('KOELNER DOM tick error:', e)
            traceback.print_exc()
    return

#### par_exec
def onPulse(par):
    b = op('__ROOT__/SHOW_CONTROL/brain').module
    n = par.name
    if n == 'Goto':
        b.seek(par.owner.par.Seek.eval())
    elif n == 'Loadkantan':
        print('Kantan:', b.load_kantan())
    elif n == 'Restart':
        b.seek(0)
    elif n == 'Openwindow':
        w = op('__ROOT__/OUTPUT_PROJECTORS/window')
        if w is not None:
            w.par.winopen.pulse()
    elif n in b.CUES_PAR:
        b.jump(b.CUES_PAR[n])
    return

def onValueChange(par, prev):
    if par.name == 'Quality':
        op('__ROOT__/SHOW_CONTROL/brain').module.apply_quality(str(par.eval()))
    return
