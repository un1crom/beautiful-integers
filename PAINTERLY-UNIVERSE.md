# Painterly Beauty-Hunting Universe

## Core Direction
The interface is not a dashboard. The interface is the painting.
Every sequence appears first as a large procedural poster, then as a living actor inside a shared aesthetic universe.
No blue links, no corporate layout, no menu-driven shell.
Navigation is done by panning through painted space, zooming into clusters, and selecting motifs directly from visual matter.

## Experience Model
1. Sequence Poster Wall
Each OEIS sequence has one canonical painterly poster (`Axxxxxx-poster.png`) generated from its own terms, dynamics, and composition profile.

2. Beauty Landscape
All sequences are embedded into a 2D/3D manifold (UMAP, t-SNE, or hyperbolic layout) using a rich beauty vector.
Clusters become beauty genres. Sparse zones become candidate "missing sequence" territories.

3. Transformation Constellations
Each sequence links to its transformed family (inverse, complement, reversal, Mobius-like transforms, residue transforms).
Families are rendered as constellations with implication and negation edges.

4. Sonic Observatory
Each sequence has a sound identity with melody, harmony, rhythm, and timbre layers.
Computational traces (runtime/memory/byte pattern surrogates) become secondary sonic channels.

5. Drama Theater
Growth, jumps, recurrence, and turning points are staged as motion scenes.
Narrative arcs are treated like acts: exposition, escalation, rupture, resolution.

## Beauty Vector (v2)
Build one vector per sequence and use it for ranking, clustering, and landscape layout.

- Structural: compressibility, delta entropy, residue structure, novelty.
- Composition: Payne-guide alignment + anti-pattern penalties.
- Connectivity: cross-reference degree, PageRank, k-core, domain spread.
- Pattern Depth: multiscale autocorrelation depth, recurrence texture complexity, fractal indicators.
- Musicality: interval entropy, tonal center persistence, cadence-like return score, run-length rhythm stability.
- Drama: volatility arc, change-point segmentation score, climax intensity.
- Recursion/Wave: recurrence order detectability, oscillation index, phase isotropy/ring behavior.
- Computation Signature: operation trace entropy, per-term runtime gradient, memory-profile motifs.
- Transformation Robustness: how beauty changes under transform family.

## Painterly Visual Grammar
Map analysis directly to paint operations.

- Steelyard: asymmetric mass blocks plus thin counterweight traces.
- Balanced scales: bilateral value balancing with subtle entropy offsets.
- S-curve: layered spline brush streams.
- Radiating lines: radial edge bursts from detected anchors.
- Tunnel: edge-density framing and center pullback.
- Group mass: clustered pigment accumulation from dominant-cell occupancy.
- Anti-patterns: equal spacing and centered-horizon penalties damp symmetry and over-regularity.

## Engine Architecture
1. Ingest Layer
OEIS JSON + internal fields + b-files + cross-reference graph extraction.

2. Analysis Layer
Compute beauty vectors and transformation families.
Persist feature tables and graph structure for embedding runs.

3. Render Layer
- Poster renderer (high-res stills).
- Landscape renderer (embedding canvas).
- Motion renderer (drama + wave scenes).
- Sonification renderer (audio exports and reactive sound mappings).

4. Universe Runtime
Single full-screen canvas experience with painterly transitions and direct manipulation.
No conventional panel chrome.

## Immediate Build Steps
1. Keep generating per-sequence painterly posters in the existing Wolfram pipeline.
2. Add OEIS cross-reference parser and graph metrics into `beauty_profile`.
3. Compute beauty vectors for a larger catalog (100-1000 sequences).
4. Generate first embedding map image and cluster labels.
5. Add transformation families and relationship edges.
6. Add audio export per sequence and a clustered "choir" render.

## Output Artifacts (Target)
- `outputs/Axxxxxx-poster.png`
- `outputs/summary.json` with `beauty_profile` vector fields and transformation links
- `outputs/beauty-landscape.png` and animation variants
- `outputs/sequence-audio/Axxxxxx.wav`
- `outputs/universe-manifest.json` for interactive runtime
