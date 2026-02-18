/**
 * Viz — Canvas-based visualizations for integer sequences
 *
 * Each visualization is a pure function: (ctx, width, height, terms, options) => void
 * No DOM dependencies. Pure mathematical painting.
 */

const TAU = Math.PI * 2;

function signedLog(x) {
  return Math.sign(x) * Math.log(1 + Math.abs(x));
}

function lerpColor(c1, c2, t) {
  return [
    c1[0] + (c2[0] - c1[0]) * t,
    c1[1] + (c2[1] - c1[1]) * t,
    c1[2] + (c2[2] - c1[2]) * t
  ];
}

function hsla(h, s, l, a) {
  return `hsla(${h}, ${s}%, ${l}%, ${a})`;
}

function clearCanvas(ctx, w, h) {
  ctx.fillStyle = '#08081a';
  ctx.fillRect(0, 0, w, h);
}

// ═══════════════════════════════════════════════════════
// 1. LINE — The raw sequence as luminous trace
// ═══════════════════════════════════════════════════════
export function drawLine(ctx, w, h, terms, opts = {}) {
  clearCanvas(ctx, w, h);
  if (terms.length < 2) return;

  const hue = opts.hue || 180;
  const pad = 40;
  const pw = w - pad * 2;
  const ph = h - pad * 2;

  const min = Math.min(...terms);
  const max = Math.max(...terms);
  const range = max - min || 1;

  // Subtle grid
  ctx.strokeStyle = 'rgba(60, 70, 100, 0.15)';
  ctx.lineWidth = 0.5;
  for (let i = 0; i <= 4; i++) {
    const y = pad + (ph * i) / 4;
    ctx.beginPath(); ctx.moveTo(pad, y); ctx.lineTo(w - pad, y); ctx.stroke();
  }

  // Main trace with glow
  ctx.shadowColor = hsla(hue, 60, 60, 0.4);
  ctx.shadowBlur = 12;
  ctx.strokeStyle = hsla(hue, 55, 65, 0.85);
  ctx.lineWidth = 1.5;
  ctx.lineJoin = 'round';
  ctx.beginPath();
  for (let i = 0; i < terms.length; i++) {
    const x = pad + (i / (terms.length - 1)) * pw;
    const y = pad + ph - ((terms[i] - min) / range) * ph;
    if (i === 0) ctx.moveTo(x, y);
    else ctx.lineTo(x, y);
  }
  ctx.stroke();
  ctx.shadowBlur = 0;

  // Terminal dots
  ctx.fillStyle = hsla(hue, 70, 75, 0.6);
  const dotEvery = Math.max(1, Math.floor(terms.length / 40));
  for (let i = 0; i < terms.length; i += dotEvery) {
    const x = pad + (i / (terms.length - 1)) * pw;
    const y = pad + ph - ((terms[i] - min) / range) * ph;
    ctx.beginPath();
    ctx.arc(x, y, 2, 0, TAU);
    ctx.fill();
  }
}

// ═══════════════════════════════════════════════════════
// 2. DIFFERENCE — First differences as energy field
// ═══════════════════════════════════════════════════════
export function drawDifference(ctx, w, h, terms, opts = {}) {
  clearCanvas(ctx, w, h);
  if (terms.length < 3) return;

  const hue = opts.hue || 280;
  const diffs = [];
  for (let i = 1; i < terms.length; i++) diffs.push(terms[i] - terms[i - 1]);

  const pad = 40;
  const pw = w - pad * 2;
  const ph = h - pad * 2;
  const max = Math.max(...diffs.map(Math.abs)) || 1;

  // Zero line
  ctx.strokeStyle = 'rgba(80, 90, 120, 0.3)';
  ctx.lineWidth = 0.5;
  ctx.beginPath();
  ctx.moveTo(pad, h / 2);
  ctx.lineTo(w - pad, h / 2);
  ctx.stroke();

  // Bars with gradient
  for (let i = 0; i < diffs.length; i++) {
    const x = pad + (i / diffs.length) * pw;
    const barW = Math.max(1, pw / diffs.length - 0.5);
    const normalized = diffs[i] / max;
    const barH = Math.abs(normalized) * (ph / 2);
    const y = h / 2 - (normalized > 0 ? barH : 0);

    const sat = 40 + Math.abs(normalized) * 40;
    const light = 40 + Math.abs(normalized) * 30;
    ctx.fillStyle = hsla(normalized > 0 ? hue : hue + 120, sat, light, 0.7);
    ctx.fillRect(x, y, barW, barH);
  }
}

// ═══════════════════════════════════════════════════════
// 3. PHASE — Return map / phase portrait
// ═══════════════════════════════════════════════════════
export function drawPhase(ctx, w, h, terms, opts = {}) {
  clearCanvas(ctx, w, h);
  if (terms.length < 3) return;

  const hue = opts.hue || 30;
  const pad = 40;
  const pw = w - pad * 2;
  const ph = h - pad * 2;

  const xVals = terms.slice(0, -1).map(signedLog);
  const yVals = terms.slice(1).map(signedLog);

  const xMin = Math.min(...xVals);
  const xMax = Math.max(...xVals);
  const yMin = Math.min(...yVals);
  const yMax = Math.max(...yVals);
  const xRange = xMax - xMin || 1;
  const yRange = yMax - yMin || 1;

  // Diagonal line (identity)
  ctx.strokeStyle = 'rgba(80, 90, 120, 0.2)';
  ctx.lineWidth = 0.5;
  ctx.beginPath();
  ctx.moveTo(pad, pad + ph);
  ctx.lineTo(pad + pw, pad);
  ctx.stroke();

  // Connecting lines (faint)
  ctx.strokeStyle = hsla(hue, 30, 50, 0.08);
  ctx.lineWidth = 0.5;
  ctx.beginPath();
  for (let i = 0; i < xVals.length; i++) {
    const x = pad + ((xVals[i] - xMin) / xRange) * pw;
    const y = pad + ph - ((yVals[i] - yMin) / yRange) * ph;
    if (i === 0) ctx.moveTo(x, y);
    else ctx.lineTo(x, y);
  }
  ctx.stroke();

  // Points with temporal color gradient
  for (let i = 0; i < xVals.length; i++) {
    const x = pad + ((xVals[i] - xMin) / xRange) * pw;
    const y = pad + ph - ((yVals[i] - yMin) / yRange) * ph;
    const t = i / xVals.length;

    ctx.beginPath();
    ctx.arc(x, y, 2.5, 0, TAU);
    ctx.fillStyle = hsla(hue + t * 60, 60, 55, 0.6);
    ctx.fill();
  }
}

// ═══════════════════════════════════════════════════════
// 4. RESIDUE — Modular residue heatmap
// ═══════════════════════════════════════════════════════
export function drawResidue(ctx, w, h, terms, opts = {}) {
  clearCanvas(ctx, w, h);
  if (terms.length < 2) return;

  const modulus = opts.modulus || 12;
  const residues = terms.map(t => ((t % modulus) + modulus) % modulus);
  const cols = Math.max(8, Math.ceil(Math.sqrt(residues.length * 2)));
  const rows = Math.ceil(residues.length / cols);

  const cellW = w / cols;
  const cellH = h / rows;

  for (let i = 0; i < residues.length; i++) {
    const col = i % cols;
    const row = Math.floor(i / cols);
    const val = residues[i] / (modulus - 1);

    // Color: warm spectrum
    const hue = 20 + val * 40;
    const light = 15 + val * 50;
    ctx.fillStyle = hsla(hue, 70, light, 0.9);
    ctx.fillRect(col * cellW, row * cellH, cellW + 0.5, cellH + 0.5);
  }
}

// ═══════════════════════════════════════════════════════
// 5. DIGIT TEXTURE — Concatenated digit stream as bitmap
// ═══════════════════════════════════════════════════════
export function drawDigitTexture(ctx, w, h, terms, opts = {}) {
  clearCanvas(ctx, w, h);
  if (terms.length < 2) return;

  const digits = [];
  for (const t of terms) {
    const s = String(Math.abs(t));
    for (const c of s) digits.push(parseInt(c));
  }

  const cols = Math.max(8, Math.ceil(Math.sqrt(digits.length * 1.5)));
  const rows = Math.ceil(digits.length / cols);
  const cellW = w / cols;
  const cellH = h / rows;

  for (let i = 0; i < digits.length; i++) {
    const col = i % cols;
    const row = Math.floor(i / cols);
    const val = digits[i] / 9;

    // Deep sea color scale
    const hue = 200 + val * 60;
    const light = 8 + val * 45;
    ctx.fillStyle = hsla(hue, 50, light, 0.9);
    ctx.fillRect(col * cellW, row * cellH, cellW + 0.5, cellH + 0.5);
  }
}

// ═══════════════════════════════════════════════════════
// 6. PARITY — Odd/even bitmap (fractal hunter)
// ═══════════════════════════════════════════════════════
export function drawParity(ctx, w, h, terms, opts = {}) {
  clearCanvas(ctx, w, h);
  if (terms.length < 4) return;

  const hue = opts.hue || 160;
  const cols = Math.max(8, Math.ceil(Math.sqrt(terms.length * 1.5)));
  const rows = Math.ceil(terms.length / cols);
  const cellW = w / cols;
  const cellH = h / rows;

  for (let i = 0; i < terms.length; i++) {
    const col = i % cols;
    const row = Math.floor(i / cols);
    const odd = Math.abs(terms[i]) % 2;

    if (odd) {
      ctx.fillStyle = hsla(hue, 50, 65, 0.85);
    } else {
      ctx.fillStyle = hsla(hue + 180, 20, 12, 0.9);
    }
    ctx.fillRect(col * cellW, row * cellH, cellW + 0.5, cellH + 0.5);
  }
}

// ═══════════════════════════════════════════════════════
// 7. MOD TRANSITIONS — Chord diagram of modular transitions
// ═══════════════════════════════════════════════════════
export function drawModTransitions(ctx, w, h, terms, opts = {}) {
  clearCanvas(ctx, w, h);
  if (terms.length < 3) return;

  const modulus = opts.modulus || Math.min(37, Math.max(12, Math.floor(terms.length / 5)));
  const hue = opts.hue || 200;
  const cx = w / 2;
  const cy = h / 2;
  const radius = Math.min(w, h) * 0.38;

  // Node positions on circle
  const nodes = [];
  for (let i = 0; i < modulus; i++) {
    const angle = (i / modulus) * TAU - Math.PI / 2;
    nodes.push({
      x: cx + Math.cos(angle) * radius,
      y: cy + Math.sin(angle) * radius
    });
  }

  // Count transitions
  const transitions = {};
  let maxCount = 0;
  const mapped = terms.map(t => ((t % modulus) + modulus) % modulus);
  for (let i = 1; i < mapped.length; i++) {
    const key = `${mapped[i - 1]}-${mapped[i]}`;
    transitions[key] = (transitions[key] || 0) + 1;
    maxCount = Math.max(maxCount, transitions[key]);
  }

  // Draw edges
  for (const [key, count] of Object.entries(transitions)) {
    const [from, to] = key.split('-').map(Number);
    if (from === to) continue;

    const t = count / maxCount;
    const alpha = 0.05 + t * 0.5;
    const lineW = 0.3 + t * 3;

    ctx.beginPath();
    ctx.moveTo(nodes[from].x, nodes[from].y);

    // Curved line through center area
    const midX = cx + (nodes[from].x + nodes[to].x - 2 * cx) * 0.3;
    const midY = cy + (nodes[from].y + nodes[to].y - 2 * cy) * 0.3;
    ctx.quadraticCurveTo(midX, midY, nodes[to].x, nodes[to].y);

    ctx.strokeStyle = hsla(hue + t * 60, 50 + t * 30, 50 + t * 20, alpha);
    ctx.lineWidth = lineW;
    ctx.stroke();
  }

  // Draw nodes
  for (let i = 0; i < modulus; i++) {
    ctx.beginPath();
    ctx.arc(nodes[i].x, nodes[i].y, 3, 0, TAU);
    ctx.fillStyle = hsla(hue, 30, 70, 0.7);
    ctx.fill();
  }
}

// ═══════════════════════════════════════════════════════
// 8. RECURRENCE — Delay-embedding distance matrix
// ═══════════════════════════════════════════════════════
export function drawRecurrence(ctx, w, h, terms, opts = {}) {
  clearCanvas(ctx, w, h);
  if (terms.length < 10) return;

  const dim = Math.min(3, Math.max(2, Math.floor(terms.length / 50)));
  const transformed = terms.map(signedLog);
  const n = Math.min(terms.length - dim + 1, 200);

  // Build embedded vectors
  const vectors = [];
  for (let i = 0; i <= n - 1; i++) {
    vectors.push(transformed.slice(i, i + dim));
  }

  // Compute distance matrix
  const size = vectors.length;
  const cellW = w / size;
  const cellH = h / size;

  // Find max distance for scaling
  let maxDist = 0;
  const dists = [];
  for (let i = 0; i < size; i++) {
    const row = [];
    for (let j = 0; j < size; j++) {
      let d = 0;
      for (let k = 0; k < dim; k++) {
        d += (vectors[i][k] - vectors[j][k]) ** 2;
      }
      d = Math.sqrt(d);
      row.push(d);
      if (d > maxDist) maxDist = d;
    }
    dists.push(row);
  }

  if (maxDist === 0) maxDist = 1;

  // Draw
  for (let i = 0; i < size; i++) {
    for (let j = 0; j < size; j++) {
      const val = 1 - dists[i][j] / maxDist;
      const hue = 80 + val * 60;
      const light = 8 + val * 40;
      ctx.fillStyle = hsla(hue, 50, light, 0.9);
      ctx.fillRect(j * cellW, i * cellH, cellW + 0.5, cellH + 0.5);
    }
  }
}

// ═══════════════════════════════════════════════════════
// 9. GROWTH RATE — Logarithmic growth visualization
// ═══════════════════════════════════════════════════════
export function drawGrowthRate(ctx, w, h, terms, opts = {}) {
  clearCanvas(ctx, w, h);
  if (terms.length < 3) return;

  const hue = opts.hue || 350;
  const pad = 40;
  const pw = w - pad * 2;
  const ph = h - pad * 2;

  // Log ratios
  const rates = [];
  for (let i = 1; i < terms.length; i++) {
    const prev = Math.abs(terms[i - 1]) || 1;
    const curr = Math.abs(terms[i]) || 1;
    rates.push(Math.log(curr / prev));
  }

  const max = Math.max(...rates.map(Math.abs)) || 1;

  // Zero line
  ctx.strokeStyle = 'rgba(80, 90, 120, 0.3)';
  ctx.lineWidth = 0.5;
  ctx.beginPath();
  ctx.moveTo(pad, h / 2);
  ctx.lineTo(w - pad, h / 2);
  ctx.stroke();

  // Filled area
  ctx.beginPath();
  ctx.moveTo(pad, h / 2);
  for (let i = 0; i < rates.length; i++) {
    const x = pad + (i / (rates.length - 1)) * pw;
    const y = h / 2 - (rates[i] / max) * (ph / 2);
    ctx.lineTo(x, y);
  }
  ctx.lineTo(pad + pw, h / 2);
  ctx.closePath();

  const grad = ctx.createLinearGradient(0, pad, 0, h - pad);
  grad.addColorStop(0, hsla(hue, 60, 60, 0.4));
  grad.addColorStop(0.5, hsla(hue, 40, 30, 0.1));
  grad.addColorStop(1, hsla(hue + 120, 60, 60, 0.4));
  ctx.fillStyle = grad;
  ctx.fill();

  // Line on top
  ctx.strokeStyle = hsla(hue, 50, 60, 0.7);
  ctx.lineWidth = 1;
  ctx.beginPath();
  for (let i = 0; i < rates.length; i++) {
    const x = pad + (i / (rates.length - 1)) * pw;
    const y = h / 2 - (rates[i] / max) * (ph / 2);
    if (i === 0) ctx.moveTo(x, y);
    else ctx.lineTo(x, y);
  }
  ctx.stroke();
}

// ═══════════════════════════════════════════════════════
// 10. SPIRAL — Values on Archimedean spiral
// ═══════════════════════════════════════════════════════
export function drawSpiral(ctx, w, h, terms, opts = {}) {
  clearCanvas(ctx, w, h);
  if (terms.length < 3) return;

  const hue = opts.hue || 260;
  const cx = w / 2;
  const cy = h / 2;
  const maxR = Math.min(w, h) * 0.42;

  const max = Math.max(...terms.map(Math.abs)) || 1;

  ctx.lineWidth = 1;
  ctx.lineCap = 'round';

  let prevX = cx, prevY = cy;
  for (let i = 0; i < terms.length; i++) {
    const t = i / terms.length;
    const angle = t * TAU * 4; // 4 full turns
    const r = t * maxR;
    const val = Math.abs(terms[i]) / max;

    const x = cx + Math.cos(angle) * r;
    const y = cy + Math.sin(angle) * r;

    // Line segment
    ctx.beginPath();
    ctx.moveTo(prevX, prevY);
    ctx.lineTo(x, y);
    ctx.strokeStyle = hsla(hue + t * 80, 50, 40 + val * 30, 0.5);
    ctx.stroke();

    // Value dot
    const dotR = 1 + val * 4;
    ctx.beginPath();
    ctx.arc(x, y, dotR, 0, TAU);
    ctx.fillStyle = hsla(hue + t * 80, 60, 50 + val * 25, 0.7);
    ctx.fill();

    prevX = x;
    prevY = y;
  }
}

// ═══════════════════════════════════════════════════════
// 11. COAGULATION — Layered blend of multiple views
// ═══════════════════════════════════════════════════════
export function drawCoagulation(ctx, w, h, terms, opts = {}) {
  const hue = opts.hue || 200;
  const tempCanvas = document.createElement('canvas');
  tempCanvas.width = w;
  tempCanvas.height = h;
  const tctx = tempCanvas.getContext('2d');

  clearCanvas(ctx, w, h);

  // Layer multiple views with different blend modes and opacities
  const layers = [
    { fn: drawResidue, opacity: 0.3, blend: 'screen' },
    { fn: drawPhase, opacity: 0.25, blend: 'screen' },
    { fn: drawModTransitions, opacity: 0.35, blend: 'screen' },
    { fn: drawRecurrence, opacity: 0.2, blend: 'lighten' },
    { fn: drawDigitTexture, opacity: 0.15, blend: 'color-dodge' },
  ];

  for (const layer of layers) {
    layer.fn(tctx, w, h, terms, { ...opts, hue: hue + Math.random() * 40 });
    ctx.globalAlpha = layer.opacity;
    ctx.globalCompositeOperation = layer.blend;
    ctx.drawImage(tempCanvas, 0, 0);
  }

  ctx.globalAlpha = 1;
  ctx.globalCompositeOperation = 'source-over';

  // Vignette
  const grad = ctx.createRadialGradient(w/2, h/2, w*0.2, w/2, h/2, w*0.7);
  grad.addColorStop(0, 'transparent');
  grad.addColorStop(1, 'rgba(6, 6, 12, 0.6)');
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, w, h);
}

// ═══════════════════════════════════════════════════════
// 12. DRAMATIC ARC — Volatility over time as landscape
// ═══════════════════════════════════════════════════════
export function drawDramaticArc(ctx, w, h, terms, opts = {}) {
  clearCanvas(ctx, w, h);
  if (terms.length < 20) return;

  const hue = opts.hue || 10;
  const pad = 40;
  const pw = w - pad * 2;
  const ph = h - pad * 2;

  // Windowed volatility
  const windowSize = Math.max(5, Math.floor(terms.length / 20));
  const volatilities = [];
  for (let i = 0; i < terms.length - windowSize; i++) {
    const window = terms.slice(i, i + windowSize);
    const logMags = window.map(t => Math.log(1 + Math.abs(t)));
    const diffs = [];
    for (let j = 1; j < logMags.length; j++) diffs.push(logMags[j] - logMags[j-1]);
    const m = diffs.reduce((a, b) => a + b, 0) / diffs.length;
    const v = Math.sqrt(diffs.reduce((s, x) => s + (x - m) ** 2, 0) / diffs.length);
    volatilities.push(v);
  }

  const maxVol = Math.max(...volatilities) || 1;

  // Mountain-like fill
  ctx.beginPath();
  ctx.moveTo(pad, pad + ph);
  for (let i = 0; i < volatilities.length; i++) {
    const x = pad + (i / (volatilities.length - 1)) * pw;
    const y = pad + ph - (volatilities[i] / maxVol) * ph;
    ctx.lineTo(x, y);
  }
  ctx.lineTo(pad + pw, pad + ph);
  ctx.closePath();

  const grad = ctx.createLinearGradient(0, pad, 0, pad + ph);
  grad.addColorStop(0, hsla(hue, 70, 55, 0.7));
  grad.addColorStop(0.5, hsla(hue + 30, 60, 35, 0.5));
  grad.addColorStop(1, hsla(hue + 60, 40, 15, 0.2));
  ctx.fillStyle = grad;
  ctx.fill();

  // Climax marker
  let climaxIdx = 0;
  let climaxVal = 0;
  for (let i = 0; i < volatilities.length; i++) {
    if (volatilities[i] > climaxVal) {
      climaxVal = volatilities[i];
      climaxIdx = i;
    }
  }
  const climaxX = pad + (climaxIdx / (volatilities.length - 1)) * pw;
  const climaxY = pad + ph - (climaxVal / maxVol) * ph;

  ctx.beginPath();
  ctx.arc(climaxX, climaxY, 5, 0, TAU);
  ctx.fillStyle = hsla(hue, 80, 70, 0.9);
  ctx.shadowColor = hsla(hue, 80, 70, 0.6);
  ctx.shadowBlur = 15;
  ctx.fill();
  ctx.shadowBlur = 0;

  // Label
  ctx.font = '10px "JetBrains Mono", monospace';
  ctx.fillStyle = hsla(hue, 50, 70, 0.7);
  ctx.fillText('climax', climaxX - 15, climaxY - 12);
}

// ═══════════════════════════════════════════════════════
// MINI — Tiny preview for dock orbs
// ═══════════════════════════════════════════════════════
export function drawMiniPreview(ctx, w, h, terms, hue = 200) {
  ctx.fillStyle = `hsla(${hue}, 30, 10, 0.9)`;
  ctx.fillRect(0, 0, w, h);

  if (terms.length < 2) return;

  const min = Math.min(...terms);
  const max = Math.max(...terms);
  const range = max - min || 1;

  // Tiny line plot
  ctx.strokeStyle = hsla(hue, 60, 60, 0.8);
  ctx.lineWidth = 1.5;
  ctx.beginPath();
  for (let i = 0; i < terms.length; i++) {
    const x = (i / (terms.length - 1)) * w;
    const y = h - ((terms[i] - min) / range) * h * 0.8 - h * 0.1;
    if (i === 0) ctx.moveTo(x, y);
    else ctx.lineTo(x, y);
  }
  ctx.stroke();
}

// ═══════════════════════════════════════════════════════
// BEAUTY RADAR — Spider chart of beauty dimensions
// ═══════════════════════════════════════════════════════
export function drawBeautyRadar(ctx, w, h, beauty, dimensions) {
  ctx.fillStyle = '#0a0a16';
  ctx.fillRect(0, 0, w, h);

  const cx = w / 2;
  const cy = h / 2;
  const radius = Math.min(w, h) * 0.36;
  const n = dimensions.length;

  // Background rings
  for (let ring = 1; ring <= 4; ring++) {
    const r = (ring / 4) * radius;
    ctx.beginPath();
    for (let i = 0; i <= n; i++) {
      const angle = (i / n) * TAU - Math.PI / 2;
      const x = cx + Math.cos(angle) * r;
      const y = cy + Math.sin(angle) * r;
      if (i === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    }
    ctx.strokeStyle = `rgba(60, 70, 100, ${0.1 + ring * 0.05})`;
    ctx.lineWidth = 0.5;
    ctx.stroke();
  }

  // Axis lines and labels
  for (let i = 0; i < n; i++) {
    const angle = (i / n) * TAU - Math.PI / 2;
    const x = cx + Math.cos(angle) * radius;
    const y = cy + Math.sin(angle) * radius;

    ctx.beginPath();
    ctx.moveTo(cx, cy);
    ctx.lineTo(x, y);
    ctx.strokeStyle = 'rgba(60, 70, 100, 0.15)';
    ctx.lineWidth = 0.5;
    ctx.stroke();

    // Label
    const labelR = radius + 14;
    const lx = cx + Math.cos(angle) * labelR;
    const ly = cy + Math.sin(angle) * labelR;

    ctx.save();
    ctx.font = '9px "JetBrains Mono", monospace';
    ctx.fillStyle = dimensions[i].color + '88';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';

    // Rotate label to follow axis
    const label = dimensions[i].label;
    if (angle > Math.PI / 2 - 0.1 && angle < Math.PI * 1.5 + 0.1) {
      ctx.fillText(label, lx, ly);
    } else {
      ctx.fillText(label, lx, ly);
    }
    ctx.restore();
  }

  // Data polygon
  ctx.beginPath();
  for (let i = 0; i <= n; i++) {
    const idx = i % n;
    const angle = (idx / n) * TAU - Math.PI / 2;
    const val = beauty[dimensions[idx].key] || 0;
    const r = val * radius;
    const x = cx + Math.cos(angle) * r;
    const y = cy + Math.sin(angle) * r;
    if (i === 0) ctx.moveTo(x, y);
    else ctx.lineTo(x, y);
  }

  // Fill
  const grad = ctx.createRadialGradient(cx, cy, 0, cx, cy, radius);
  grad.addColorStop(0, `hsla(${beauty.hue || 200}, 60%, 50%, 0.25)`);
  grad.addColorStop(1, `hsla(${beauty.hue || 200}, 60%, 50%, 0.05)`);
  ctx.fillStyle = grad;
  ctx.fill();

  // Stroke
  ctx.strokeStyle = `hsla(${beauty.hue || 200}, 60%, 65%, 0.7)`;
  ctx.lineWidth = 1.5;
  ctx.stroke();

  // Data points
  for (let i = 0; i < n; i++) {
    const angle = (i / n) * TAU - Math.PI / 2;
    const val = beauty[dimensions[i].key] || 0;
    const r = val * radius;
    const x = cx + Math.cos(angle) * r;
    const y = cy + Math.sin(angle) * r;

    ctx.beginPath();
    ctx.arc(x, y, 3, 0, TAU);
    ctx.fillStyle = dimensions[i].color;
    ctx.shadowColor = dimensions[i].color;
    ctx.shadowBlur = 8;
    ctx.fill();
    ctx.shadowBlur = 0;
  }

  // Beauty Index in center
  ctx.font = '600 24px "Cormorant Garamond", serif';
  ctx.fillStyle = `hsla(${beauty.hue || 200}, 50%, 75%, 0.9)`;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText((beauty.beautyIndex || 0).toFixed(3), cx, cy - 8);

  ctx.font = '10px "JetBrains Mono", monospace';
  ctx.fillStyle = 'rgba(160, 170, 200, 0.5)';
  ctx.fillText('beauty index', cx, cy + 14);
}

// ═══════════════════════════════════════════════════════
// EMBEDDING — 2D beauty space scatter plot
// ═══════════════════════════════════════════════════════
export function drawEmbedding(ctx, w, h, sequences) {
  ctx.fillStyle = '#06060c';
  ctx.fillRect(0, 0, w, h);

  if (sequences.length === 0) return;

  const pad = 60;
  const pw = w - pad * 2;
  const ph = h - pad * 2;

  // Axes
  ctx.strokeStyle = 'rgba(60, 70, 100, 0.2)';
  ctx.lineWidth = 0.5;
  // Horizontal
  ctx.beginPath();
  ctx.moveTo(pad, h / 2);
  ctx.lineTo(w - pad, h / 2);
  ctx.stroke();
  // Vertical
  ctx.beginPath();
  ctx.moveTo(w / 2, pad);
  ctx.lineTo(w / 2, h - pad);
  ctx.stroke();

  // Axis labels
  ctx.font = '10px "JetBrains Mono", monospace';
  ctx.fillStyle = 'rgba(120, 130, 160, 0.4)';
  ctx.textAlign = 'center';
  ctx.fillText('structural', w / 2, h - pad + 30);
  ctx.save();
  ctx.translate(pad - 30, h / 2);
  ctx.rotate(-Math.PI / 2);
  ctx.fillText('experiential', 0, 0);
  ctx.restore();

  // Cross-reference connections
  ctx.strokeStyle = 'rgba(100, 110, 160, 0.08)';
  ctx.lineWidth = 0.5;
  for (let i = 0; i < sequences.length; i++) {
    for (let j = i + 1; j < sequences.length; j++) {
      const si = sequences[i];
      const sj = sequences[j];
      if (si.xrefs && si.xrefs.includes(sj.id)) {
        const xi = pad + ((si.embedPos.x + 1) / 2) * pw;
        const yi = pad + ph - ((si.embedPos.y + 1) / 2) * ph;
        const xj = pad + ((sj.embedPos.x + 1) / 2) * pw;
        const yj = pad + ph - ((sj.embedPos.y + 1) / 2) * ph;

        ctx.beginPath();
        ctx.moveTo(xi, yi);
        ctx.lineTo(xj, yj);
        ctx.strokeStyle = `hsla(${(si.beauty.hue + sj.beauty.hue) / 2}, 30%, 50%, 0.15)`;
        ctx.stroke();
      }
    }
  }

  // Sequence points
  for (const seq of sequences) {
    const x = pad + ((seq.embedPos.x + 1) / 2) * pw;
    const y = pad + ph - ((seq.embedPos.y + 1) / 2) * ph;
    const r = 6 + seq.beauty.beautyIndex * 14;
    const hue = seq.beauty.hue;

    // Glow
    const grad = ctx.createRadialGradient(x, y, 0, x, y, r * 3);
    grad.addColorStop(0, hsla(hue, 60, 60, 0.15));
    grad.addColorStop(1, 'transparent');
    ctx.fillStyle = grad;
    ctx.fillRect(x - r * 3, y - r * 3, r * 6, r * 6);

    // Point
    ctx.beginPath();
    ctx.arc(x, y, r, 0, TAU);
    ctx.fillStyle = hsla(hue, 55, 55, 0.8);
    ctx.fill();
    ctx.strokeStyle = hsla(hue, 60, 70, 0.5);
    ctx.lineWidth = 1;
    ctx.stroke();

    // Label
    ctx.font = '10px "JetBrains Mono", monospace';
    ctx.fillStyle = hsla(hue, 40, 70, 0.8);
    ctx.textAlign = 'center';
    ctx.fillText(seq.id, x, y + r + 14);

    ctx.font = '300 11px "Cormorant Garamond", serif';
    ctx.fillStyle = 'rgba(180, 185, 210, 0.5)';
    const shortName = (seq.name || '').slice(0, 30);
    ctx.fillText(shortName, x, y + r + 26);
  }
}

// Export viz modes
export const VIZ_MODES = [
  { key: 'line', label: 'trace', fn: drawLine },
  { key: 'difference', label: 'delta', fn: drawDifference },
  { key: 'phase', label: 'phase', fn: drawPhase },
  { key: 'residue', label: 'residue', fn: drawResidue },
  { key: 'digits', label: 'digits', fn: drawDigitTexture },
  { key: 'parity', label: 'parity', fn: drawParity },
  { key: 'modtrans', label: 'chords', fn: drawModTransitions },
  { key: 'recurrence', label: 'recurrence', fn: drawRecurrence },
  { key: 'growth', label: 'growth', fn: drawGrowthRate },
  { key: 'spiral', label: 'spiral', fn: drawSpiral },
  { key: 'dramatic', label: 'drama', fn: drawDramaticArc },
  { key: 'coagulation', label: 'coagulate', fn: drawCoagulation },
];
