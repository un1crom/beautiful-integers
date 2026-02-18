/**
 * OEIS — Client for the Online Encyclopedia of Integer Sequences
 *
 * Proxied through our Python server to avoid CORS.
 * Falls back to embedded seed data when OEIS is unreachable.
 * Parses OEIS JSON format into clean sequence objects.
 */

import { SEED_DATA } from './seeds.js';

export class OEISClient {
  constructor(baseUrl = '') {
    this.baseUrl = baseUrl;
    this.cache = new Map();
  }

  /**
   * Search OEIS by keyword, sequence values, or ID
   * @param {string} query
   * @returns {Promise<Array>} parsed sequence results
   */
  async search(query) {
    query = query.trim();
    if (!query) return [];

    // If it looks like an OEIS ID, fetch directly
    if (/^A?\d{6}$/i.test(query)) {
      const id = query.toUpperCase();
      const normalized = id.startsWith('A') ? id : 'A' + id;
      const seq = await this.fetchSequence(normalized);
      return seq ? [seq] : [];
    }

    // Try API first
    const url = `${this.baseUrl}/api/search?q=${encodeURIComponent(query)}`;
    try {
      const resp = await fetch(url);
      if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
      const data = await resp.json();
      if (!data) return []; // OEIS returns null for no-result searches
      if (data.results && Array.isArray(data.results)) {
        return data.results.map(r => this.parseResult(r)).filter(Boolean);
      }
      if (data.error) throw new Error(data.error);
      return [];
    } catch (err) {
      console.warn('OEIS search error, falling back to seeds:', err.message);
      // Fallback: search seed data by name
      const q = query.toLowerCase();
      const matches = Object.entries(SEED_DATA)
        .filter(([id, s]) => s.name.toLowerCase().includes(q) || id.toLowerCase().includes(q))
        .map(([id, s]) => this.parseResult({ ...s, number: parseInt(id.slice(1)) }))
        .filter(Boolean);
      return matches;
    }
  }

  /**
   * Fetch a specific sequence by ID
   * @param {string} id e.g. "A000045"
   * @returns {Promise<Object|null>}
   */
  async fetchSequence(id) {
    id = id.toUpperCase();
    if (this.cache.has(id)) return this.cache.get(id);

    // Try API first
    const url = `${this.baseUrl}/api/sequence/${id}`;
    try {
      const resp = await fetch(url);
      if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
      const data = await resp.json();
      if (!data) return null; // OEIS returns null for unknown sequences
      if (data.results && data.results.length > 0) {
        const seq = this.parseResult(data.results[0]);
        if (seq) this.cache.set(id, seq);
        return seq;
      }
      if (data.error) throw new Error(data.error);
      return null;
    } catch (err) {
      console.warn(`OEIS fetch error for ${id}, trying seeds:`, err.message);
      // Fallback to seed data
      if (SEED_DATA[id]) {
        const raw = SEED_DATA[id];
        const seq = this.parseResult({ ...raw, number: parseInt(id.slice(1)) });
        if (seq) this.cache.set(id, seq);
        return seq;
      }
      return null;
    }
  }

  /**
   * Fetch extended terms from b-file
   * @param {string} id
   * @param {number} n max terms
   * @returns {Promise<number[]>}
   */
  async fetchBFile(id, n = 1000) {
    id = id.toUpperCase();
    const url = `${this.baseUrl}/api/bfile/${id}?n=${n}`;
    try {
      const resp = await fetch(url);
      if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
      const data = await resp.json();
      return data.terms || [];
    } catch (err) {
      console.error(`B-file fetch error for ${id}:`, err);
      return [];
    }
  }

  /**
   * Parse a raw OEIS JSON result into a clean object
   */
  parseResult(raw) {
    if (!raw) return null;

    const number = raw.number;
    const id = 'A' + String(number).padStart(6, '0');

    // Parse data string into array of integers
    let terms = [];
    if (raw.data) {
      terms = raw.data.split(',').map(s => {
        const n = parseInt(s.trim(), 10);
        return isNaN(n) ? 0 : n;
      });
    }

    // Parse cross-references
    const xrefs = this.parseXrefs(raw.xref || []);

    // Parse keywords
    const keywords = (raw.keyword || '').split(',').map(k => k.trim()).filter(Boolean);

    return {
      id,
      number,
      name: raw.name || '',
      terms,
      offset: raw.offset || '0,1',
      comments: Array.isArray(raw.comment) ? raw.comment : [],
      references: Array.isArray(raw.reference) ? raw.reference : [],
      links: Array.isArray(raw.link) ? raw.link : [],
      formulas: Array.isArray(raw.formula) ? raw.formula : [],
      examples: Array.isArray(raw.example) ? raw.example : [],
      programs: Array.isArray(raw.program) ? raw.program : [],
      xrefs,
      xrefRaw: Array.isArray(raw.xref) ? raw.xref : [],
      keywords,
      author: raw.author || '',
      extensions: Array.isArray(raw.extensions) ? raw.extensions : [],
      // Computed
      _loaded: true,
      _extendedTerms: null,  // filled when b-file fetched
      _beauty: null           // filled by beauty computation
    };
  }

  /**
   * Extract A-number cross-references from xref lines
   */
  parseXrefs(xrefLines) {
    const ids = new Set();
    const text = Array.isArray(xrefLines) ? xrefLines.join(' ') : String(xrefLines);
    const matches = text.matchAll(/A(\d{6})/g);
    for (const m of matches) {
      ids.add('A' + m[1]);
    }
    return [...ids];
  }

  /**
   * Load a sequence fully: metadata + extended terms from b-file
   */
  async loadFull(id, maxTerms = 500) {
    const seq = await this.fetchSequence(id);
    if (!seq) return null;

    // Try to get more terms from b-file
    if (seq.terms.length < maxTerms) {
      const extended = await this.fetchBFile(id, maxTerms);
      if (extended.length > seq.terms.length) {
        seq._extendedTerms = extended;
      }
    }

    return seq;
  }

  /**
   * Get the best available terms for a sequence
   */
  getTerms(seq, maxTerms = 500) {
    if (seq._extendedTerms && seq._extendedTerms.length > seq.terms.length) {
      return seq._extendedTerms.slice(0, maxTerms);
    }
    return seq.terms.slice(0, maxTerms);
  }
}

// Known beautiful sequences for random exploration
export const BEAUTIFUL_SEEDS = [
  'A000045', // Fibonacci
  'A000040', // Primes
  'A000041', // Partitions
  'A005132', // Recaman
  'A000002', // Kolakoski
  'A000108', // Catalan
  'A000079', // Powers of 2
  'A000142', // Factorials
  'A001006', // Motzkin
  'A000110', // Bell numbers
  'A000203', // Sigma (sum of divisors)
  'A005117', // Squarefree numbers
  'A001222', // Big omega (prime factor count with multiplicity)
  'A000120', // Binary weight
  'A010060', // Thue-Morse
  'A014577', // Dragon curve
  'A006519', // 2-adic valuation
  'A003188', // Gray code
  'A000035', // Period 2: 0,1,0,1,...
  'A001511', // Ruler sequence
  'A007318', // Pascal's triangle
  'A135021', // User's referenced sequence
  'A000290', // Perfect squares
  'A000217', // Triangular numbers
  'A001358', // Semiprimes
  'A005150', // Look-and-say
  'A006577', // Collatz steps
  'A000396', // Perfect numbers
  'A001065', // Sum of proper divisors
  'A000961', // Prime powers
  'A002378', // Oblong numbers
  'A000984', // Central binomial coefficients
  'A279212', // Parity fractal sequence
];
