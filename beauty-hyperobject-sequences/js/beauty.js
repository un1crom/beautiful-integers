/**
 * Beauty — Deep beauty metric computation for integer sequences
 *
 * Dimensions of mathematical beauty:
 *  1. Compressibility        — how concise under encoding
 *  2. DeltaSignEntropy       — unpredictability of direction changes
 *  3. GrowthDrama            — volatility of magnitude evolution
 *  4. ResidueStructure       — pattern in modular residue classes
 *  5. Novelty                — invention rate of new values
 *  6. SelfSimilarity         — autocorrelation depth across scales
 *  7. HarmonicContent        — musical consonance in interval structure
 *  8. DramaticArc            — Freytag's pyramid: exposition-climax-resolution
 *  9. CompositionType        — Payne compositional archetype
 * 10. Connectedness          — cross-reference network centrality
 * 11. WaveMechanics          — oscillatory character from recurrence structure
 * 12. RecursionDepth         — self-referential complexity
 */

export function computeBeauty(terms, xrefs = [], keywords = []) {
  if (!terms || terms.length < 5) {
    return defaultProfile();
  }

  const compressibility = computeCompressibility(terms);
  const deltaEntropy = computeDeltaSignEntropy(terms);
  const growthDrama = computeGrowthDrama(terms);
  const residueStructure = computeResidueStructure(terms);
  const novelty = computeNovelty(terms);
  const selfSimilarity = computeSelfSimilarity(terms);
  const harmonicContent = computeHarmonicContent(terms);
  const dramaticArc = computeDramaticArc(terms);
  const composition = classifyComposition(terms);
  const connectedness = computeConnectedness(xrefs);
  const waveMechanics = computeWaveMechanics(terms);
  const recursionDepth = computeRecursionDepth(terms);

  // Weighted composite beauty index
  const beautyIndex = clamp01(
    0.10 * compressibility +
    0.10 * deltaEntropy +
    0.10 * growthDrama +
    0.06 * residueStructure +
    0.06 * novelty +
    0.12 * selfSimilarity +
    0.10 * harmonicContent +
    0.10 * dramaticArc +
    0.08 * composition.score +
    0.06 * connectedness +
    0.06 * waveMechanics +
    0.06 * recursionDepth
  );

  return {
    compressibility,
    deltaEntropy,
    growthDrama,
    residueStructure,
    novelty,
    selfSimilarity,
    harmonicContent,
    dramaticArc,
    compositionType: composition.type,
    compositionScore: composition.score,
    compositionDescription: composition.description,
    connectedness,
    waveMechanics,
    recursionDepth,
    beautyIndex,
    // Derived color
    hue: computeSequenceHue(terms),
    saturation: 40 + novelty * 40,
    lightness: 45 + harmonicContent * 25
  };
}

function defaultProfile() {
  return {
    compressibility: 0, deltaEntropy: 0, growthDrama: 0,
    residueStructure: 0, novelty: 0, selfSimilarity: 0,
    harmonicContent: 0, dramaticArc: 0,
    compositionType: 'unknown', compositionScore: 0, compositionDescription: '',
    connectedness: 0, waveMechanics: 0, recursionDepth: 0,
    beautyIndex: 0, hue: 220, saturation: 40, lightness: 50
  };
}

function clamp01(x) { return Math.max(0, Math.min(1, x)); }

function mean(arr) {
  if (arr.length === 0) return 0;
  return arr.reduce((a, b) => a + b, 0) / arr.length;
}

function stddev(arr) {
  if (arr.length < 2) return 0;
  const m = mean(arr);
  const variance = arr.reduce((sum, x) => sum + (x - m) ** 2, 0) / arr.length;
  return Math.sqrt(variance);
}

function entropy(counts) {
  const total = Object.values(counts).reduce((a, b) => a + b, 0);
  if (total === 0) return 0;
  let h = 0;
  for (const c of Object.values(counts)) {
    if (c > 0) {
      const p = c / total;
      h -= p * Math.log2(p);
    }
  }
  return h;
}

function normalizedEntropy(counts) {
  const n = Object.keys(counts).length;
  if (n <= 1) return 0;
  return entropy(counts) / Math.log2(n);
}

// 1. Compressibility — run-length encoding ratio
function computeCompressibility(terms) {
  if (terms.length < 2) return 0;

  // RLE compression ratio
  let runs = 1;
  for (let i = 1; i < terms.length; i++) {
    if (terms[i] !== terms[i - 1]) runs++;
  }
  const rleRatio = 1 - runs / terms.length;

  // Difference compressibility
  const diffs = [];
  for (let i = 1; i < terms.length; i++) diffs.push(terms[i] - terms[i - 1]);
  let diffRuns = 1;
  for (let i = 1; i < diffs.length; i++) {
    if (diffs[i] !== diffs[i - 1]) diffRuns++;
  }
  const diffRleRatio = diffs.length > 0 ? (1 - diffRuns / diffs.length) : 0;

  // Second differences
  const diffs2 = [];
  for (let i = 1; i < diffs.length; i++) diffs2.push(diffs[i] - diffs[i - 1]);
  let diff2Runs = 1;
  for (let i = 1; i < diffs2.length; i++) {
    if (diffs2[i] !== diffs2[i - 1]) diff2Runs++;
  }
  const diff2RleRatio = diffs2.length > 0 ? (1 - diff2Runs / diffs2.length) : 0;

  return clamp01(0.3 * rleRatio + 0.4 * diffRleRatio + 0.3 * diff2RleRatio);
}

// 2. Delta Sign Entropy
function computeDeltaSignEntropy(terms) {
  if (terms.length < 3) return 0;
  const signs = {};
  for (let i = 1; i < terms.length; i++) {
    const s = Math.sign(terms[i] - terms[i - 1]);
    signs[s] = (signs[s] || 0) + 1;
  }
  return normalizedEntropy(signs);
}

// 3. Growth Drama
function computeGrowthDrama(terms) {
  if (terms.length < 3) return 0;
  const logMags = terms.map(t => Math.log(1 + Math.abs(t)));
  const deltas = [];
  for (let i = 1; i < logMags.length; i++) {
    deltas.push(logMags[i] - logMags[i - 1]);
  }
  const vol = stddev(deltas);
  return clamp01(1 - Math.exp(-vol));
}

// 4. Residue Structure (anti-entropy = structure)
function computeResidueStructure(terms, modulus = 12) {
  const counts = {};
  for (const t of terms) {
    const r = ((t % modulus) + modulus) % modulus;
    counts[r] = (counts[r] || 0) + 1;
  }
  return clamp01(1 - normalizedEntropy(counts));
}

// 5. Novelty
function computeNovelty(terms) {
  if (terms.length === 0) return 0;
  const unique = new Set(terms);
  return unique.size / terms.length;
}

// 6. Self-Similarity — autocorrelation cascade depth
function computeSelfSimilarity(terms) {
  if (terms.length < 20) return 0;

  const n = Math.min(terms.length, 256);
  const data = terms.slice(0, n);
  const m = mean(data);
  const v = data.reduce((s, x) => s + (x - m) ** 2, 0);
  if (v === 0) return 1; // constant sequence is perfectly self-similar

  // Compute autocorrelation at multiple lags
  const lags = [1, 2, 3, 5, 8, 13, 21, 34];
  const autocorrs = [];
  for (const lag of lags) {
    if (lag >= n) break;
    let sum = 0;
    for (let i = 0; i < n - lag; i++) {
      sum += (data[i] - m) * (data[i + lag] - m);
    }
    autocorrs.push(Math.abs(sum / v));
  }

  if (autocorrs.length === 0) return 0;

  // Self-similarity = how slowly autocorrelation decays
  const avgAutocorr = mean(autocorrs);
  // Also check if autocorrelation of autocorrelation is high
  if (autocorrs.length >= 3) {
    const acOfAc = [];
    const acm = mean(autocorrs);
    const acv = autocorrs.reduce((s, x) => s + (x - acm) ** 2, 0);
    if (acv > 0) {
      for (let lag = 1; lag < autocorrs.length; lag++) {
        let sum = 0;
        for (let i = 0; i < autocorrs.length - lag; i++) {
          sum += (autocorrs[i] - acm) * (autocorrs[i + lag] - acm);
        }
        acOfAc.push(Math.abs(sum / acv));
      }
      const metaAC = mean(acOfAc);
      return clamp01(0.6 * avgAutocorr + 0.4 * metaAC);
    }
  }
  return clamp01(avgAutocorr);
}

// 7. Harmonic Content — musical consonance analysis
function computeHarmonicContent(terms) {
  if (terms.length < 5) return 0;

  // Map differences to musical intervals (mod 12 = chromatic)
  const intervals = [];
  for (let i = 1; i < terms.length; i++) {
    intervals.push(((terms[i] - terms[i - 1]) % 12 + 12) % 12);
  }

  // Consonant intervals: unison(0), minor 3rd(3), major 3rd(4),
  // perfect 4th(5), perfect 5th(7), octave(0 again)
  const consonant = new Set([0, 3, 4, 5, 7, 8, 9, 12]);
  let consonantCount = 0;
  for (const iv of intervals) {
    if (consonant.has(iv)) consonantCount++;
  }
  const consonanceRatio = consonantCount / intervals.length;

  // Melodic contour: detect stepwise motion vs leaps
  const steps = intervals.filter(iv => iv <= 2 || iv >= 10).length;
  const stepRatio = steps / intervals.length;

  // Cadential patterns: V-I equivalent (7->0 or 5->0 transitions)
  let cadences = 0;
  for (let i = 1; i < intervals.length; i++) {
    if ((intervals[i - 1] === 7 || intervals[i - 1] === 5) && intervals[i] === 0) {
      cadences++;
    }
  }
  const cadenceRatio = cadences / Math.max(1, intervals.length);

  // Run-length encoding of intervals (rhythmic regularity)
  let runCount = 1;
  for (let i = 1; i < intervals.length; i++) {
    if (intervals[i] !== intervals[i - 1]) runCount++;
  }
  const rhythmRegularity = 1 - runCount / intervals.length;

  return clamp01(
    0.35 * consonanceRatio +
    0.20 * stepRatio +
    0.15 * cadenceRatio * 10 +
    0.30 * rhythmRegularity
  );
}

// 8. Dramatic Arc — Freytag's pyramid detection
function computeDramaticArc(terms) {
  if (terms.length < 10) return 0;

  const n = terms.length;
  const thirds = Math.floor(n / 3);

  // Compute local volatility in three acts
  const act1 = terms.slice(0, thirds);
  const act2 = terms.slice(thirds, thirds * 2);
  const act3 = terms.slice(thirds * 2);

  const vol1 = stddev(act1);
  const vol2 = stddev(act2);
  const vol3 = stddev(act3);

  // Ideal dramatic arc: rising action then resolution
  // vol1 < vol2 > vol3 (Freytag)
  let arcScore = 0;

  // Rising action
  if (vol2 > vol1 && vol1 > 0) {
    arcScore += 0.4 * clamp01((vol2 - vol1) / vol1);
  }
  // Climax exists
  if (vol2 > vol3) {
    arcScore += 0.3 * clamp01((vol2 - vol3) / Math.max(1, vol2));
  }

  // Find the "climax point" - maximum absolute value
  let climaxIdx = 0;
  let climaxVal = 0;
  for (let i = 0; i < n; i++) {
    const av = Math.abs(terms[i]);
    if (av > climaxVal) {
      climaxVal = av;
      climaxIdx = i;
    }
  }
  // Climax position bonus (near golden ratio is most dramatic)
  const climaxPos = climaxIdx / n;
  const goldenDist = Math.abs(climaxPos - 0.618);
  arcScore += 0.3 * clamp01(1 - goldenDist * 3);

  return clamp01(arcScore);
}

// 9. Composition Classification — Payne archetypes
function classifyComposition(terms) {
  if (terms.length < 10) {
    return { type: 'void', score: 0, description: 'insufficient data' };
  }

  const n = Math.min(terms.length, 200);
  const data = terms.slice(0, n);

  // Phase portrait properties
  const xVals = data.slice(0, -1).map(signedLog);
  const yVals = data.slice(1).map(signedLog);

  // Quadrant distribution
  const quads = [0, 0, 0, 0];
  for (let i = 0; i < xVals.length; i++) {
    const qx = xVals[i] >= 0 ? 1 : 0;
    const qy = yVals[i] >= 0 ? 1 : 0;
    quads[qy * 2 + qx]++;
  }
  const quadTotal = quads.reduce((a, b) => a + b, 0);
  const quadProbs = quads.map(q => q / quadTotal);

  // Compute key compositional features
  const symmetry = 1 - Math.abs(quadProbs[0] - quadProbs[3]) - Math.abs(quadProbs[1] - quadProbs[2]);
  const skewness = Math.abs(quadProbs[0] + quadProbs[1] - quadProbs[2] - quadProbs[3]);

  // Radial spread (distance from center)
  const cx = mean(xVals);
  const cy = mean(yVals);
  const radii = xVals.map((x, i) => Math.sqrt((x - cx) ** 2 + (yVals[i] - cy) ** 2));
  const radialCV = stddev(radii) / Math.max(0.001, mean(radii)); // coefficient of variation

  // Angular spread
  const angles = xVals.map((x, i) => Math.atan2(yVals[i] - cy, x - cx));
  const angleCounts = {};
  for (const a of angles) {
    const bin = Math.floor(((a + Math.PI) / (2 * Math.PI)) * 8);
    angleCounts[bin] = (angleCounts[bin] || 0) + 1;
  }
  const angularEntropy = normalizedEntropy(angleCounts);

  // Curvature changes (inflection points)
  const diffs = [];
  for (let i = 1; i < data.length; i++) diffs.push(data[i] - data[i - 1]);
  let inflections = 0;
  for (let i = 1; i < diffs.length; i++) {
    if (diffs[i] * diffs[i - 1] < 0) inflections++;
  }
  const inflectionRate = inflections / Math.max(1, diffs.length);

  // Classify
  const types = [
    {
      type: 'steelyard',
      score: 0.4 * skewness + 0.3 * (1 - symmetry) + 0.3 * clamp01(radialCV),
      description: 'asymmetric tension balanced by gravitational pull'
    },
    {
      type: 'balance',
      score: 0.5 * symmetry + 0.3 * (1 - skewness) + 0.2 * (1 - radialCV),
      description: 'symmetric equilibrium across the compositional field'
    },
    {
      type: 'radiating',
      score: 0.4 * angularEntropy + 0.3 * radialCV + 0.3 * clamp01(1 - inflectionRate),
      description: 'energy spraying outward from a generative center'
    },
    {
      type: 's-curve',
      score: 0.5 * inflectionRate + 0.3 * (1 - symmetry) + 0.2 * angularEntropy,
      description: 'continuous inflection creating flowing movement'
    },
    {
      type: 'group-mass',
      score: 0.4 * (1 - angularEntropy) + 0.3 * (1 - radialCV) + 0.3 * symmetry,
      description: 'dense gravitational clustering of mathematical weight'
    },
    {
      type: 'cantilever',
      score: 0.4 * skewness + 0.3 * clamp01(radialCV * 2) + 0.3 * (1 - inflectionRate),
      description: 'dramatic overhang of values beyond the structural base'
    },
    {
      type: 'spiral',
      score: (() => {
        // Detect spiral: monotonic radius + changing angle
        let radiusMonotone = 0;
        for (let i = 1; i < radii.length; i++) {
          if (radii[i] > radii[i-1]) radiusMonotone++;
        }
        return 0.4 * (radiusMonotone / Math.max(1, radii.length - 1)) +
               0.3 * angularEntropy + 0.3 * (1 - symmetry);
      })(),
      description: 'unwinding energy expanding through rotational force'
    },
    {
      type: 'tunnel',
      score: 0.4 * (1 - radialCV) + 0.3 * (1 - angularEntropy) + 0.3 * symmetry,
      description: 'converging perspective drawing the eye inward'
    }
  ];

  types.sort((a, b) => b.score - a.score);
  return types[0];
}

function signedLog(x) {
  return Math.sign(x) * Math.log(1 + Math.abs(x));
}

// 10. Connectedness — cross-reference network measure
function computeConnectedness(xrefs) {
  if (!xrefs || xrefs.length === 0) return 0;
  // Logarithmic scaling: each doubling of xrefs is worth less
  return clamp01(Math.log(1 + xrefs.length) / Math.log(50));
}

// 11. Wave Mechanics — oscillatory character
function computeWaveMechanics(terms) {
  if (terms.length < 10) return 0;

  // Count sign changes in differences (oscillation)
  const diffs = [];
  for (let i = 1; i < terms.length; i++) diffs.push(terms[i] - terms[i - 1]);

  let signChanges = 0;
  for (let i = 1; i < diffs.length; i++) {
    if (diffs[i] * diffs[i - 1] < 0) signChanges++;
  }
  const oscillationRate = signChanges / Math.max(1, diffs.length);

  // Period detection via autocorrelation peaks
  const n = Math.min(terms.length, 128);
  const data = terms.slice(0, n);
  const m = mean(data);
  const v = data.reduce((s, x) => s + (x - m) ** 2, 0);
  if (v === 0) return 0;

  let peakCount = 0;
  const maxLag = Math.floor(n / 2);
  let prevCorr = 1;
  let prevPrevCorr = 1;
  for (let lag = 1; lag < maxLag; lag++) {
    let sum = 0;
    for (let i = 0; i < n - lag; i++) {
      sum += (data[i] - m) * (data[i + lag] - m);
    }
    const corr = sum / v;
    // Detect peak
    if (lag >= 2 && prevCorr > corr && prevCorr > prevPrevCorr && prevCorr > 0.1) {
      peakCount++;
    }
    prevPrevCorr = prevCorr;
    prevCorr = corr;
  }

  const periodicity = clamp01(peakCount / 5);

  return clamp01(0.5 * oscillationRate + 0.5 * periodicity);
}

// 12. Recursion Depth — self-referential complexity
function computeRecursionDepth(terms) {
  if (terms.length < 10) return 0;

  // Check if terms reference their own indices
  let selfRef = 0;
  for (let i = 0; i < terms.length; i++) {
    const t = terms[i];
    if (t >= 0 && t < terms.length && t !== i) {
      // Term points to another valid index
      selfRef++;
    }
  }
  const selfRefRate = selfRef / terms.length;

  // Check nested differences structure
  let diffLevels = 0;
  let current = [...terms];
  for (let level = 0; level < 5; level++) {
    if (current.length < 3) break;
    const next = [];
    for (let i = 1; i < current.length; i++) next.push(current[i] - current[i - 1]);
    // Check if this level has interesting structure (not all zeros, not random)
    const unique = new Set(next);
    if (unique.size === 1 && next[0] === 0) break; // constant = stop
    if (unique.size < next.length * 0.3) diffLevels++; // structured
    current = next;
  }

  return clamp01(0.4 * selfRefRate + 0.6 * (diffLevels / 5));
}

// Derive a characteristic hue from a sequence
function computeSequenceHue(terms) {
  if (terms.length === 0) return 220;
  // Use first 20 terms to create a stable hue
  const sample = terms.slice(0, 20);
  let hash = 0;
  for (const t of sample) {
    hash = ((hash << 5) - hash + Math.abs(t)) | 0;
  }
  return ((hash % 360) + 360) % 360;
}

/**
 * Beauty dimension labels for display
 */
export const BEAUTY_DIMENSIONS = [
  { key: 'compressibility', label: 'compressibility', color: '#4aeadc' },
  { key: 'deltaEntropy', label: 'delta entropy', color: '#5898f0' },
  { key: 'growthDrama', label: 'growth drama', color: '#e8708a' },
  { key: 'residueStructure', label: 'residue structure', color: '#f0c060' },
  { key: 'novelty', label: 'novelty', color: '#a87aef' },
  { key: 'selfSimilarity', label: 'self-similarity', color: '#60e8a0' },
  { key: 'harmonicContent', label: 'harmonic content', color: '#f09848' },
  { key: 'dramaticArc', label: 'dramatic arc', color: '#e85878' },
  { key: 'compositionScore', label: 'composition power', color: '#c8a848' },
  { key: 'connectedness', label: 'connectedness', color: '#7888e8' },
  { key: 'waveMechanics', label: 'wave mechanics', color: '#48c8e0' },
  { key: 'recursionDepth', label: 'recursion depth', color: '#d878c0' },
];

/**
 * Compute a 2D embedding position from beauty profile
 * Uses first two principal axes of the beauty vector
 */
export function beautyToPosition(beauty) {
  // Manual PCA-like projection using interpretable axes
  // X-axis: structural-mathematical (compressibility, residue, recursion)
  // Y-axis: experiential-aesthetic (drama, harmony, composition)
  const x = (beauty.compressibility * 0.3 +
             beauty.residueStructure * 0.2 +
             beauty.selfSimilarity * 0.25 +
             beauty.recursionDepth * 0.25) * 2 - 1;

  const y = (beauty.growthDrama * 0.25 +
             beauty.harmonicContent * 0.25 +
             beauty.dramaticArc * 0.25 +
             beauty.compositionScore * 0.25) * 2 - 1;

  return { x, y };
}
