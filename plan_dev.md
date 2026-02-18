# Beauty Hyperobject Sequences — Development Plan

## Current State

A working web app (`beauty-hyperobject-sequences/`) that visualizes OEIS integer
sequences through 12 beauty dimensions, 12 canvas visualization modes, audio
sonification, and a simplex-noise particle cosmos background. Pure vanilla JS +
Python server, zero external dependencies.

### What Works
- **server.py** — HTTP server on port 8071 with OEIS proxy, caching, and retry logic
- **app.js** — Full state machine: search, load, dock, focus view, embedding, keyboard shortcuts
- **oeis.js** — OEIS client with fallback to seed data
- **beauty.js** — 12-dimensional beauty metric computation + embedding projection
- **viz.js** — 12 canvas visualization modes + mini-preview + radar + embedding scatter
- **cosmos.js** — Simplex noise particle flow field background
- **audio.js** — Web Audio sonification with waveform display
- **seeds.js** — 8 pre-cached sequences for offline fallback

### What's Broken / Missing

See "Phase 1: Bug Fixes" below.

---

## Phase 1: Bug Fixes (Critical)

### 1.1 OEIS null-response crash

**Problem:** The OEIS API returns a literal `null` JSON body when a search has no
results. `server.py` proxies this as-is. The client then does `data.results` on
JavaScript `null`, throwing:
```
Cannot read properties of null (reading 'results')
```

**Root Cause:** `json.loads("null")` returns Python `None`; `json.dumps(None)`
sends `"null"` back. Client `resp.json()` yields JS `null`.

**Fix (server-side):** In `server.py` `handle_search` and `handle_sequence`,
normalize `None` parsed results to `{"results": [], "count": 0}`.

**Fix (client-side):** In `oeis.js`, add `if (!resp.ok) throw` and `if (!data) return []`
guards before accessing `data.results`.

**Status:** FIXED in this branch.

**Files changed:**
- `beauty-hyperobject-sequences/server.py` — lines 64-68, 80-84
- `beauty-hyperobject-sequences/js/oeis.js` — lines 37-43, 68-70, 100-101

### 1.2 Non-OK HTTP responses parsed as JSON

**Problem:** When server returns 404/502, the response body is HTML. Calling
`resp.json()` on HTML throws a `SyntaxError` that masks the real problem.

**Fix:** Check `resp.ok` before parsing JSON in all three fetch methods
(`search`, `fetchSequence`, `fetchBFile`). Throw a descriptive error that
includes the HTTP status code.

**Status:** FIXED in this branch.

### 1.3 Missing favicon 404

**Problem:** Browsers auto-request `/favicon.ico`, which returns 404 from
`SimpleHTTPRequestHandler`. Harmless but noisy.

**Fix (optional):** Add a small favicon or a route that returns 204.

**Status:** Low priority. Not blocking.

---

## Phase 2: Robustness & UX

### 2.1 OEIS rate limiting / unavailability

OEIS has a 1 request/second soft limit. Currently the client fires parallel
requests (metadata + b-file) with no throttling.

**Tasks:**
- [ ] Add request queue with 1-second minimum interval in `server.py`
- [ ] Show user-friendly "OEIS is slow, using cached data" messages
- [ ] Expand `seeds.js` to cover all 34 `BEAUTIFUL_SEEDS` entries

### 2.2 Expand seed/offline data

Only 8 of the 34 curated seeds have offline data in `seeds.js`.

**Tasks:**
- [ ] Pre-cache all 34 seeds by running a one-time fetch script
- [ ] Store seed data as a separate JSON file generated at build time
- [ ] Include extended terms (b-file data) for key sequences

### 2.3 Error states in the UI

The app uses `whisper()` for transient messages but has no persistent error UI.

**Tasks:**
- [ ] Show inline message in search results when search fails
- [ ] Show retry button in focus view when sequence load fails
- [ ] Distinguish "not found" from "network error" in messaging

---

## Phase 3: Painting Engine

The generative painting engine was planned but its implementation was interrupted.
The idea: mathematical beauty metrics **paint** the interface — the visualization
is not a chart of the data but a painting made FROM the data.

### 3.1 `painting.js` — Generative painting module

**Concept:** Each beauty dimension drives a visual force:
- **Compressibility** → brush texture (smooth to noisy)
- **DeltaSignEntropy** → color palette temperature
- **GrowthDrama** → stroke energy / scale variation
- **ResidueStructure** → pattern tiling / grid alignment
- **Novelty** → palette diversity
- **SelfSimilarity** → fractal recursion depth
- **HarmonicContent** → color harmony (complementary vs analogous)
- **DramaticArc** → compositional tension (placement, density)
- **CompositionType** → layout algorithm (steelyard, spiral, etc.)
- **Connectedness** → layering / transparency
- **WaveMechanics** → rhythm / stroke spacing
- **RecursionDepth** → nesting / detail level

**Tasks:**
- [ ] Create `js/painting.js` module with `PaintingEngine` class
- [ ] Implement base brush system (stamp, stroke, drip, splatter)
- [ ] Map beauty dimensions to painting parameters
- [ ] Integrate with app.js as a 13th visualization mode or overlay
- [ ] Add animation: paintings that evolve over time as more terms load

### 3.2 Canvas composition techniques

**Tasks:**
- [ ] Implement blend modes (multiply, screen, overlay) via manual pixel ops
- [ ] Add noise-driven texture layers
- [ ] Create color palette generator from beauty hue + harmonic content
- [ ] Implement layered rendering pipeline (background → mid → detail → glow)

---

## Phase 4: Polish & Features

### 4.1 Sequence comparison

- [ ] Side-by-side beauty radar overlays for 2+ sequences
- [ ] Difference visualization (how do Fibonacci and Primes differ in beauty?)
- [ ] "Beauty distance" metric between sequences

### 4.2 Embedding space interactivity

- [ ] Clickable dots in embedding view to load/focus sequences
- [ ] Tooltip on hover with sequence name + mini preview
- [ ] Zoom/pan in embedding space
- [ ] Cluster visualization (color by dominant beauty dimension)

### 4.3 Audio improvements

- [ ] Multiple sonification modes (melodic, rhythmic, ambient)
- [ ] Dual-sequence sonification (counterpoint)
- [ ] Export audio as WAV

### 4.4 Export & sharing

- [ ] Export current visualization as PNG/SVG
- [ ] Export painting as high-resolution image
- [ ] Shareable URL with sequence ID + viz mode encoded

### 4.5 Performance

- [ ] Web Worker for beauty computation on large sequences
- [ ] Offscreen canvas for heavy visualizations
- [ ] Virtual scroll for large search result sets

---

## Architecture Reference

```
index.html
  └─ js/app.js (state machine, event binding, view transitions)
       ├─ js/cosmos.js    (simplex noise particle background)
       ├─ js/oeis.js      (OEIS API client + fallback)
       │   └─ js/seeds.js (offline sequence data)
       ├─ js/beauty.js    (12-dim beauty computation)
       ├─ js/viz.js       (12 canvas viz modes + radar + embedding)
       ├─ js/audio.js     (Web Audio sonification)
       └─ js/painting.js  (planned: generative painting engine)

server.py (port 8071)
  ├─ Static file server (index.html, CSS, JS)
  ├─ GET /api/search?q=...       → OEIS search proxy
  ├─ GET /api/sequence/<ID>      → OEIS sequence proxy
  └─ GET /api/bfile/<ID>?n=...   → OEIS b-file proxy + parser
```

### Key data flow
1. User searches → `app.js` → `oeis.js` → `server.py` → OEIS (or seeds fallback)
2. Terms returned → `beauty.js` computes 12 dimensions + hue + composition type
3. Beauty drives: `viz.js` rendering, `cosmos.js` color influence, `audio.js` mapping
4. User navigates via dock orbs, keyboard shortcuts, cross-reference tags

### Files summary

| File | Lines | Purpose |
|------|-------|---------|
| `server.py` | ~185 | HTTP server + OEIS proxy with caching |
| `index.html` | ~82 | Single-page app shell |
| `style.css` | ~400 | Dark glass aesthetic, layout |
| `js/app.js` | ~609 | Main orchestration |
| `js/oeis.js` | ~235 | OEIS client + seeds fallback |
| `js/beauty.js` | ~576 | 12-dimensional beauty analysis |
| `js/viz.js` | ~850 | 12 visualization modes |
| `js/cosmos.js` | ~239 | Particle flow background |
| `js/audio.js` | ~194 | Sequence sonification |
| `js/seeds.js` | ~140 | Offline fallback data |

---

## Running

```bash
cd beauty-hyperobject-sequences
python3 server.py
# Open http://localhost:8071
```

No dependencies. Python 3.6+ only.
