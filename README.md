# KÖLNER DOM — THE CATHEDRAL IS ALIVE

A 15-minute (900 s) projection-mapping show for a Gothic twin-tower cathedral facade, built in TouchDesigner.
Stone → cracks → skeleton → machinery → arteries → heart → roots → skin → neurons → eyes open → splats → particles → DNA → human → stone → reconstruction.
Every effect is generated from the architecture (masks, depth, edges), never from a flat rectangle.

> **Important honesty note.** There is no LiDAR / photogrammetry capture of the real Kölner Dom in this project. The "digital twin" is a
> **procedural stand-in** (two spired towers, nave gable, flèche, portals, lancets, a rose window, piers, statue niches, crockets, tracery).
> It is stylised, not a measured model of the real façade. Replace it with an authorised scan before projecting on the real building (see §6).

## 1. Run it

`KOELNER_DOM.toe` contains everything (the MCP bridge is bundled so Claude can drive TD live; you can ignore it).

To rebuild from source (Textport, Alt+T):

```python
exec(open(r'C:\Users\Utsav\koelner-dom\build_dom.py', encoding='utf-8').read())
```

It prints a `WARN` list (empty on TouchDesigner 2025.33230). The first build bakes the procedural twin to `twin/*.exr` (~40 s on an Intel iGPU);
later builds load those files. Set `KOELNER_QUALITY=low|medium|high` in the environment to choose the starting resolution.

Open the preview with the **OPEN OUTPUT WINDOW** pulse on `/project1/KOELNER_DOM/SHOW_CONTROL`. Output is a 720×1280 portrait master
(Non-Commercial TD caps resolution; raise `CW, CH` in the builder on a licensed copy).

## 2. Control (`/SHOW_CONTROL`)

* **MODE** `auto` (timeline writes the master parameters, so the UI mirrors the show) or `manual` (the parameters drive the building).
* **PLAYING / SHOW SPEED / SEEK + GO TO SEEK / RESTART / LOOP.** Speed ×8 lets you rehearse 15 minutes in two.
* **Cue buttons:** STONE 0 s · AWAKEN 95 · CRACK 176 · MACHINE 228 · HEART 362 · ROOTS 402 · NEURAL 455 · CONSCIOUS 566 · DISSOLVE 650 · DNA 775 · REBIRTH 826 · RECONSTRUCT 845 · SLEEP 880 · ENTER 594.
* **Master parameters:** BREATH, HEART_RATE, CRACK_GROWTH, MACHINE_REVEAL, BIOLOGY, ROOT_GROWTH, NEURAL_ACTIVITY, EYE_OPEN, EYE_TARGET (xy),
  CROWD_ENERGY, SPLAT_DISSOLVE, GRAVITY, TURBULENCE, RETURN_STRENGTH, VOLUMETRIC_INTENSITY, AUDIO_REACTIVITY, STRUCTURAL_STABILITY
  (TouchDesigner custom-parameter names are `Breath`, `Heartrate`, `Crackgrowth`, …).
* **QUALITY** low 360×640 / medium 540×960 / high 720×1280: rescales every per-frame layer live.
* Edit the story in `scripts/brain.py` (`K` keyframes, `STINGERS`, `SILENCE`, `SECTIONS`, `CUES`).

## 3. The 22 networks

| COMP | What it holds |
|---|---|
| `DOM_DIGITAL_TWIN` | twinA (height, windows, edges, solid), twinB (tower L/R, nave, roof), twinC (portals, columns, statues, ornaments), DEPTH_MAP, NORMAL_MAP, HIGH/LOW-RES projection mesh grids |
| `ARCH_MASKS` | the nine named masks TOWER_LEFT/RIGHT, CENTER, WINDOWS, PORTALS, COLUMNS, STATUES, ORNAMENTS, ROOF |
| `PHOTOGRAMMETRY` | ingest stubs (`scan_mesh`, `scan_pointcloud`) + notes. Empty: no scan available |
| `PROJECTOR_CALIBRATION` | table of virtual projectors (position, rotation, throw ratio, lens k1/k2, keystone corners, canvas region, edge blend). Placeholder values |
| `STONE_SHADER` | masonry, relief lighting, AO, shadows, edges, the opening-minute anomalies |
| `CRACK_ENGINE` | voronoi + masonry-joint fractures growing from window sills / portal feet / setbacks; white → amber → deep red; branching biased by the RD field |
| `MACHINERY` | parallax gears, rings, pistons, chains seen through the lens-shaped opening; softens into tissue with BIOLOGY |
| `SKELETON` | columns → vertebrae, arches → ribs, spire ridges / ornaments → tendons |
| `ARTERIES` | alternating up/down flow in every pier, kick-triggered pressure wave heart → arteries → columns → windows → towers |
| `HEART` | biomechanical Gothic heart (nested ogive ribs, veins, gilded rim, aorta) |
| `ROOTS` | 14 strands from the base up the piers with branching; ornament morphs into roots; wood → veins → neurons |
| `REACTION_DIFFUSION` | Gray-Scott, per-region feed/kill (towers coral, nave cells, windows worms, columns labyrinth, portals spots) + skin shader |
| `NEURONS` | nodes at architectural intersections, axons along the tracery, crowd-side stimulation, cascade, sync converging on the rose window |
| `EYES` | windows → iris-tracery → pupil → living eye; gaze = crowd, pupils dilate with crowd energy, blink, close in silence, open on impacts |
| `CROWD_VISION` | camera → 96×54 frame-difference "optical flow" (energy, left/centre/right, centroid) + binary silhouettes. No face detection |
| `AUDIO_ANALYSIS` | live band analysis (sub/bass/mid/high/transient/master) and a small generative score for demo mode |
| `PARTICLE_SIM` | 65,536 splats: baked "P_original" home positions, velocity + position sims |
| `GAUSSIAN_SPLATS` | instanced Gaussian billboards coloured from the stone; audience particles |
| `VOLUMETRICS` | radial light shafts from eyes / heart / the collapse, reversed during reconstruction |
| `CAMERA` | 3D render camera (drifts during the collapse) + the scale-illusion and enter-the-cathedral sequences |
| `SHOW_CONTROL` | brain, timeline, cues, master parameters, uniform texture |
| `OUTPUT_PROJECTORS` | composite stack, MASTER_OUT, two projector warps (keystone, lens, gamma-correct edge blend), preview window |

Convention: every facade shader takes `[ustate, twinA, twinB, twinC]` as inputs. `ustate` is a 24×1 float texture holding all show state, written
once per frame; its layout is documented at the top of `shaders/common.glsl`.

## 4. Section → implementation

01–02 twin + calibration tables · 03 stone enhancement + 4 anomalies (window blink, ornament shifts, shadow flips, column swells) ·
04 breath: 6.5 s cycle, depth-displacement spreading centre → towers → columns → windows, SUB adds structural breathing ·
05 eyes · 06 cracks · 07 nave slides open (stone read from further in), machine revealed · 08 bones · 09 BIOLOGY morphs the machine ·
10 arteries · 11 heart · 12 roots · 13 RD skin · 14–15 neurons, sync, pause, eyes open · 16 crowd tiers (sleep → track → vascular boost → neural
boost → destabilise) · 17 silhouettes dissolve into particles that rise through the piers · 18–21 splat separation (edges leak first, then statues,
ornaments, columns, windows), left tower then right tower blown away top-down, stability 1→0 with negative gravity, 20 s of zero-g stillness ·
22 DNA · 23 human built on the cathedral's proportions (arms = tower extensions, rose window = the mind; bones → vessels → nerves → skin) ·
24 human → stone · 25 reconstruction with `F_return = (P_original − P_current) × RETURN_STRENGTH`, classes returning in order
(silhouette → towers → columns → windows → statues → ornaments → fine stone), final snap · 26 audio mapping (SUB breath, BASS heart, MID
vascular, HIGH neural, TRANSIENT shockwave/eyes) · 27 volumetrics · 28 scale illusion (crack → canyon → vessel → neuron → lightning → pull-out)
· 29 enter-the-cathedral flight + recursion · 30 final sequence (blink, look, heartbeat, faint pulse, black).

## 5. What was verified, and what was not

**Verified live in TouchDesigner 2025.33230** (screenshots of the master output): the build (0 warnings), shader compilation, the baked twin,
stone + anomalies (88 s), iris-tracery eyes (162 s), cracks + opening + machine + bones (300 s), heart + arteries (380 s), skin + roots + neurons +
eyes + audience particles (500–580 s), canyon scale scene (207 s), several frames of the tunnel and its pull-out reveal (612–646 s), splat
transition, tower dissolution, collapse, DNA, human, human→stone, reconstruction and the final blink (656–890 s, played in real time),
cue jump, Seek/Goto, Quality switching, AUTO/MANUAL.

**Not verified:** sound (never heard; the live-analysis chain and the synth audio were built but not run), a real camera or microphone, the
vessel / neuron / lightning stages of the scale illusion, the eyes closing in real silence, anything on real projectors, the neural cascade
under heavy crowd input, and projector calibration (the table holds placeholders).

**Performance:** measured only on an Intel UHD 620 laptop GPU, where this TD session ran at roughly 10 fps at *low* quality (the same session ran ~20 fps
with every network disabled). Expect a dedicated GPU to be needed for 60 fps. 65k splats is also a deliberately light count; raise `NP` in the builder
(`256` → `512` = 262k) on stronger hardware.

**Known rough edges:** the reconstruction passes through a noisy, blobby stage before the details lock in; the crowd shadows are blunt;
the heart shafts and neuron/skin layers get busy in Act III; `neurons.glsl` and `eyes.glsl` are the most expensive layers.

## 6. Using a real scan

Bake your capture into three images and drop them over `twin/twinA.exr` (R height 0–1, G windows, B edges, A solid), `twinB.exr` (R left tower,
G right tower, B nave, A roof) and `twinC.exr` (R portals, G columns, B statues, A ornaments), same size as the canvas. Then re-run the builder; window and
eye positions are still taken from the table at the top of `shaders/common.glsl` (`WN`, `ROSE`), which you would also edit to match. For true splat
data replace the rejection-sampling in `shaders/home.glsl` with a texture of your splat centres.

## 7. Projection calibration

Fill the `PROJECTOR_CALIBRATION/projectors` table from measurements (throw ratio, position, lens k1/k2), then trim the keystone corners (`c00x…c11y`) against the real stone.
Kantan Mapper is not loaded by default (it adds 4,000+ operators): pulse **LOAD KANTAN MAPPER** on `SHOW_CONTROL` to load it from the palette.

## 8. Tools

`python tools/check_shaders.py` compiles every shader in WebGL2 (headless Chrome) behind a TouchDesigner shim.
It cannot see TouchDesigner-specific problems such as a shader reading an input that is not wired (that one bit us once; see `NO_TWIN` in `common.glsl`).

## 9. Hard-won TD notes

* A GLSL TOP with no inputs does not declare `sTD2DInputs`; guard with `NO_INPUTS`.
* One big procedural function called five times in a single shader froze TD; keep one evaluation per pass and bake static maps.
* Never let a material read a uniform by expression from the TOP that renders it (cook-dependency loop); set it from a script.
* The MCP bridge locates its modules relative to its `.tox`; keep `mcp_webserver_base.tox` + `modules/` next to the project.
* Parameter Execute callbacks run on the next frame, not synchronously after a Python parameter write.
