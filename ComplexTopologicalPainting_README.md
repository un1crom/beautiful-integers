# Complex Topological Painting — Companion Notes

## Requirements
- Mathematica 13+ (for `ComplexPlot`, `NetChain`, `DedekindEta`)
- Evaluate sequentially or as a full script: `Get["ComplexTopologicalPainting.wl"]`

## The Four Movements

### Movement I: The Complex Plane as Canvas
Five domain-colored paintings built from analytically continued functions:

| Painting | Function | Why it's surprising |
|----------|----------|-------------------|
| Zeta-Gamma Interference | ζ(Γ(z)) | Γ's poles at non-positive integers feed into ζ's critical strip — creates cascading singularity interference |
| Modular Dream | η(z)²⁴ / η(2z)¹² | Modular form with SL₂(ℤ) symmetry — self-similar at every scale of the upper half-plane |
| Arithmetic Topology | ζ(z) · ℘'(z; 2, -1) | Zeta's arithmetic structure meets Weierstrass's doubly-periodic topology |
| Polylogarithmic Spiral | Li_{1/2+3i}(z) | **Complex-order** polylogarithm — the order itself is complex, creating logarithmic spirals in the phase portrait |
| Grand Composition | ζ(z)·Li_{1/2+3i}(z) / (Γ(z) + η(z/4+i)⁶) | All singularity types at once: poles, branch cuts, modular cusps, essential singularities |

### Movement II: Image Filters & Convolutions
Treats the paintings as images and applies:
- Standard: Gaussian multiscale, Laplacian of Gaussian, edge detection, derivative filters
- Custom kernels: emboss, sharpen, difference-of-Gaussians "singularity detector"
- Gabor filter bank at 7 orientations
- Morphological gradient, total variation denoising
- Fourier power spectrum + high-pass filtering

### Movement III: Neural Networks
Two architectures trained on 32×32 patches extracted from all paintings + filtered versions:

- **Classifier** (4 conv blocks → dense → 7-class softmax): learns to identify which topological family a patch came from
- **Autoencoder** (encoder → 8-channel bottleneck → decoder): learns a compressed representation of the topology

### Movement IV: Weight Visualization
- First-layer filters visualized as images (raw topology detectors)
- Filter correlation matrix (cosine similarity between deeper filters)
- Weight distribution histogram
- **Grand Weight Painting**: all weights from all layers arranged as a single image — the network's self-portrait
- t-SNE of autoencoder latent space, colored by source painting
- Autoencoder encoder filters

## Output Files
All exported as high-resolution PNGs to the working directory.
