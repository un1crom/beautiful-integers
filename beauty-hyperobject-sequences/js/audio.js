/**
 * Audio — Sonification of integer sequences via Web Audio API
 *
 * Maps sequence values to musical parameters:
 *  - Pitch: mod-12 residues map to chromatic scale
 *  - Duration: first differences map to note length
 *  - Timbre: growth rate maps to harmonic content
 *  - Volume: absolute magnitude maps to dynamics
 */

export class SequenceAudio {
  constructor() {
    this.ctx = null;
    this.playing = false;
    this.currentTimeout = null;
    this.analyser = null;
    this.gainNode = null;
    this.onStop = null;
  }

  init() {
    if (this.ctx) return;
    this.ctx = new (window.AudioContext || window.webkitAudioContext)();
    this.gainNode = this.ctx.createGain();
    this.gainNode.gain.value = 0.15;

    this.analyser = this.ctx.createAnalyser();
    this.analyser.fftSize = 256;
    this.analyser.smoothingTimeConstant = 0.85;

    this.gainNode.connect(this.analyser);
    this.analyser.connect(this.ctx.destination);
  }

  /**
   * Sonify a sequence
   * @param {number[]} terms
   * @param {object} opts - { tempo, baseOctave, scale }
   */
  async play(terms, opts = {}) {
    this.stop();
    this.init();

    if (this.ctx.state === 'suspended') {
      await this.ctx.resume();
    }

    this.playing = true;

    const tempo = opts.tempo || 180; // BPM
    const beatDuration = 60 / tempo;
    const baseFreq = opts.baseFreq || 220; // A3
    const maxTerms = Math.min(terms.length, 200);

    // Determine scale mapping
    // Use pentatonic for more consonant sound
    const pentatonic = [0, 2, 4, 7, 9]; // C D E G A
    const chromatic = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
    const scale = opts.chromatic ? chromatic : pentatonic;

    const maxAbs = Math.max(...terms.map(Math.abs)) || 1;

    let noteIndex = 0;
    const playNext = () => {
      if (!this.playing || noteIndex >= maxTerms) {
        this.playing = false;
        if (this.onStop) this.onStop();
        return;
      }

      const term = terms[noteIndex];
      const absTerm = Math.abs(term);

      // Pitch: map to scale
      const scaleIdx = ((term % scale.length) + scale.length) % scale.length;
      const semitone = scale[scaleIdx];
      const octave = Math.floor(Math.log2(absTerm + 1)) % 4;
      const freq = baseFreq * Math.pow(2, (semitone + octave * 12) / 12);

      // Duration: based on difference magnitude
      const diff = noteIndex > 0 ? Math.abs(terms[noteIndex] - terms[noteIndex - 1]) : 1;
      const normalizedDiff = Math.min(diff / (maxAbs * 0.5 + 1), 2);
      const duration = beatDuration * (0.5 + normalizedDiff * 0.5);

      // Volume: based on position in sequence (fade structure)
      const t = noteIndex / maxTerms;
      const envelope = Math.sin(t * Math.PI); // natural arc
      const volume = 0.3 + 0.7 * (absTerm / maxAbs) * envelope;

      // Timbre: growth rate determines waveform blend
      const growthRate = noteIndex > 0 ?
        Math.abs(Math.log((absTerm + 1) / (Math.abs(terms[noteIndex - 1]) + 1))) : 0;
      const waveType = growthRate > 0.5 ? 'sawtooth' :
                       growthRate > 0.2 ? 'triangle' : 'sine';

      this.playNote(freq, duration * 0.8, volume, waveType);

      noteIndex++;
      this.currentTimeout = setTimeout(playNext, duration * 1000);
    };

    playNext();
  }

  playNote(freq, duration, volume, waveType = 'sine') {
    if (!this.ctx || !this.playing) return;

    const osc = this.ctx.createOscillator();
    const env = this.ctx.createGain();

    osc.type = waveType;
    osc.frequency.value = Math.max(20, Math.min(freq, 8000));

    const now = this.ctx.currentTime;
    env.gain.setValueAtTime(0, now);
    env.gain.linearRampToValueAtTime(volume * 0.15, now + 0.01);
    env.gain.exponentialRampToValueAtTime(0.001, now + duration);

    osc.connect(env);
    env.connect(this.gainNode);

    osc.start(now);
    osc.stop(now + duration + 0.05);
  }

  stop() {
    this.playing = false;
    if (this.currentTimeout) {
      clearTimeout(this.currentTimeout);
      this.currentTimeout = null;
    }
  }

  /**
   * Get waveform data for visualization
   * @returns {Uint8Array}
   */
  getWaveformData() {
    if (!this.analyser) return new Uint8Array(128);
    const data = new Uint8Array(this.analyser.frequencyBinCount);
    this.analyser.getByteTimeDomainData(data);
    return data;
  }

  /**
   * Get frequency data for visualization
   * @returns {Uint8Array}
   */
  getFrequencyData() {
    if (!this.analyser) return new Uint8Array(128);
    const data = new Uint8Array(this.analyser.frequencyBinCount);
    this.analyser.getByteFrequencyData(data);
    return data;
  }

  /**
   * Draw waveform on a canvas
   */
  drawWaveform(canvas) {
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const w = canvas.width;
    const h = canvas.height;

    ctx.fillStyle = 'rgba(6, 6, 12, 0.3)';
    ctx.fillRect(0, 0, w, h);

    if (!this.playing || !this.analyser) return;

    const data = this.getWaveformData();
    const sliceWidth = w / data.length;

    ctx.beginPath();
    ctx.strokeStyle = 'rgba(240, 192, 96, 0.6)';
    ctx.lineWidth = 1;

    for (let i = 0; i < data.length; i++) {
      const v = data[i] / 128.0;
      const y = v * h / 2;
      if (i === 0) ctx.moveTo(0, y);
      else ctx.lineTo(i * sliceWidth, y);
    }
    ctx.stroke();
  }

  destroy() {
    this.stop();
    if (this.ctx) {
      this.ctx.close();
      this.ctx = null;
    }
  }
}
