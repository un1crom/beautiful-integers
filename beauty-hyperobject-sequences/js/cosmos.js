/**
 * Cosmos — Living flow field particle background
 *
 * A Perlin-noise driven particle system that fills the void
 * and responds to loaded sequences. The mathematical substrate
 * of the entire interface.
 */

// Simplex noise (compact implementation)
const GRAD3 = [
  [1,1,0],[-1,1,0],[1,-1,0],[-1,-1,0],
  [1,0,1],[-1,0,1],[1,0,-1],[-1,0,-1],
  [0,1,1],[0,-1,1],[0,1,-1],[0,-1,-1]
];
const PERM = new Uint8Array(512);
const P = [151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,30,
  69,142,8,99,37,240,21,10,23,190,6,148,247,120,234,75,0,26,197,62,94,252,
  219,203,117,35,11,32,57,177,33,88,237,149,56,87,174,20,125,136,171,168,
  68,175,74,165,71,134,139,48,27,166,77,146,158,231,83,111,229,122,60,211,
  133,230,220,105,92,41,55,46,245,40,244,102,143,54,65,25,63,161,1,216,
  80,73,209,76,132,187,208,89,18,169,200,196,135,130,116,188,159,86,164,
  100,109,198,173,186,3,64,52,217,226,250,124,123,5,202,38,147,118,126,
  255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,223,183,170,213,
  119,248,152,2,44,154,163,70,221,153,101,155,167,43,172,9,129,22,39,253,
  19,98,108,110,79,113,224,232,178,185,112,104,218,246,97,228,251,34,242,
  193,238,210,144,12,191,179,162,241,81,51,145,235,249,14,239,107,49,192,
  214,31,181,199,106,157,184,84,204,176,115,121,50,45,127,4,150,254,138,
  236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180];

for (let i = 0; i < 512; i++) PERM[i] = P[i & 255];

function dot3(g, x, y, z) { return g[0]*x + g[1]*y + g[2]*z; }

function simplex3(xin, yin, zin) {
  const F3 = 1/3, G3 = 1/6;
  const s = (xin + yin + zin) * F3;
  const i = Math.floor(xin + s);
  const j = Math.floor(yin + s);
  const k = Math.floor(zin + s);
  const t = (i + j + k) * G3;
  const x0 = xin - (i - t);
  const y0 = yin - (j - t);
  const z0 = zin - (k - t);

  let i1,j1,k1,i2,j2,k2;
  if (x0 >= y0) {
    if (y0 >= z0) { i1=1;j1=0;k1=0;i2=1;j2=1;k2=0; }
    else if (x0 >= z0) { i1=1;j1=0;k1=0;i2=1;j2=0;k2=1; }
    else { i1=0;j1=0;k1=1;i2=1;j2=0;k2=1; }
  } else {
    if (y0 < z0) { i1=0;j1=0;k1=1;i2=0;j2=1;k2=1; }
    else if (x0 < z0) { i1=0;j1=1;k1=0;i2=0;j2=1;k2=1; }
    else { i1=0;j1=1;k1=0;i2=1;j2=1;k2=0; }
  }

  const x1=x0-i1+G3, y1=y0-j1+G3, z1=z0-k1+G3;
  const x2=x0-i2+2*G3, y2=y0-j2+2*G3, z2=z0-k2+2*G3;
  const x3=x0-1+3*G3, y3=y0-1+3*G3, z3=z0-1+3*G3;

  const ii=i&255, jj=j&255, kk=k&255;
  const gi0 = PERM[ii+PERM[jj+PERM[kk]]] % 12;
  const gi1 = PERM[ii+i1+PERM[jj+j1+PERM[kk+k1]]] % 12;
  const gi2 = PERM[ii+i2+PERM[jj+j2+PERM[kk+k2]]] % 12;
  const gi3 = PERM[ii+1+PERM[jj+1+PERM[kk+1]]] % 12;

  let n0=0, n1=0, n2=0, n3=0;
  let t0 = 0.5 - x0*x0 - y0*y0 - z0*z0;
  if (t0 >= 0) { t0 *= t0; n0 = t0*t0*dot3(GRAD3[gi0], x0, y0, z0); }
  let t1 = 0.5 - x1*x1 - y1*y1 - z1*z1;
  if (t1 >= 0) { t1 *= t1; n1 = t1*t1*dot3(GRAD3[gi1], x1, y1, z1); }
  let t2 = 0.5 - x2*x2 - y2*y2 - z2*z2;
  if (t2 >= 0) { t2 *= t2; n2 = t2*t2*dot3(GRAD3[gi2], x2, y2, z2); }
  let t3 = 0.5 - x3*x3 - y3*y3 - z3*z3;
  if (t3 >= 0) { t3 *= t3; n3 = t3*t3*dot3(GRAD3[gi3], x3, y3, z3); }

  return 32 * (n0 + n1 + n2 + n3);
}

export class Cosmos {
  constructor(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.particles = [];
    this.time = 0;
    this.mouse = { x: -1000, y: -1000 };
    this.sequenceInfluences = []; // beauty colors from loaded sequences
    this.baseHue = 220;
    this.running = true;

    this.resize();
    this.initParticles();
    this.bindEvents();
    this.animate();
  }

  resize() {
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    this.width = window.innerWidth;
    this.height = window.innerHeight;
    this.canvas.width = this.width * dpr;
    this.canvas.height = this.height * dpr;
    this.canvas.style.width = this.width + 'px';
    this.canvas.style.height = this.height + 'px';
    this.ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  }

  initParticles() {
    const density = Math.min(this.width * this.height / 3200, 800);
    this.particles = [];
    for (let i = 0; i < density; i++) {
      this.particles.push({
        x: Math.random() * this.width,
        y: Math.random() * this.height,
        vx: 0,
        vy: 0,
        life: Math.random(),
        size: 0.5 + Math.random() * 1.5,
        hueOffset: Math.random() * 60 - 30
      });
    }
  }

  bindEvents() {
    window.addEventListener('resize', () => {
      this.resize();
      this.initParticles();
    });

    const onMove = (x, y) => {
      this.mouse.x = x;
      this.mouse.y = y;
    };

    window.addEventListener('mousemove', e => onMove(e.clientX, e.clientY));
    window.addEventListener('touchmove', e => {
      if (e.touches.length) onMove(e.touches[0].clientX, e.touches[0].clientY);
    }, { passive: true });
  }

  setInfluences(influences) {
    this.sequenceInfluences = influences;
    if (influences.length > 0) {
      this.baseHue = influences[0].hue || 220;
    }
  }

  getFlowAngle(x, y) {
    const scale = 0.003;
    const n = simplex3(x * scale, y * scale, this.time * 0.15);
    return n * Math.PI * 2;
  }

  animate() {
    if (!this.running) return;
    requestAnimationFrame(() => this.animate());

    this.time += 0.008;
    const ctx = this.ctx;

    // Fade trail
    ctx.fillStyle = 'rgba(6, 6, 12, 0.06)';
    ctx.fillRect(0, 0, this.width, this.height);

    // Compute influence color
    const influences = this.sequenceInfluences;
    const hue = this.baseHue + Math.sin(this.time * 0.3) * 15;

    for (const p of this.particles) {
      // Flow field
      const angle = this.getFlowAngle(p.x, p.y);
      const speed = 0.6;
      p.vx += Math.cos(angle) * speed * 0.1;
      p.vy += Math.sin(angle) * speed * 0.1;

      // Mouse repulsion
      const dx = p.x - this.mouse.x;
      const dy = p.y - this.mouse.y;
      const dist = Math.sqrt(dx * dx + dy * dy);
      if (dist < 150) {
        const force = (150 - dist) / 150 * 0.5;
        p.vx += (dx / dist) * force;
        p.vy += (dy / dist) * force;
      }

      // Damping
      p.vx *= 0.92;
      p.vy *= 0.92;

      p.x += p.vx;
      p.y += p.vy;

      // Wrap
      if (p.x < -10) p.x = this.width + 10;
      if (p.x > this.width + 10) p.x = -10;
      if (p.y < -10) p.y = this.height + 10;
      if (p.y > this.height + 10) p.y = -10;

      // Draw
      const speed2 = Math.sqrt(p.vx * p.vx + p.vy * p.vy);
      const alpha = Math.min(0.7, 0.1 + speed2 * 0.15);
      const particleHue = hue + p.hueOffset;
      const sat = 40 + speed2 * 20;
      const light = 50 + speed2 * 15;

      ctx.beginPath();
      ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
      ctx.fillStyle = `hsla(${particleHue}, ${sat}%, ${light}%, ${alpha})`;
      ctx.fill();

      // Trail
      if (speed2 > 0.3) {
        ctx.beginPath();
        ctx.moveTo(p.x, p.y);
        ctx.lineTo(p.x - p.vx * 3, p.y - p.vy * 3);
        ctx.strokeStyle = `hsla(${particleHue}, ${sat}%, ${light}%, ${alpha * 0.3})`;
        ctx.lineWidth = p.size * 0.5;
        ctx.stroke();
      }
    }

    // Sequence influence glow spots
    for (const inf of influences) {
      const gx = inf.x || this.width * 0.5;
      const gy = inf.y || this.height * 0.5;
      const pulse = 0.5 + 0.5 * Math.sin(this.time * 2 + inf.phase);
      const radius = 80 + pulse * 40;
      const grad = ctx.createRadialGradient(gx, gy, 0, gx, gy, radius);
      grad.addColorStop(0, `hsla(${inf.hue}, 60%, 60%, ${0.03 * pulse})`);
      grad.addColorStop(1, 'transparent');
      ctx.fillStyle = grad;
      ctx.fillRect(gx - radius, gy - radius, radius * 2, radius * 2);
    }
  }

  destroy() {
    this.running = false;
  }
}
