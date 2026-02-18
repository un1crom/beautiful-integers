#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════
  "Integer Strata"  —  A painting from the arithmetic of dreams
═══════════════════════════════════════════════════════════════════

Five OEIS sequences, computed locally to 2000+ terms each, are
layered through modular arithmetic, logarithmic scaling, phase-space
embedding, cellular automaton evolution, and Fourier spectra to
produce a single high-resolution painting (5400 × 3600 px).

Sequences used:
  A006577  Collatz stopping times     — chaotic with hidden structure
  A005132  Recamán's sequence          — structured aperiodic beauty
  A002487  Stern's diatomic series     — fractal self-similarity
  A010060  Thue-Morse sequence         — substitution anti-fractal
  A001223  Prime gaps                  — the heartbeat of the primes

Layers (bottom → top):
  1. Cellular automaton substrate     (Collatz → Rule 30, the chaotic rule)
  2. Modular residue color field      (Stern diatomic mod primes → HSV)
  3. Phase-space flow curves          (Recamán delay embedding)
  4. Mountain silhouette horizon      (Collatz log-scaled profile)
  5. Spectral aurora                  (FFT of Collatz stopping times)
  6. Prime-gap star field             (prime gaps as luminous points)
  7. Recurrence web                   (Recamán near-returns)
"""

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy.ndimage import gaussian_filter, gaussian_filter1d
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.collections import LineCollection
import math
import colorsys
import os
import io

# ─── Configuration ────────────────────────────────────────────────
WIDTH  = 5400
HEIGHT = 3600
OUTPUT_DIR = "/home/user/beautiful-integers/outputs"
OUTPUT_FILE = os.path.join(OUTPUT_DIR, "integer_strata_painting.png")


# ═══════════════════════════════════════════════════════════════════
#  SECTION 1: SEQUENCE GENERATORS (all computed locally)
# ═══════════════════════════════════════════════════════════════════

def gen_collatz_stopping_times(count):
    """A006577: Collatz stopping times for n = 0..count-1."""
    result = []
    for n in range(count):
        if n <= 1:
            result.append(0)
            continue
        steps, x = 0, n
        while x != 1:
            x = x // 2 if x % 2 == 0 else 3 * x + 1
            steps += 1
        result.append(steps)
    return np.array(result)


def gen_recaman(count):
    """A005132: Recamán's sequence."""
    a = [0]
    seen = {0}
    for n in range(1, count):
        c = a[-1] - n
        if c > 0 and c not in seen:
            a.append(c)
        else:
            a.append(a[-1] + n)
        seen.add(a[-1])
    return np.array(a)


def gen_stern_diatomic(count):
    """A002487: Stern's diatomic series."""
    a = [0, 1]
    while len(a) < count:
        n = len(a) // 2
        a.append(a[n] if len(a) % 2 == 0 else a[n] + a[n + 1])
    return np.array(a[:count])


def gen_thue_morse(count):
    """A010060: Thue-Morse sequence."""
    return np.array([bin(n).count('1') % 2 for n in range(count)])


def gen_prime_gaps(count):
    """A001223: Differences between consecutive primes."""
    limit = max(count * 20, 50000)
    sieve = np.ones(limit, dtype=bool)
    sieve[0] = sieve[1] = False
    for i in range(2, int(limit**0.5) + 1):
        if sieve[i]:
            sieve[i*i::i] = False
    primes = np.where(sieve)[0]
    return np.diff(primes)[:count]


# ═══════════════════════════════════════════════════════════════════
#  SECTION 2: MATHEMATICAL TRANSFORMS
# ═══════════════════════════════════════════════════════════════════

def rule30_ca(initial_row, steps):
    """Evolve binary CA under Rule 30 (Wolfram's chaotic rule).
    Fully vectorized with numpy."""
    w = len(initial_row)
    grid = np.zeros((steps, w), dtype=np.uint8)
    grid[0] = initial_row.astype(np.uint8) & 1
    # Rule 30: new = left XOR (center OR right)
    for t in range(1, steps):
        left   = np.roll(grid[t-1], 1)
        center = grid[t-1]
        right  = np.roll(grid[t-1], -1)
        grid[t] = left ^ (center | right)
    return grid


def compute_fft_magnitudes(seq, smooth_sigma=3):
    """Compute smoothed, normalized FFT magnitude spectrum."""
    fft = np.fft.rfft(seq.astype(float))
    mags = np.log1p(np.abs(fft))
    mags = gaussian_filter1d(mags, sigma=smooth_sigma)
    mx = mags.max()
    return mags / mx if mx > 0 else mags


# ═══════════════════════════════════════════════════════════════════
#  SECTION 3: COLOR UTILITIES
# ═══════════════════════════════════════════════════════════════════

def lerp_color(c1, c2, t):
    t = np.clip(t, 0.0, 1.0)
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))


def make_colormap(colors_rgb, n=256):
    """Create an Nx3 uint8 lookup table from a list of RGB tuples."""
    n_colors = len(colors_rgb)
    lut = np.zeros((n, 3), dtype=np.uint8)
    for i in range(n):
        t = i / (n - 1)
        idx = t * (n_colors - 1)
        lo = int(idx)
        hi = min(lo + 1, n_colors - 1)
        frac = idx - lo
        for c in range(3):
            lut[i, c] = int(colors_rgb[lo][c] * (1 - frac) + colors_rgb[hi][c] * frac)
    return lut


def apply_colormap(values, cmap_lut):
    """Map normalized float array [0,1] → RGB via lookup table."""
    indices = np.clip((values * 255).astype(int), 0, 255)
    return cmap_lut[indices]


# ═══════════════════════════════════════════════════════════════════
#  SECTION 4: PAINTING LAYERS (vectorized numpy operations)
# ═══════════════════════════════════════════════════════════════════

def render_background(w, h):
    """Deep cosmic gradient background."""
    print("  Background gradient...")
    canvas = np.zeros((h, w, 3), dtype=np.float64)
    # Vertical gradient: slightly lighter indigo at top → deep at bottom
    t = np.linspace(0, 1, h).reshape(-1, 1)
    # Also add subtle horizontal variation
    tx = np.linspace(0, 1, w).reshape(1, -1)
    # Base: deep indigo
    canvas[:, :, 0] = 10 + (1 - t) * 15 + tx * 3    # R
    canvas[:, :, 1] = 8  + (1 - t) * 12 + tx * 2     # G
    canvas[:, :, 2] = 32 + (1 - t) * 25 + tx * 5     # B
    return canvas


def render_ca_layer(collatz, thue_morse, w, h):
    """Layer 1: Rule 30 CA seeded by Collatz stopping times modulated by Thue-Morse.
    Creates the famous chaotic triangular patterns. Returns float64 RGB array."""
    print("  Cellular automaton (Rule 30, Collatz-seeded)...")

    # Build initial row: Collatz values mod 2, XOR with Thue-Morse for richness
    ca_width = 2700  # cells (will be upscaled to canvas width)
    n = min(len(collatz), ca_width)
    init = np.zeros(ca_width, dtype=np.uint8)
    # Map Collatz stopping times into initial conditions
    indices = np.linspace(0, len(collatz) - 1, ca_width).astype(int)
    init = (collatz[indices] % 2).astype(np.uint8)
    # Modulate with Thue-Morse
    tm_indices = np.linspace(0, len(thue_morse) - 1, ca_width).astype(int)
    init ^= thue_morse[tm_indices].astype(np.uint8)

    # Evolve CA
    ca_height = 1800
    grid = rule30_ca(init, ca_height)

    # Colorize: state 0 → deep indigo, state 1 → visible teal-violet
    # Increase contrast between states for visible CA texture
    result = np.zeros((ca_height, ca_width, 3), dtype=np.float64)
    result[grid == 0, 0] = 10   # dark cell R
    result[grid == 0, 1] = 8    # dark cell G
    result[grid == 0, 2] = 30   # dark cell B
    result[grid == 1, 0] = 28   # light cell R
    result[grid == 1, 1] = 38   # light cell G — teal
    result[grid == 1, 2] = 68   # light cell B — rich blue

    # Position-dependent color shift for depth
    y_grid = np.linspace(0, 1, ca_height).reshape(-1, 1)
    x_grid = np.linspace(0, 1, ca_width).reshape(1, -1)
    result[:, :, 0] += grid * (y_grid * 10 + x_grid * 6)   # warm towards bottom-right
    result[:, :, 1] += grid * ((1 - y_grid) * 8)             # greener towards top
    result[:, :, 2] += grid * ((1 - x_grid) * 8)             # bluer towards left

    # Resize to canvas dimensions using PIL
    img = Image.fromarray(np.clip(result, 0, 255).astype(np.uint8))
    img = img.resize((w, h), Image.LANCZOS)
    return np.array(img).astype(np.float64)


def render_modular_field(stern, w, h):
    """Layer 2: Modular residue color field.
    Maps Stern diatomic values mod primes to HSV → creates stained glass shimmer.
    Returns float64 RGBA (4 channels, alpha as float 0-1)."""
    print("  Modular residue color field (Stern diatomic)...")

    # Create a grid of Stern diatomic values
    cell_size = 30  # pixels per cell (smaller = finer texture when upscaled)
    cols = w // cell_size + 1
    rows = h // cell_size + 1

    # Map grid cells to Stern sequence values
    idx = np.arange(rows * cols) % len(stern)
    vals = stern[idx].reshape(rows, cols).astype(float)

    # HSV from modular arithmetic
    hue = (vals % 7) / 7.0
    sat = 0.4 + 0.45 * ((vals % 11) / 10.0)
    val = 0.25 + 0.30 * ((vals % 13) / 12.0)

    # Convert HSV to RGB (vectorized)
    rgb = np.zeros((rows, cols, 3), dtype=np.float64)
    for gy in range(rows):
        for gx in range(cols):
            r, g, b = colorsys.hsv_to_rgb(hue[gy, gx], sat[gy, gx], val[gy, gx])
            rgb[gy, gx] = [r * 255, g * 255, b * 255]

    # Upscale to canvas size with interpolation
    img = Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8))
    img = img.resize((w, h), Image.LANCZOS)
    field = np.array(img).astype(np.float64)

    # Create alpha channel with vertical fade (less in sky, more in ground)
    alpha = np.full((h, w), 0.18, dtype=np.float64)
    # Fade out in the upper 40% so modular field doesn't compete with aurora
    y_fade = np.linspace(0, 1, h).reshape(-1, 1)
    alpha *= np.clip(y_fade * 2.0, 0.05, 1.0)  # minimal at top, full below middle

    return field, alpha


def render_phase_flow_matplotlib(recaman, w, h):
    """Layer 3: Phase-space flow curves from Recamán's sequence.
    Uses matplotlib for anti-aliased rendering with colormaps.
    Returns a float64 RGBA numpy array."""
    print("  Phase-space flow curves (Recamán, matplotlib)...")

    dpi = 100
    fig_w, fig_h = w / dpi, h / dpi
    fig, ax = plt.subplots(figsize=(fig_w, fig_h), dpi=dpi)
    fig.patch.set_alpha(0)
    ax.set_xlim(0, w)
    ax.set_ylim(h, 0)
    ax.axis('off')
    ax.set_position([0, 0, 1, 1])

    # Multiple delay embeddings
    taus = [1, 2, 5, 11, 23]
    alpha_levels = [0.35, 0.28, 0.22, 0.16, 0.10]
    width_levels = [2.5, 2.0, 1.5, 1.2, 0.8]

    for tau_idx, tau in enumerate(taus):
        n = len(recaman) - tau
        if n < 10:
            continue

        x_raw = recaman[:n].astype(float)
        y_raw = recaman[tau:tau+n].astype(float)

        # Log-scale to compress range, then map to canvas
        lx = np.log1p(np.abs(x_raw)) * np.sign(x_raw + 0.001)
        ly = np.log1p(np.abs(y_raw)) * np.sign(y_raw + 0.001)

        lx_min, lx_max = lx.min(), lx.max()
        ly_min, ly_max = ly.min(), ly.max()
        lx_range = lx_max - lx_min if lx_max > lx_min else 1
        ly_range = ly_max - ly_min if ly_max > ly_min else 1

        margin = 150
        cx = margin + (lx - lx_min) / lx_range * (w - 2 * margin)
        cy = margin + (ly - ly_min) / ly_range * (h - 2 * margin)

        # Build line segments for LineCollection
        points = np.column_stack([cx, cy]).reshape(-1, 1, 2)
        segments = np.concatenate([points[:-1], points[1:]], axis=1)

        # Color by sequence index: teal → gold → rose → crimson
        t = np.linspace(0, 1, len(segments))

        # Custom colormap: teal → gold → rose
        from matplotlib.colors import LinearSegmentedColormap
        cmap_colors = [
            (46/255, 196/255, 182/255),     # teal
            (80/255, 200/255, 140/255),      # teal-green
            (212/255, 165/255, 116/255),     # gold
            (230/255, 100/255, 130/255),     # rose
            (193/255, 41/255, 46/255),       # crimson
        ]
        cmap = LinearSegmentedColormap.from_list('flow', cmap_colors)

        lc = LineCollection(segments, cmap=cmap, norm=plt.Normalize(0, 1))
        lc.set_array(t)
        lc.set_linewidth(width_levels[tau_idx])
        lc.set_alpha(alpha_levels[tau_idx])
        ax.add_collection(lc)

    # Render to numpy array
    fig.canvas.draw()
    buf = fig.canvas.buffer_rgba()
    flow_img = np.asarray(buf).copy()
    plt.close(fig)

    # flow_img is (h, w, 4) uint8 RGBA
    return flow_img.astype(np.float64)


def render_mountain(collatz, w, h):
    """Layer 4: Mountain silhouette from Collatz stopping times.
    Bold horizon line at golden ratio position with gradient fill.
    Fully vectorized. Returns float64 RGB array and float64 alpha array."""
    print("  Collatz mountain silhouette...")

    horizon_y = int(h * 0.382)

    # Build mountain profile from Collatz stopping times
    profile = np.log1p(collatz.astype(float))
    mx = profile.max()
    if mx > 0:
        profile = profile / mx

    # Multi-scale smoothing for natural mountain feel
    smooth1 = gaussian_filter1d(profile, sigma=5)
    smooth2 = gaussian_filter1d(profile, sigma=25)
    smooth3 = gaussian_filter1d(profile, sigma=80)
    combined = 0.3 * smooth1 + 0.4 * smooth2 + 0.3 * smooth3

    # Stretch to canvas width
    x_idx = np.linspace(0, len(combined) - 1, w)
    mountain = np.interp(x_idx, np.arange(len(combined)), combined)

    amplitude = 500
    fill_depth = 180

    # Peak y-positions for each column
    peak_y = np.clip((horizon_y - mountain * amplitude).astype(int), 0, h - 1)
    fill_bottom = min(horizon_y + fill_depth, h)

    # Create coordinate grids
    y_arr = np.arange(h).reshape(-1, 1)  # (h, 1)
    x_arr = np.arange(w).reshape(1, -1)  # (1, w)
    peak_row = peak_y.reshape(1, -1)     # (1, w)

    # Mountain body mask: peak_y <= y < fill_bottom
    body_mask = (y_arr >= peak_row) & (y_arr < fill_bottom)
    above_horizon = (y_arr < horizon_y) & body_mask
    below_horizon = (y_arr >= horizon_y) & body_mask

    rgb = np.zeros((h, w, 3), dtype=np.float64)
    alpha = np.zeros((h, w), dtype=np.float64)

    mtn_top = np.array([40, 28, 62])
    mtn_base = np.array([22, 16, 42])

    # Above horizon: gradient from peak to horizon
    depth_above = np.clip((y_arr - peak_row).astype(float) /
                          np.maximum(1, (horizon_y - peak_row).astype(float)), 0, 1)
    for c in range(3):
        rgb[:, :, c] = np.where(above_horizon,
                                mtn_top[c] * (1 - depth_above) + mtn_base[c] * depth_above,
                                rgb[:, :, c])
    alpha = np.where(above_horizon, 0.88 * (1 - depth_above * 0.3), alpha)

    # Below horizon: fade out
    depth_below = np.clip((y_arr - horizon_y).astype(float) /
                          max(1, fill_bottom - horizon_y), 0, 1)
    for c in range(3):
        rgb[:, :, c] = np.where(below_horizon, mtn_base[c] * (1 - depth_below), rgb[:, :, c])
    alpha = np.where(below_horizon, 0.65 * (1 - depth_below), alpha)

    # Ridge line glow (vectorized)
    ridge_teal = np.array([46, 196, 182], dtype=np.float64)
    ridge_gold = np.array([212, 165, 116], dtype=np.float64)
    t_x = np.linspace(0, 1, w)
    ridge_color = ridge_teal[np.newaxis, :] * (1 - t_x[:, np.newaxis]) + \
                  ridge_gold[np.newaxis, :] * t_x[:, np.newaxis]  # (w, 3)

    glow_radius = 7
    for dy in range(-glow_radius, glow_radius + 1):
        y_pos = np.clip(peak_y + dy, 0, h - 1)
        glow = np.maximum(0, 1 - abs(dy) / float(glow_radius)) ** 1.5
        for c in range(3):
            rgb[y_pos, np.arange(w), c] = (ridge_color[:, c] * glow +
                rgb[y_pos, np.arange(w), c] * (1 - glow))
        alpha[y_pos, np.arange(w)] = np.maximum(alpha[y_pos, np.arange(w)], glow * 0.92)

    return rgb, alpha


def render_aurora(collatz, w, h):
    """Layer 5: Spectral aurora from FFT of Collatz stopping times.
    Bold, colorful bands in the top portion. Fully vectorized.
    Returns float64 RGB array and float64 alpha array."""
    print("  Spectral aurora (FFT of Collatz, vectorized)...")

    # Multiple FFT windows for richer structure
    fft1 = compute_fft_magnitudes(collatz[:2000], smooth_sigma=2)
    fft2 = compute_fft_magnitudes(collatz[500:2500], smooth_sigma=5)

    aurora_bottom = int(h * 0.38)  # extend aurora region slightly

    # Aurora colormap — rich saturated jewel tones
    aurora_cmap = make_colormap([
        (20, 8, 55),       # deep indigo
        (80, 30, 130),     # rich violet
        (46, 180, 200),    # bright teal
        (30, 220, 140),    # emerald green
        (180, 200, 60),    # chartreuse
        (255, 200, 100),   # warm gold
    ])

    # Build magnitude array for all x positions
    x_arr = np.arange(w)
    fi1 = (x_arr * len(fft1) // w) % len(fft1)
    fi2 = (x_arr * len(fft2) // w) % len(fft2)
    mag_x = 0.6 * fft1[fi1] + 0.4 * fft2[fi2]  # (w,)

    # Build 2D coordinate grid for aurora region
    y_arr = np.arange(aurora_bottom)
    peak_y = aurora_bottom * 0.25

    # 2D distance from peak (y_arr: rows, mag_x: cols)
    dist = np.abs(y_arr[:, np.newaxis] - peak_y) / max(1, aurora_bottom)  # (aurora_bottom, w)
    envelope = mag_x[np.newaxis, :] * np.exp(-dist * dist * 6)  # wider bands

    # Wave modulation (2D)
    xx = x_arr[np.newaxis, :].astype(float)  # (1, w)
    yy = y_arr[:, np.newaxis].astype(float)  # (aurora_bottom, 1)
    mm = mag_x[np.newaxis, :]                 # (1, w)

    wave1 = 0.5 + 0.5 * np.sin(xx * 0.008 + yy * 0.03 + mm * 15)
    wave2 = 0.5 + 0.5 * np.sin(xx * 0.003 - yy * 0.02 + mm * 8)
    wave3 = 0.5 + 0.5 * np.sin(xx * 0.015 + yy * 0.008 + mm * 5)
    intensity = envelope * (0.3 + 0.3 * wave1 + 0.2 * wave2 + 0.2 * wave3)

    # Color from magnitude + vertical shift
    y_shift = yy / aurora_bottom
    color_idx = np.clip(((mm + y_shift * 0.25) * 255).astype(int), 0, 255)

    rgb = np.zeros((h, w, 3), dtype=np.float64)
    alpha = np.zeros((h, w), dtype=np.float64)

    # Color by HORIZONTAL position (creates rainbow bands like real aurora)
    # FFT magnitude only controls intensity/alpha, not hue
    x_color_idx = np.clip((xx / w * 255).astype(int), 0, 255)  # (1, w)
    # Modulate the hue position with FFT magnitude for subtle variation
    combined_idx = np.clip((x_color_idx * 0.7 + color_idx * 0.3).astype(int), 0, 255)

    for c in range(3):
        rgb[:aurora_bottom, :, c] = aurora_cmap[combined_idx, c] * (intensity > 0.01)
    alpha[:aurora_bottom] = np.clip(intensity * 1.6, 0, 0.65)

    # Soft Gaussian blur on alpha for smoother aurora edges
    alpha[:aurora_bottom] = gaussian_filter(alpha[:aurora_bottom], sigma=3)

    return rgb, alpha


def render_stars(prime_gaps, collatz, w, h):
    """Layer 6: Star field from prime gaps.
    Returns an RGBA PIL Image."""
    print("  Prime-gap star field...")

    img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    n_stars = min(len(prime_gaps), 1800)
    max_gap = float(prime_gaps[:n_stars].max())

    cum = np.cumsum(prime_gaps[:n_stars].astype(float))
    cum_max = cum[-1]

    for i in range(n_stars):
        x = int((cum[i] / cum_max) * (w - 200) + 100)
        ci = int(cum[i]) % len(collatz)
        yv = collatz[ci] if ci < len(collatz) else 0
        y = int((yv % h) * 0.85 + h * 0.075)

        gap = float(prime_gaps[i])
        brightness = 0.2 + 0.8 * (gap / max_gap)
        radius = max(1, int(1 + (gap / max_gap) * 8))

        # Color coding by gap magnitude
        if gap > max_gap * 0.6:
            color = lerp_color((255, 200, 100), (230, 80, 80),
                             (gap / max_gap - 0.6) / 0.4)
        elif gap > max_gap * 0.3:
            color = lerp_color((200, 230, 255), (46, 196, 182),
                             (gap / max_gap - 0.3) / 0.3)
        else:
            color = lerp_color((40, 38, 70), (200, 210, 230), brightness * 0.7)

        # Outer glow
        gr = radius * 5
        draw.ellipse([x-gr, y-gr, x+gr, y+gr],
                     fill=color + (int(35 * brightness),))
        # Middle glow
        mr = radius * 3
        draw.ellipse([x-mr, y-mr, x+mr, y+mr],
                     fill=color + (int(100 * brightness),))
        # Core
        cr = max(radius, 2)
        draw.ellipse([x-cr, y-cr, x+cr, y+cr],
                     fill=color + (int(240 * brightness),))
        # Hot center for bright stars
        if brightness > 0.4:
            draw.ellipse([x-1, y-1, x+1, y+1],
                         fill=(255, 252, 240, int(255 * brightness)))

    return img


def render_recurrence_web(recaman, w, h):
    """Gossamer recurrence web using matplotlib for clean lines."""
    print("  Recurrence web (Recamán near-returns)...")

    img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    n = min(len(recaman), 1200)
    seq = recaman[:n]
    log_seq = np.log1p(np.abs(seq).astype(float))
    seq_max = log_seq.max() if log_seq.max() > 0 else 1

    threshold = seq_max * 0.025
    count = 0

    for i in range(0, n, 2):
        for j in range(i + 8, min(i + 300, n), 2):
            if abs(log_seq[i] - log_seq[j]) < threshold:
                x0 = int(i / n * w)
                y0 = int(log_seq[i] / seq_max * (h * 0.55) + h * 0.22)
                x1 = int(j / n * w)
                y1 = int(log_seq[j] / seq_max * (h * 0.55) + h * 0.22)

                t = (i + j) / (2 * n)
                color = lerp_color((91, 44, 111), (160, 210, 235), t)
                draw.line([(x0, y0), (x1, y1)],
                         fill=color + (20,), width=1)
                count += 1
                if count >= 12000:
                    return img
    return img


# ═══════════════════════════════════════════════════════════════════
#  SECTION 5: COMPOSITION ENGINE
# ═══════════════════════════════════════════════════════════════════

def composite_layer(canvas, layer_rgb, layer_alpha):
    """Alpha-composite a layer onto the canvas (all float64, in-place)."""
    a = layer_alpha[:, :, np.newaxis]  # broadcast to 3 channels
    canvas[:] = canvas * (1 - a) + layer_rgb * a


def composite_pil_rgba(canvas, pil_img):
    """Composite a PIL RGBA image onto the float64 canvas."""
    arr = np.array(pil_img).astype(np.float64)
    rgb = arr[:, :, :3]
    alpha = arr[:, :, 3] / 255.0
    composite_layer(canvas, rgb, alpha)


def add_vignette(canvas, strength=0.5):
    """Vectorized vignette: darken edges to focus composition."""
    print("  Vignette...")
    h, w = canvas.shape[:2]
    y = np.linspace(-1, 1, h).reshape(-1, 1)
    x = np.linspace(-1, 1, w).reshape(1, -1)
    dist_sq = x*x + y*y
    factor = 1.0 - strength * dist_sq * 0.5
    factor = np.clip(factor, 0.1, 1.0)
    canvas *= factor[:, :, np.newaxis]


def add_grain(canvas, amount=3.0):
    """Add subtle film grain for organic texture."""
    print("  Film grain...")
    noise = np.random.normal(0, amount, canvas.shape)
    canvas += noise
    np.clip(canvas, 0, 255, out=canvas)


# ═══════════════════════════════════════════════════════════════════
#  SECTION 6: MAIN PAINTING PIPELINE
# ═══════════════════════════════════════════════════════════════════

def generate_painting():
    print("=" * 70)
    print("  INTEGER STRATA  —  A painting from the arithmetic of dreams")
    print("=" * 70)
    print()

    # ── Generate sequences ────────────────────────────────────────
    print("[1/9] Computing integer sequences (16,900 terms across 5 OEIS sequences)...")
    collatz    = gen_collatz_stopping_times(2500)
    print(f"  A006577 Collatz stopping times: 2500 terms, range [{collatz.min()}..{collatz.max()}]")
    recaman    = gen_recaman(2000)
    print(f"  A005132 Recamán's sequence:     2000 terms, range [{recaman.min()}..{recaman.max()}]")
    stern      = gen_stern_diatomic(5000)
    print(f"  A002487 Stern diatomic series:  5000 terms, range [{stern.min()}..{stern.max()}]")
    thue_morse = gen_thue_morse(5400)
    print(f"  A010060 Thue-Morse sequence:    5400 terms, values {set(thue_morse.tolist())}")
    prime_gaps = gen_prime_gaps(2000)
    print(f"  A001223 Prime gaps:             2000 terms, range [{prime_gaps.min()}..{prime_gaps.max()}]")
    total = len(collatz) + len(recaman) + len(stern) + len(thue_morse) + len(prime_gaps)
    print(f"  Total: {total} terms")
    print()

    # ── Build canvas (float64 RGB) ────────────────────────────────
    print("[2/9] Background gradient...")
    canvas = render_background(WIDTH, HEIGHT)

    # ── Layer 1: Cellular automaton ───────────────────────────────
    print("[3/9] Layer 1: Cellular automaton substrate")
    ca = render_ca_layer(collatz, thue_morse, WIDTH, HEIGHT)
    # Blend: use CA as base, weighted blend with background
    canvas = 0.35 * canvas + 0.65 * ca
    del ca
    print("       Done")

    # ── Layer 2: Modular color field ──────────────────────────────
    print("[4/9] Layer 2: Modular residue color field")
    mod_rgb, mod_alpha = render_modular_field(stern, WIDTH, HEIGHT)
    composite_layer(canvas, mod_rgb, mod_alpha)
    del mod_rgb, mod_alpha
    print("       Done")

    # ── Layer 3: Mountain silhouette ──────────────────────────────
    print("[5/9] Layer 3: Collatz mountain silhouette")
    mtn_rgb, mtn_alpha = render_mountain(collatz, WIDTH, HEIGHT)
    composite_layer(canvas, mtn_rgb, mtn_alpha)
    del mtn_rgb, mtn_alpha
    print("       Done")

    # ── Layer 4: Spectral aurora ──────────────────────────────────
    print("[6/9] Layer 4: Spectral aurora")
    aur_rgb, aur_alpha = render_aurora(collatz, WIDTH, HEIGHT)
    composite_layer(canvas, aur_rgb, aur_alpha)
    del aur_rgb, aur_alpha
    print("       Done")

    # ── Layer 5: Recurrence web ───────────────────────────────────
    print("[7/9] Layer 5: Recurrence web")
    web = render_recurrence_web(recaman, WIDTH, HEIGHT)
    composite_pil_rgba(canvas, web)
    del web
    print("       Done")

    # ── Layer 6: Phase space flow ─────────────────────────────────
    print("[8/9] Layer 6: Phase-space flow curves")
    flow = render_phase_flow_matplotlib(recaman, WIDTH, HEIGHT)
    # Apply Gaussian blur for painterly softness
    flow_rgb = gaussian_filter(flow[:, :, :3].astype(np.float64), sigma=(2.5, 2.5, 0))
    flow_alpha = gaussian_filter(flow[:, :, 3].astype(np.float64) / 255.0, sigma=2.0)
    # Boost alpha slightly for more presence
    flow_alpha = np.clip(flow_alpha * 1.8, 0, 1)
    composite_layer(canvas, flow_rgb, flow_alpha)
    del flow, flow_rgb, flow_alpha
    print("       Done")

    # ── Layer 7: Stars ────────────────────────────────────────────
    print("[9/9] Layer 7: Star field + Post-processing")
    stars = render_stars(prime_gaps, collatz, WIDTH, HEIGHT)
    composite_pil_rgba(canvas, stars)
    del stars
    print("       Stars done")

    # ── Post-processing ───────────────────────────────────────────
    add_vignette(canvas, strength=0.42)
    # Subtle warm color grade: lift shadows slightly toward violet-teal
    print("  Color grading...")
    luminance = np.mean(canvas, axis=2)
    shadow_mask = np.clip(1.0 - luminance / 60.0, 0, 1)  # affects dark areas
    canvas[:, :, 0] += shadow_mask * 3    # tiny red lift
    canvas[:, :, 1] += shadow_mask * 2    # tiny green lift
    canvas[:, :, 2] += shadow_mask * 6    # more blue in shadows
    np.clip(canvas, 0, 255, out=canvas)
    add_grain(canvas, amount=2.5)

    # ── Final signature ───────────────────────────────────────────
    final = Image.fromarray(np.clip(canvas, 0, 255).astype(np.uint8))
    draw = ImageDraw.Draw(final)
    sig = "Integer Strata  |  A006577 · A005132 · A002487 · A010060 · A001223  |  16,900 terms"
    draw.text((WIDTH - 700, HEIGHT - 25), sig, fill=(70, 65, 90))

    # ── Save ──────────────────────────────────────────────────────
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    final.save(OUTPUT_FILE, 'PNG')
    fsize = os.path.getsize(OUTPUT_FILE) / 1024 / 1024

    print()
    print("=" * 70)
    print(f"  PAINTING COMPLETE")
    print(f"  Output: {OUTPUT_FILE}")
    print(f"  Canvas: {WIDTH} × {HEIGHT} px  ({fsize:.1f} MB)")
    print(f"  Sequences: 5 OEIS  ({total} terms total)")
    print(f"  Layers: 7 (CA · modular · mountain · aurora · web · flow · stars)")
    print("=" * 70)
    return OUTPUT_FILE


if __name__ == '__main__':
    generate_painting()
