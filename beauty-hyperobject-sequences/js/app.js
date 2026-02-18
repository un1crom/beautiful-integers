/**
 * App — Main orchestration for Beauty Hyperobject Sequences
 *
 * State management, search, sequence loading, view transitions.
 * The mathematical beauty paint IS the UI.
 */

import { Cosmos } from './cosmos.js';
import { OEISClient, BEAUTIFUL_SEEDS } from './oeis.js';
import { computeBeauty, BEAUTY_DIMENSIONS, beautyToPosition } from './beauty.js';
import { VIZ_MODES, drawMiniPreview, drawBeautyRadar, drawEmbedding } from './viz.js';
import { SequenceAudio } from './audio.js';

// ═══════════════════════════════════════════════════════
// STATE
// ═══════════════════════════════════════════════════════
const state = {
  sequences: [],          // loaded sequence objects
  activeSequence: null,   // currently focused sequence
  activeVizMode: 'line',  // current visualization mode
  searchResults: [],       // current search results
  view: 'cosmos'           // 'cosmos' | 'focus' | 'embedding'
};

const oeis = new OEISClient();
const audio = new SequenceAudio();
let cosmos = null;
let waveformAnimId = null;

// ═══════════════════════════════════════════════════════
// INITIALIZATION
// ═══════════════════════════════════════════════════════
function init() {
  // Start the cosmos
  const cosmosCanvas = document.getElementById('cosmos');
  cosmos = new Cosmos(cosmosCanvas);

  // Bind events
  bindSearch();
  bindFocusView();
  bindFloatingActions();
  bindAudio();
  bindEmbedding();
  bindKeyboard();

  // Show welcome whisper
  whisper('beauty hyperobject sequences — enter an OEIS id to begin');
  setTimeout(() => whisper(''), 5000);
}

// ═══════════════════════════════════════════════════════
// SEARCH
// ═══════════════════════════════════════════════════════
function bindSearch() {
  const input = document.getElementById('search-input');
  let debounceTimer = null;

  input.addEventListener('input', () => {
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(() => handleSearch(input.value), 400);
  });

  input.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
      e.preventDefault();
      clearTimeout(debounceTimer);
      handleSearch(input.value, true);
    }
    if (e.key === 'Escape') {
      input.blur();
      hideSearchResults();
    }
  });
}

async function handleSearch(query, immediate = false) {
  query = query.trim();
  if (!query) {
    hideSearchResults();
    return;
  }

  // Direct OEIS ID load
  if (/^A?\d{6}$/i.test(query) && immediate) {
    const id = query.toUpperCase();
    const normalized = id.startsWith('A') ? id : 'A' + id;
    hideSearchResults();
    document.getElementById('search-input').value = '';
    document.getElementById('search-input').blur();
    await loadSequence(normalized);
    return;
  }

  whisper('searching...');

  try {
    const results = await oeis.search(query);
    state.searchResults = results;
    showSearchResults(results);
    whisper('');
  } catch (err) {
    whisper('search failed');
    console.error(err);
  }
}

function showSearchResults(results) {
  const container = document.getElementById('search-results');
  container.innerHTML = '';

  if (results.length === 0) {
    container.classList.remove('visible');
    return;
  }

  for (const seq of results.slice(0, 12)) {
    const item = document.createElement('div');
    item.className = 'search-result-item';
    item.innerHTML = `
      <div class="search-result-id">${seq.id}</div>
      <div class="search-result-name">${escapeHtml(seq.name)}</div>
      <div class="search-result-data">${seq.terms.slice(0, 15).join(', ')}${seq.terms.length > 15 ? ', ...' : ''}</div>
    `;
    item.addEventListener('click', () => {
      hideSearchResults();
      document.getElementById('search-input').value = '';
      document.getElementById('search-input').blur();
      loadSequence(seq.id);
    });
    container.appendChild(item);
  }

  container.classList.add('visible');
}

function hideSearchResults() {
  document.getElementById('search-results').classList.remove('visible');
}

// ═══════════════════════════════════════════════════════
// SEQUENCE LOADING
// ═══════════════════════════════════════════════════════
async function loadSequence(id) {
  id = id.toUpperCase();
  if (!id.startsWith('A')) id = 'A' + id;

  // Check if already loaded
  const existing = state.sequences.find(s => s.id === id);
  if (existing) {
    focusSequence(existing);
    return;
  }

  whisper(`loading ${id}...`);

  try {
    const seq = await oeis.loadFull(id, 500);
    if (!seq) {
      whisper(`${id} not found`);
      return;
    }

    // Get terms
    const terms = oeis.getTerms(seq, 500);

    // Compute beauty
    const beauty = computeBeauty(terms, seq.xrefs, seq.keywords);
    seq._beauty = beauty;

    // Compute embedding position
    const embedPos = beautyToPosition(beauty);

    // Build our sequence object
    const seqObj = {
      id: seq.id,
      name: seq.name,
      terms,
      keywords: seq.keywords,
      comments: seq.comments,
      formulas: seq.formulas,
      xrefs: seq.xrefs,
      author: seq.author,
      beauty,
      embedPos,
      raw: seq
    };

    state.sequences.push(seqObj);

    // Add to dock
    addDockOrb(seqObj);

    // Update cosmos influences
    updateCosmosInfluences();

    // Auto-focus the new sequence
    focusSequence(seqObj);

    whisper(`${id} materialized — beauty ${beauty.beautyIndex.toFixed(3)}`);
    setTimeout(() => whisper(''), 3000);

  } catch (err) {
    whisper(`failed to load ${id}`);
    console.error(err);
  }
}

// ═══════════════════════════════════════════════════════
// DOCK (bottom sequence orbs)
// ═══════════════════════════════════════════════════════
function addDockOrb(seq) {
  const dock = document.getElementById('sequence-dock');
  const orb = document.createElement('div');
  orb.className = 'dock-orb';
  orb.dataset.id = seq.id;
  orb.style.setProperty('--orb-color', `hsl(${seq.beauty.hue}, 60%, 55%)`);
  orb.style.boxShadow = `0 0 20px hsla(${seq.beauty.hue}, 60%, 50%, 0.3), inset 0 0 10px hsla(${seq.beauty.hue}, 40%, 30%, 0.2)`;
  orb.style.background = `radial-gradient(circle at 35% 35%, hsla(${seq.beauty.hue}, 50%, 55%, 0.8), hsla(${seq.beauty.hue}, 40%, 20%, 0.9))`;

  // Mini canvas preview
  const canvas = document.createElement('canvas');
  canvas.width = 112;
  canvas.height = 112;
  const ctx = canvas.getContext('2d');
  drawMiniPreview(ctx, 112, 112, seq.terms.slice(0, 100), seq.beauty.hue);
  orb.appendChild(canvas);

  // Label
  const label = document.createElement('div');
  label.className = 'dock-orb-label';
  label.textContent = seq.id;
  orb.appendChild(label);

  orb.addEventListener('click', () => focusSequence(seq));

  dock.appendChild(orb);
}

function updateDockActive(id) {
  const orbs = document.querySelectorAll('.dock-orb');
  for (const orb of orbs) {
    orb.classList.toggle('active', orb.dataset.id === id);
  }
}

// ═══════════════════════════════════════════════════════
// FOCUS VIEW
// ═══════════════════════════════════════════════════════
function bindFocusView() {
  document.getElementById('focus-close').addEventListener('click', closeFocus);
}

function focusSequence(seq) {
  state.activeSequence = seq;
  state.view = 'focus';
  updateDockActive(seq.id);

  // Header
  document.getElementById('focus-id').textContent = seq.id;
  document.getElementById('focus-name').textContent = seq.name;
  document.getElementById('focus-keywords').textContent = seq.keywords.join('  ');

  // Visualization
  renderVisualization(seq, state.activeVizMode);
  buildVizModeStrip(seq);

  // Beauty panel
  renderBeautyRadar(seq);
  renderBeautyScores(seq);
  renderCompositionType(seq);
  renderXrefs(seq);
  renderComments(seq);

  // Show
  document.getElementById('focus-view').classList.remove('hidden');
}

function closeFocus() {
  state.view = 'cosmos';
  document.getElementById('focus-view').classList.add('hidden');
  audio.stop();
}

function renderVisualization(seq, modeKey) {
  const canvas = document.getElementById('viz-canvas');
  const dpr = Math.min(window.devicePixelRatio || 1, 2);
  const rect = canvas.getBoundingClientRect();
  canvas.width = rect.width * dpr;
  canvas.height = rect.height * dpr;
  const ctx = canvas.getContext('2d');
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);

  const mode = VIZ_MODES.find(m => m.key === modeKey);
  if (mode) {
    mode.fn(ctx, rect.width, rect.height, seq.terms, {
      hue: seq.beauty.hue,
      modulus: 12
    });
  }
}

function buildVizModeStrip(seq) {
  const strip = document.getElementById('viz-mode-strip');
  strip.innerHTML = '';

  for (const mode of VIZ_MODES) {
    const btn = document.createElement('button');
    btn.className = 'viz-mode-btn' + (mode.key === state.activeVizMode ? ' active' : '');
    btn.textContent = mode.label;
    btn.addEventListener('click', () => {
      state.activeVizMode = mode.key;
      renderVisualization(seq, mode.key);
      strip.querySelectorAll('.viz-mode-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
    });
    strip.appendChild(btn);
  }
}

function renderBeautyRadar(seq) {
  const canvas = document.getElementById('beauty-radar');
  const dpr = Math.min(window.devicePixelRatio || 1, 2);
  const rect = canvas.getBoundingClientRect();
  canvas.width = rect.width * dpr;
  canvas.height = rect.height * dpr;
  const ctx = canvas.getContext('2d');
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);

  drawBeautyRadar(ctx, rect.width, rect.height, seq.beauty, BEAUTY_DIMENSIONS);
}

function renderBeautyScores(seq) {
  const container = document.getElementById('beauty-scores');
  container.innerHTML = '';

  for (const dim of BEAUTY_DIMENSIONS) {
    const val = seq.beauty[dim.key] || 0;
    const row = document.createElement('div');
    row.className = 'beauty-score-row';
    row.innerHTML = `
      <span class="beauty-score-label">${dim.label}</span>
      <div class="beauty-score-bar">
        <div class="beauty-score-fill" style="width: ${val * 100}%; background: ${dim.color}; color: ${dim.color};"></div>
      </div>
      <span class="beauty-score-value">${val.toFixed(3)}</span>
    `;
    container.appendChild(row);
  }
}

function renderCompositionType(seq) {
  const container = document.getElementById('composition-type');
  container.innerHTML = `
    <div class="comp-type-label">compositional archetype</div>
    <div class="comp-type-name">${seq.beauty.compositionType || 'unknown'}</div>
    <div class="comp-type-desc">${seq.beauty.compositionDescription || ''}</div>
  `;
}

function renderXrefs(seq) {
  const container = document.getElementById('xref-network');
  if (!seq.xrefs || seq.xrefs.length === 0) {
    container.innerHTML = '';
    return;
  }

  const tags = seq.xrefs.slice(0, 30).map(id =>
    `<span class="xref-tag" data-id="${id}">${id}</span>`
  ).join('');

  container.innerHTML = `
    <div class="xref-title">cross-references (${seq.xrefs.length})</div>
    <div class="xref-tags">${tags}</div>
  `;

  // Click handlers
  container.querySelectorAll('.xref-tag').forEach(tag => {
    tag.addEventListener('click', () => {
      closeFocus();
      loadSequence(tag.dataset.id);
    });
  });
}

function renderComments(seq) {
  const container = document.getElementById('sequence-comments');
  if (!seq.comments || seq.comments.length === 0) {
    container.textContent = '';
    return;
  }
  container.textContent = seq.comments.slice(0, 5).join('\n\n');
}

// ═══════════════════════════════════════════════════════
// AUDIO
// ═══════════════════════════════════════════════════════
function bindAudio() {
  const btnSonify = document.getElementById('btn-sonify');
  const btnStop = document.getElementById('btn-stop-audio');
  const waveformCanvas = document.getElementById('audio-waveform');

  const dpr = Math.min(window.devicePixelRatio || 1, 2);
  waveformCanvas.width = 240 * dpr;
  waveformCanvas.height = 72 * dpr;
  const wctx = waveformCanvas.getContext('2d');
  wctx.setTransform(dpr, 0, 0, dpr, 0, 0);

  btnSonify.addEventListener('click', () => {
    if (!state.activeSequence) return;

    if (audio.playing) {
      audio.stop();
      btnSonify.classList.remove('playing');
      btnStop.classList.add('hidden');
      return;
    }

    audio.play(state.activeSequence.terms);
    btnSonify.classList.add('playing');
    btnStop.classList.remove('hidden');

    audio.onStop = () => {
      btnSonify.classList.remove('playing');
      btnStop.classList.add('hidden');
      cancelAnimationFrame(waveformAnimId);
    };

    // Waveform animation
    const drawWave = () => {
      if (!audio.playing) return;
      audio.drawWaveform(waveformCanvas);
      waveformAnimId = requestAnimationFrame(drawWave);
    };
    drawWave();
  });

  btnStop.addEventListener('click', () => {
    audio.stop();
    btnSonify.classList.remove('playing');
    btnStop.classList.add('hidden');
  });
}

// ═══════════════════════════════════════════════════════
// EMBEDDING VIEW
// ═══════════════════════════════════════════════════════
function bindEmbedding() {
  document.getElementById('embedding-close').addEventListener('click', closeEmbedding);
}

function showEmbedding() {
  if (state.sequences.length === 0) {
    whisper('load some sequences first');
    setTimeout(() => whisper(''), 2000);
    return;
  }

  state.view = 'embedding';
  const view = document.getElementById('embedding-view');
  view.classList.remove('hidden');

  const canvas = document.getElementById('embedding-canvas');
  const dpr = Math.min(window.devicePixelRatio || 1, 2);
  canvas.width = window.innerWidth * dpr;
  canvas.height = window.innerHeight * dpr;
  const ctx = canvas.getContext('2d');
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);

  drawEmbedding(ctx, window.innerWidth, window.innerHeight, state.sequences);
}

function closeEmbedding() {
  state.view = 'cosmos';
  document.getElementById('embedding-view').classList.add('hidden');
}

// ═══════════════════════════════════════════════════════
// FLOATING ACTIONS
// ═══════════════════════════════════════════════════════
function bindFloatingActions() {
  document.getElementById('btn-embedding').addEventListener('click', showEmbedding);
  document.getElementById('btn-random').addEventListener('click', loadRandomBeautiful);
}

async function loadRandomBeautiful() {
  // Pick a random seed that isn't already loaded
  const loaded = new Set(state.sequences.map(s => s.id));
  const available = BEAUTIFUL_SEEDS.filter(id => !loaded.has(id));

  if (available.length === 0) {
    // Generate a random A-number
    const num = Math.floor(Math.random() * 300000) + 1;
    const id = 'A' + String(num).padStart(6, '0');
    await loadSequence(id);
    return;
  }

  const id = available[Math.floor(Math.random() * available.length)];
  await loadSequence(id);
}

// ═══════════════════════════════════════════════════════
// KEYBOARD
// ═══════════════════════════════════════════════════════
function bindKeyboard() {
  document.addEventListener('keydown', (e) => {
    // Escape closes views
    if (e.key === 'Escape') {
      if (state.view === 'embedding') closeEmbedding();
      else if (state.view === 'focus') closeFocus();
    }

    // Don't handle shortcuts when typing in search
    if (document.activeElement === document.getElementById('search-input')) return;

    // Space: toggle audio
    if (e.key === ' ' && state.view === 'focus') {
      e.preventDefault();
      document.getElementById('btn-sonify').click();
    }

    // Arrow keys: cycle viz modes in focus view
    if (state.view === 'focus' && state.activeSequence) {
      if (e.key === 'ArrowRight' || e.key === 'ArrowLeft') {
        e.preventDefault();
        const currentIdx = VIZ_MODES.findIndex(m => m.key === state.activeVizMode);
        const dir = e.key === 'ArrowRight' ? 1 : -1;
        const newIdx = (currentIdx + dir + VIZ_MODES.length) % VIZ_MODES.length;
        state.activeVizMode = VIZ_MODES[newIdx].key;
        renderVisualization(state.activeSequence, state.activeVizMode);

        const strip = document.getElementById('viz-mode-strip');
        strip.querySelectorAll('.viz-mode-btn').forEach((btn, i) => {
          btn.classList.toggle('active', i === newIdx);
        });
      }
    }

    // R: random sequence
    if (e.key === 'r' && state.view === 'cosmos') {
      loadRandomBeautiful();
    }

    // E: embedding view
    if (e.key === 'e' && state.view !== 'focus') {
      showEmbedding();
    }

    // /: focus search
    if (e.key === '/' && state.view === 'cosmos') {
      e.preventDefault();
      document.getElementById('search-input').focus();
    }
  });
}

// ═══════════════════════════════════════════════════════
// COSMOS INFLUENCES
// ═══════════════════════════════════════════════════════
function updateCosmosInfluences() {
  const influences = state.sequences.map((seq, i) => ({
    hue: seq.beauty.hue,
    x: window.innerWidth * (0.3 + (i / Math.max(1, state.sequences.length - 1)) * 0.4),
    y: window.innerHeight * (0.4 + Math.sin(i * 1.5) * 0.15),
    phase: i * 1.7
  }));
  cosmos.setInfluences(influences);
}

// ═══════════════════════════════════════════════════════
// UTILITIES
// ═══════════════════════════════════════════════════════
function whisper(msg) {
  const el = document.getElementById('status-whisper');
  el.textContent = msg;
  el.classList.toggle('visible', !!msg);
}

function escapeHtml(str) {
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}

// Handle click outside search results
document.addEventListener('click', (e) => {
  const portal = document.getElementById('search-portal');
  const results = document.getElementById('search-results');
  if (!portal.contains(e.target) && !results.contains(e.target)) {
    hideSearchResults();
  }
});

// ═══════════════════════════════════════════════════════
// BOOT
// ═══════════════════════════════════════════════════════
document.addEventListener('DOMContentLoaded', init);

// Handle window resize for focus view
window.addEventListener('resize', () => {
  if (state.view === 'focus' && state.activeSequence) {
    renderVisualization(state.activeSequence, state.activeVizMode);
    renderBeautyRadar(state.activeSequence);
  }
  if (state.view === 'embedding') {
    showEmbedding();
  }
});
