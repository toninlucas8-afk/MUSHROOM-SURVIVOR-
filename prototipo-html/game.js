'use strict';
// Mushroom Survivor — prototipo. Tutto disegnato a codice su canvas, nessun asset esterno.
(() => {
  const cv = document.getElementById('game');
  const ctx = cv.getContext('2d');
  let W = 0, H = 0, DPR = 1;

  function resize() {
    DPR = Math.min(window.devicePixelRatio || 1, 2);
    W = window.innerWidth; H = window.innerHeight;
    cv.width = Math.floor(W * DPR); cv.height = Math.floor(H * DPR);
    cv.style.width = W + 'px'; cv.style.height = H + 'px';
    ctx.setTransform(DPR, 0, 0, DPR, 0, 0);
  }
  window.addEventListener('resize', resize);
  resize();

  // ---------- utilità ----------
  const rand = (a, b) => a + Math.random() * (b - a);
  const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
  const pick = (arr) => arr[(Math.random() * arr.length) | 0];
  const TAU = Math.PI * 2;
  function shuffle(a) { for (let i = a.length - 1; i > 0; i--) { const j = (Math.random() * (i + 1)) | 0; [a[i], a[j]] = [a[j], a[i]]; } return a; }
  function fmtTime(s) { s = Math.floor(s); return String(Math.floor(s / 60)).padStart(2, '0') + ':' + String(s % 60).padStart(2, '0'); }
  function store(k, v) { try { if (v === undefined) return localStorage.getItem(k); localStorage.setItem(k, v); } catch (e) { return null; } }

  // ---------- audio sintetizzato ----------
  const AU = {
    ac: null, master: null, musicOn: true, musicNodes: null, lastHit: 0, arpTimer: null,
    init() {
      if (this.ac) { if (this.ac.state === 'suspended') this.ac.resume(); return; }
      const AC = window.AudioContext || window.webkitAudioContext;
      if (!AC) return;
      this.ac = new AC();
      this.master = this.ac.createGain(); this.master.gain.value = 0.35; this.master.connect(this.ac.destination);
      if (this.musicOn) this.startMusic();
    },
    blip(freq, dur = 0.08, type = 'sine', vol = 0.2, slide = 0) {
      if (!this.ac) return;
      const t = this.ac.currentTime, o = this.ac.createOscillator(), g = this.ac.createGain();
      o.type = type; o.frequency.setValueAtTime(freq, t);
      if (slide) o.frequency.exponentialRampToValueAtTime(Math.max(30, freq * slide), t + dur);
      g.gain.setValueAtTime(vol, t); g.gain.exponentialRampToValueAtTime(0.001, t + dur);
      o.connect(g); g.connect(this.master); o.start(t); o.stop(t + dur + 0.02);
    },
    hit() { const n = performance.now(); if (n - this.lastHit < 45) return; this.lastHit = n; this.blip(rand(180, 260), 0.06, 'square', 0.05, 0.5); },
    startMusic() {
      if (!this.ac || this.musicNodes) return;
      const ac = this.ac, out = ac.createGain(); out.gain.value = 0.18; out.connect(this.master);
      const filt = ac.createBiquadFilter(); filt.type = 'lowpass'; filt.frequency.value = 600; filt.Q.value = 8; filt.connect(out);
      const lfo = ac.createOscillator(), lfoG = ac.createGain(); lfo.frequency.value = 0.13; lfoG.gain.value = 450;
      lfo.connect(lfoG); lfoG.connect(filt.frequency); lfo.start();
      const oscs = [55, 55.4, 82.4, 110.3].map((f, i) => {
        const o = ac.createOscillator(); o.type = i % 2 ? 'sawtooth' : 'triangle'; o.frequency.value = f; o.connect(filt); o.start(); return o;
      });
      this.musicNodes = { out, oscs, lfo };
      const scale = [220, 247, 277, 330, 370, 440, 494, 554, 660, 740];
      this.arpTimer = setInterval(() => {
        if (state !== 'play' || Math.random() < 0.35) return;
        this.blip(pick(scale) * (Math.random() < 0.2 ? 2 : 1), 0.5, 'sine', 0.05);
      }, 260);
    },
    stopMusic() {
      if (!this.musicNodes) return;
      this.musicNodes.oscs.forEach(o => o.stop()); this.musicNodes.lfo.stop(); this.musicNodes.out.disconnect();
      this.musicNodes = null; clearInterval(this.arpTimer);
    },
    toggleMusic() { this.musicOn = !this.musicOn; if (this.musicOn) this.startMusic(); else this.stopMusic(); },
  };

  // ---------- input ----------
  const keys = new Set();
  const touch = { active: false, id: null, ox: 0, oy: 0, x: 0, y: 0 };
  window.addEventListener('keydown', (e) => {
    const k = e.key.toLowerCase();
    keys.add(k);
    if (['arrowup', 'arrowdown', 'arrowleft', 'arrowright', ' '].includes(k)) e.preventDefault();
    if ((k === 'p' || k === 'escape') && (state === 'play' || state === 'pause')) togglePause();
    if (k === 'm') AU.toggleMusic();
    if (state === 'levelup' && ['1', '2', '3'].includes(k)) chooseUpgrade(+k - 1);
    if (k === 'enter' && (state === 'menu' || state === 'over')) startGame();
  });
  window.addEventListener('keyup', (e) => keys.delete(e.key.toLowerCase()));
  window.addEventListener('blur', () => { keys.clear(); if (state === 'play') togglePause(); });
  cv.addEventListener('touchstart', (e) => {
    const t = e.changedTouches[0];
    Object.assign(touch, { active: true, id: t.identifier, ox: t.clientX, oy: t.clientY, x: t.clientX, y: t.clientY });
    e.preventDefault();
  }, { passive: false });
  cv.addEventListener('touchmove', (e) => {
    for (const t of e.changedTouches) if (t.identifier === touch.id) { touch.x = t.clientX; touch.y = t.clientY; }
    e.preventDefault();
  }, { passive: false });
  const endTouch = (e) => { for (const t of e.changedTouches) if (t.identifier === touch.id) touch.active = false; };
  cv.addEventListener('touchend', endTouch); cv.addEventListener('touchcancel', endTouch);

  function moveInput() {
    let x = 0, y = 0;
    if (keys.has('a') || keys.has('arrowleft')) x -= 1;
    if (keys.has('d') || keys.has('arrowright')) x += 1;
    if (keys.has('w') || keys.has('arrowup')) y -= 1;
    if (keys.has('s') || keys.has('arrowdown')) y += 1;
    if (touch.active) {
      const dx = touch.x - touch.ox, dy = touch.y - touch.oy, d = Math.hypot(dx, dy);
      if (d > 8) { const m = Math.min(1, d / 60); x = dx / d * m; y = dy / d * m; }
    }
    const l = Math.hypot(x, y);
    if (l > 1) { x /= l; y /= l; }
    return { x, y };
  }

  // ---------- griglia spaziale per le collisioni ----------
  const CELL = 64;
  let grid = new Map();
  const cellKey = (cx, cy) => (cx + 50000) * 100000 + (cy + 50000);
  function buildGrid() {
    grid = new Map();
    for (const e of G.enemies) {
      const k = cellKey(Math.floor(e.x / CELL), Math.floor(e.y / CELL));
      let c = grid.get(k); if (!c) { c = []; grid.set(k, c); } c.push(e);
    }
  }
  function queryEnemies(x, y, r, cb) {
    const x0 = Math.floor((x - r) / CELL), x1 = Math.floor((x + r) / CELL);
    const y0 = Math.floor((y - r) / CELL), y1 = Math.floor((y + r) / CELL);
    for (let cx = x0; cx <= x1; cx++) for (let cy = y0; cy <= y1; cy++) {
      const c = grid.get(cellKey(cx, cy)); if (!c) continue;
      for (const e of c) if (!e.dead && cb(e) === false) return;
    }
  }
  function nearestEnemies(x, y, n, maxD = 700) {
    const list = [];
    for (const e of G.enemies) {
      if (e.dead) continue;
      const d = (e.x - x) ** 2 + (e.y - y) ** 2;
      if (d < maxD * maxD) list.push([d, e]);
    }
    list.sort((a, b) => a[0] - b[0]);
    return list.slice(0, n).map(v => v[1]);
  }

  // ---------- armi ----------
  const WEAPONS = {
    spore: {
      name: 'Spore Lisergiche', icon: '🍄', hue: 320, max: 6,
      desc: (l) => l === 1 ? 'Spara spore al nemico più vicino.' : ['', '', '+1 spora, +danno', '+danno, più veloce', 'Le spore trapassano 2 nemici', '+1 spora, +danno', 'Raffica rapida e potentissima'][l],
      update(dt, l, s) {
        s.cd = (s.cd || 0) - dt;
        if (s.cd > 0) return;
        const targets = nearestEnemies(P.x, P.y, 1 + Math.floor(l / 2) + (l >= 6 ? 1 : 0));
        if (!targets.length) return;
        s.cd = (0.85 - 0.06 * l) * P.cd;
        for (const t of targets) {
          const a = Math.atan2(t.y - P.y, t.x - P.x), sp = 430;
          G.projs.push({ x: P.x, y: P.y, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp, r: 6 * P.area, dmg: (8 + 3.5 * l) * P.dmg,
            life: 1.4, pierce: l >= 4 ? 2 : 1, hue: rand(280, 360), hit: new Set(), kind: 'spore' });
        }
        AU.blip(rand(600, 760), 0.05, 'sine', 0.04, 1.6);
      },
    },
    orbit: {
      name: 'Anello di Funghetti', icon: '🌀', hue: 140, max: 6,
      desc: (l) => l === 1 ? 'Funghetti che ti orbitano intorno e colpiscono chi tocca.' : ['', '', '+1 funghetto', '+danno, orbita più ampia', '+1 funghetto, più veloce', '+danno', '+2 funghetti'][l],
      update(dt, l, s) {
        s.a = (s.a || 0) + dt * (2.4 + 0.3 * l);
        const n = 1 + l + (l >= 6 ? 1 : 0), rad = (58 + 8 * l) * P.area, dmg = (6 + 3 * l) * P.dmg, r = 11 * P.area;
        s.pts = [];
        for (let i = 0; i < n; i++) {
          const a = s.a + i * TAU / n, x = P.x + Math.cos(a) * rad, y = P.y + Math.sin(a) * rad;
          s.pts.push({ x, y, r });
          queryEnemies(x, y, r + 30, (e) => {
            if (e.orbCd > 0) return;
            if ((e.x - x) ** 2 + (e.y - y) ** 2 < (e.r + r) ** 2) { e.orbCd = 0.35; hurtEnemy(e, dmg, e.x - P.x, e.y - P.y, 90); }
          });
        }
      },
    },
    aura: {
      name: 'Aura Cosmica', icon: '🌈', hue: 50, max: 6,
      desc: (l) => l === 1 ? 'Un campo arcobaleno che brucia i nemici vicini.' : ['', '', '+raggio', '+danno', '+raggio, rallenta i nemici', '+danno', 'Aura enorme'][l],
      update(dt, l, s) {
        s.r = (60 + 12 * l + (l >= 6 ? 30 : 0)) * P.area;
        s.cd = (s.cd || 0) - dt;
        const slow = l >= 4;
        if (slow) queryEnemies(P.x, P.y, s.r, (e) => { if ((e.x - P.x) ** 2 + (e.y - P.y) ** 2 < s.r * s.r) e.slow = 0.15; });
        if (s.cd > 0) return;
        s.cd = 0.5;
        const dmg = (3 + 2.2 * l) * P.dmg;
        queryEnemies(P.x, P.y, s.r, (e) => { if ((e.x - P.x) ** 2 + (e.y - P.y) ** 2 < (s.r + e.r) ** 2) hurtEnemy(e, dmg, e.x - P.x, e.y - P.y, 30); });
      },
    },
    nova: {
      name: 'Esplosione Prismatica', icon: '💥', hue: 200, max: 6,
      desc: (l) => l === 1 ? 'Ogni tanto esplodi in un anello di cristalli.' : ['', '', '+3 cristalli', '+danno', 'Più frequente', '+3 cristalli, +danno', 'Doppia esplosione'][l],
      update(dt, l, s) {
        s.cd = (s.cd || 1.5) - dt;
        if (s.cd > 0) return;
        s.cd = (3.4 - 0.3 * l) * P.cd;
        const burst = (off) => {
          const n = 6 + 3 * Math.floor(l / 2) + (l >= 5 ? 3 : 0);
          for (let i = 0; i < n; i++) {
            const a = off + i * TAU / n, sp = 320;
            G.projs.push({ x: P.x, y: P.y, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp, r: 7 * P.area, dmg: (10 + 4 * l) * P.dmg,
              life: 1.1, pierce: 3, hue: (i / n) * 360, hit: new Set(), kind: 'crystal' });
          }
        };
        burst(Math.random() * TAU);
        if (l >= 6) setTimeout(() => state === 'play' && burst(Math.random() * TAU), 250);
        G.ripples.push({ x: P.x, y: P.y, r: 10, life: 0.6, hue: 200 });
        AU.blip(320, 0.25, 'triangle', 0.08, 2.5);
      },
    },
    micelio: {
      name: 'Micelio Elettrico', icon: '⚡', hue: 270, max: 6,
      desc: (l) => l === 1 ? 'Un fulmine di micelio che rimbalza tra i nemici.' : ['', '', '+1 rimbalzo', '+danno', '+1 rimbalzo, più frequente', '+danno', 'Due fulmini alla volta'][l],
      update(dt, l, s) {
        s.cd = (s.cd || 0.8) - dt;
        if (s.cd > 0) return;
        const first = nearestEnemies(P.x, P.y, 6, 450);
        if (!first.length) return;
        s.cd = (2.3 - 0.2 * l) * P.cd;
        const casts = l >= 6 ? 2 : 1;
        for (let c = 0; c < casts; c++) {
          let cur = pick(first), hops = 2 + Math.floor(l / 2) + (l >= 4 ? 1 : 0);
          const pts = [{ x: P.x, y: P.y }], used = new Set();
          const dmg = (14 + 5 * l) * P.dmg;
          while (cur && hops-- >= 0) {
            used.add(cur); pts.push({ x: cur.x, y: cur.y }); hurtEnemy(cur, dmg, 0, 0, 0);
            let best = null, bd = 160 * 160 * P.area;
            queryEnemies(cur.x, cur.y, 160 * P.area, (e) => {
              if (used.has(e)) return; const d = (e.x - cur.x) ** 2 + (e.y - cur.y) ** 2; if (d < bd) { bd = d; best = e; }
            });
            cur = best;
          }
          G.bolts.push({ pts, life: 0.25 });
        }
        AU.blip(900, 0.12, 'sawtooth', 0.05, 0.3);
      },
    },
  };

  // ---------- potenziamenti passivi ----------
  const PASSIVES = {
    cappello: { name: 'Cappello Robusto', icon: '🛡️', hue: 0, max: 5, desc: () => '+20 vita massima e ti cura di 20' },
    gambe: { name: 'Gambo Veloce', icon: '👟', hue: 100, max: 5, desc: () => '+10% velocità di movimento' },
    magnete: { name: 'Micelio Magnetico', icon: '🧲', hue: 190, max: 5, desc: () => '+35% raggio di raccolta' },
    potenza: { name: 'Spore Concentrate', icon: '🔥', hue: 20, max: 5, desc: () => '+15% danno di tutte le armi' },
    metabolismo: { name: 'Metabolismo Rapido', icon: '⏱️', hue: 160, max: 5, desc: () => '-8% tempo di ricarica delle armi' },
    rigenera: { name: 'Muschio Curativo', icon: '💚', hue: 120, max: 5, desc: () => '+0.4 vita al secondo' },
    espansione: { name: 'Espansione Mentale', icon: '👁️', hue: 280, max: 5, desc: () => '+15% area degli attacchi' },
  };
  function recomputeStats() {
    const p = (id) => P.passives[id] || 0;
    P.maxHp = 100 + 20 * p('cappello');
    P.speed = 165 * (1 + 0.1 * p('gambe'));
    P.magnet = 100 * (1 + 0.35 * p('magnete'));
    P.dmg = 1 + 0.15 * p('potenza');
    P.cd = 1 - 0.08 * p('metabolismo');
    P.regen = 0.4 * p('rigenera');
    P.area = 1 + 0.15 * p('espansione');
  }

  // ---------- nemici ----------
  const ETYPES = {
    lumaca: { name: 'Lumaca Acida', hp: 9, spd: 50, r: 13, dmg: 7, xp: 1, hue: 90 },
    zanzara: { name: 'Zanzara Ronzante', hp: 5, spd: 105, r: 9, dmg: 5, xp: 1, hue: 180 },
    bruco: { name: 'Bruco Ipnotico', hp: 30, spd: 42, r: 17, dmg: 10, xp: 3, hue: 300 },
    occhio: { name: 'Occhio Fluttuante', hp: 75, spd: 62, r: 21, dmg: 14, xp: 6, hue: 40 },
    boss: { name: 'Re della Muffa', hp: 1400, spd: 58, r: 50, dmg: 25, xp: 60, hue: 0 },
  };
  function spawnTable(t) {
    if (t < 30) return [['lumaca', 1]];
    if (t < 70) return [['lumaca', 3], ['zanzara', 2]];
    if (t < 140) return [['lumaca', 3], ['zanzara', 3], ['bruco', 2]];
    if (t < 240) return [['lumaca', 2], ['zanzara', 3], ['bruco', 3], ['occhio', 1]];
    return [['lumaca', 1], ['zanzara', 3], ['bruco', 3], ['occhio', 2]];
  }
  function weightedPick(table) {
    let tot = 0; for (const [, w] of table) tot += w;
    let r = Math.random() * tot;
    for (const [id, w] of table) { r -= w; if (r <= 0) return id; }
    return table[0][0];
  }
  function spawnEnemy(type, x, y) {
    const d = ETYPES[type], mul = 1 + G.t / 75;
    if (x === undefined) {
      const a = Math.random() * TAU, dist = Math.hypot(W, H) / 2 + 60;
      x = P.x + Math.cos(a) * dist; y = P.y + Math.sin(a) * dist;
    }
    const hp = d.hp * (type === 'boss' ? 1 + G.t / 120 : mul);
    G.enemies.push({ type, x, y, r: d.r, hp, maxHp: hp, spd: d.spd * rand(0.9, 1.1), dmg: d.dmg * (1 + G.t / 300), xp: d.xp,
      hue: d.hue, flash: 0, kx: 0, ky: 0, orbCd: 0, slow: 0, ph: Math.random() * TAU, dead: false });
  }

  // ---------- stato del gioco ----------
  let state = 'menu', G, P;
  const cam = { x: 0, y: 0 };

  function newGame() {
    G = { t: 0, kills: 0, enemies: [], projs: [], gems: [], parts: [], texts: [], pickups: [], bolts: [], ripples: [],
      spawnAcc: 0, bossNext: 180, swarmNext: 60, shake: 0, flash: 0, pendingLevels: 0, offer: [] };
    P = { x: 0, y: 0, r: 14, hp: 100, xp: 0, level: 1, xpNext: 4, inv: 0, face: 1, walk: 0, moving: false,
      weapons: { spore: 1 }, passives: {}, ws: {} };
    recomputeStats();
    P.hp = P.maxHp;
    cam.x = 0; cam.y = 0;
  }
  const xpFor = (lvl) => Math.floor(5 + lvl * 4 + Math.pow(lvl, 1.65));

  function hurtEnemy(e, dmg, kx, ky, kb) {
    if (e.dead) return;
    e.hp -= dmg; e.flash = 0.08;
    if (kb && e.type !== 'boss') { const l = Math.hypot(kx, ky) || 1; e.kx += kx / l * kb; e.ky += ky / l * kb; }
    G.texts.push({ x: e.x + rand(-6, 6), y: e.y - e.r, v: Math.round(dmg), life: 0.6, hue: (G.t * 90 + e.x) % 360 });
    AU.hit();
    if (e.hp <= 0) killEnemy(e);
  }
  function killEnemy(e) {
    e.dead = true; G.kills++;
    for (let i = 0; i < (e.type === 'boss' ? 60 : 7); i++) {
      const a = Math.random() * TAU, s = rand(40, e.type === 'boss' ? 400 : 180);
      G.parts.push({ x: e.x, y: e.y, vx: Math.cos(a) * s, vy: Math.sin(a) * s, life: rand(0.3, 0.8), max: 0.8, r: rand(2, 5), hue: e.hue + rand(-40, 40) + G.t * 40 });
    }
    dropGem(e.x, e.y, e.xp);
    if (e.type === 'boss') {
      for (let i = 0; i < 10; i++) dropGem(e.x + rand(-60, 60), e.y + rand(-60, 60), 8);
      G.pickups.push({ type: 'cuore', x: e.x + 20, y: e.y }, { type: 'calamita', x: e.x - 20, y: e.y });
      G.flash = 0.6; AU.blip(110, 0.8, 'sawtooth', 0.15, 0.2);
    } else {
      const r = Math.random();
      if (r < 0.012) G.pickups.push({ type: 'cuore', x: e.x, y: e.y });
      else if (r < 0.016) G.pickups.push({ type: 'calamita', x: e.x, y: e.y });
    }
  }
  function dropGem(x, y, v) {
    if (G.gems.length > 400) { const g = G.gems[(Math.random() * G.gems.length) | 0]; g.v += v; return; }
    G.gems.push({ x, y, v, pull: false, ph: Math.random() * TAU });
  }
  function gainXp(v) {
    P.xp += v;
    while (P.xp >= P.xpNext) { P.xp -= P.xpNext; P.level++; P.xpNext = xpFor(P.level); G.pendingLevels++; }
    if (G.pendingLevels > 0 && state === 'play') openLevelUp();
  }

  // ---------- level up ----------
  const elLevel = document.getElementById('levelup'), elCards = document.getElementById('cards');
  function buildOffer() {
    const opts = [];
    const nWeapons = Object.keys(P.weapons).length;
    for (const id in WEAPONS) {
      const l = P.weapons[id] || 0;
      if (l < WEAPONS[id].max && (l > 0 || nWeapons < 5)) opts.push({ kind: 'w', id, lvl: l + 1 });
    }
    for (const id in PASSIVES) { const l = P.passives[id] || 0; if (l < PASSIVES[id].max) opts.push({ kind: 'p', id, lvl: l + 1 }); }
    shuffle(opts);
    const offer = opts.slice(0, 3);
    if (!offer.length) offer.push({ kind: 'heal' });
    return offer;
  }
  function openLevelUp() {
    state = 'levelup';
    G.offer = buildOffer();
    elCards.innerHTML = '';
    G.offer.forEach((o, i) => {
      const b = document.createElement('button'); b.className = 'card';
      let def, kindTxt, d;
      if (o.kind === 'heal') { def = { name: 'Zuppa di Funghi', icon: '🍲', hue: 30 }; kindTxt = 'CURA'; d = 'Recupera 40 vita.'; }
      else {
        def = o.kind === 'w' ? WEAPONS[o.id] : PASSIVES[o.id];
        kindTxt = (o.kind === 'w' ? 'ARMA' : 'POTERE') + ' · LV ' + o.lvl;
        d = (o.lvl === 1 ? '<span class="new">NUOVO! </span>' : '') + def.desc(o.lvl);
      }
      b.style.setProperty('--h', def.hue);
      b.innerHTML = `<span class="ico">${def.icon}</span><div class="k">[${i + 1}] ${kindTxt}</div><div class="n">${def.name}</div><div class="d">${d}</div>`;
      b.addEventListener('click', () => chooseUpgrade(i));
      elCards.appendChild(b);
    });
    elLevel.classList.remove('hidden');
    [523, 659, 784, 1046].forEach((f, i) => setTimeout(() => AU.blip(f, 0.18, 'triangle', 0.1), i * 70));
  }
  function chooseUpgrade(i) {
    if (state !== 'levelup') return;
    const o = G.offer[i]; if (!o) return;
    if (o.kind === 'w') P.weapons[o.id] = o.lvl;
    else if (o.kind === 'p') { P.passives[o.id] = o.lvl; recomputeStats(); if (o.id === 'cappello') P.hp = Math.min(P.maxHp, P.hp + 20); }
    else P.hp = Math.min(P.maxHp, P.hp + 40);
    G.pendingLevels--;
    elLevel.classList.add('hidden');
    state = 'play';
    if (G.pendingLevels > 0) openLevelUp();
  }

  // ---------- schermate ----------
  const elMenu = document.getElementById('menu'), elOver = document.getElementById('gameover'), elPause = document.getElementById('pause');
  function showBest() {
    const b = +store('ms_best') || 0;
    document.getElementById('best').textContent = b ? 'Record: ' + fmtTime(b) : '';
  }
  function startGame() {
    AU.init();
    newGame();
    [elMenu, elOver, elPause, elLevel].forEach(e => e.classList.add('hidden'));
    state = 'play';
  }
  function buildSummary() {
    const w = Object.entries(P.weapons).map(([id, l]) => `${WEAPONS[id].icon} ${WEAPONS[id].name} ${l}`).join('<br>');
    const p = Object.entries(P.passives).map(([id, l]) => `${PASSIVES[id].icon} ${PASSIVES[id].name} ${l}`).join('<br>');
    return w + (p ? '<br>' + p : '');
  }
  function togglePause() {
    if (state === 'play') { state = 'pause'; document.getElementById('pause-build').innerHTML = buildSummary(); elPause.classList.remove('hidden'); }
    else if (state === 'pause') { state = 'play'; elPause.classList.add('hidden'); }
  }
  function gameOver() {
    state = 'over';
    const best = Math.max(+store('ms_best') || 0, G.t);
    store('ms_best', String(Math.floor(best)));
    document.getElementById('stats').innerHTML =
      `Sopravvissuto: <b>${fmtTime(G.t)}</b><br>Livello: <b>${P.level}</b> · Nemici sconfitti: <b>${G.kills}</b><br>Record: <b>${fmtTime(best)}</b><br><br>${buildSummary()}`;
    elOver.classList.remove('hidden');
    AU.blip(220, 1.2, 'sawtooth', 0.15, 0.15);
  }
  document.getElementById('btn-start').addEventListener('click', startGame);
  document.getElementById('btn-restart').addEventListener('click', startGame);
  document.getElementById('btn-resume').addEventListener('click', togglePause);

  // ---------- update ----------
  function update(dt) {
    G.t += dt;

    // spawn
    const rate = 1.1 + G.t / 18;
    G.spawnAcc += rate * dt;
    const table = spawnTable(G.t);
    while (G.spawnAcc >= 1) { G.spawnAcc--; if (G.enemies.length < 380) spawnEnemy(weightedPick(table)); }
    if (G.t >= G.swarmNext) {
      G.swarmNext += 60;
      const n = 24 + Math.floor(G.t / 20), rad = Math.hypot(W, H) / 2 + 40;
      for (let i = 0; i < n; i++) { const a = i * TAU / n; spawnEnemy('zanzara', P.x + Math.cos(a) * rad, P.y + Math.sin(a) * rad); }
    }
    if (G.t >= G.bossNext) { G.bossNext += 180; spawnEnemy('boss'); G.flash = 0.4; AU.blip(70, 1.2, 'sawtooth', 0.2, 0.5); }

    // giocatore
    const mv = moveInput();
    P.moving = mv.x !== 0 || mv.y !== 0;
    P.x += mv.x * P.speed * dt; P.y += mv.y * P.speed * dt;
    if (mv.x) P.face = mv.x > 0 ? 1 : -1;
    if (P.moving) P.walk += dt * 12;
    P.inv = Math.max(0, P.inv - dt);
    P.hp = Math.min(P.maxHp, P.hp + P.regen * dt);

    buildGrid();

    // armi
    for (const id in P.weapons) {
      const s = P.ws[id] || (P.ws[id] = {});
      WEAPONS[id].update(dt, P.weapons[id], s);
    }

    // nemici
    for (const e of G.enemies) {
      if (e.dead) continue;
      const dx = P.x - e.x, dy = P.y - e.y, d = Math.hypot(dx, dy) || 1;
      let spd = e.spd * (e.slow > 0 ? 0.55 : 1);
      if (e.type === 'zanzara') { e.ph += dt * 6; }
      e.x += (dx / d * spd + e.kx) * dt; e.y += (dy / d * spd + e.ky) * dt;
      if (e.type === 'zanzara') { e.x += Math.cos(e.ph) * 40 * dt; e.y += Math.sin(e.ph * 1.3) * 40 * dt; }
      e.kx *= Math.pow(0.02, dt); e.ky *= Math.pow(0.02, dt);
      e.flash -= dt; e.orbCd -= dt; e.slow -= dt;
      // separazione
      queryEnemies(e.x, e.y, e.r * 2, (o) => {
        if (o === e) return;
        const ox = e.x - o.x, oy = e.y - o.y, rr = e.r + o.r, dd = ox * ox + oy * oy;
        if (dd > 0 && dd < rr * rr) {
          const dl = Math.sqrt(dd), push = (rr - dl) * 0.5 * (o.type === 'boss' ? 2 : e.type === 'boss' ? 0 : 1);
          e.x += ox / dl * push * 0.5; e.y += oy / dl * push * 0.5;
        }
      });
      // contatto con il giocatore
      if (d < e.r + P.r && P.inv <= 0) {
        P.hp -= e.dmg; P.inv = 0.45; G.shake = 8; G.flash = Math.max(G.flash, 0.25);
        AU.blip(140, 0.18, 'square', 0.12, 0.5);
        if (P.hp <= 0) { P.hp = 0; gameOver(); return; }
      }
      // troppo lontano: riposiziona vicino al giocatore
      if (d > 1600 && e.type !== 'boss') {
        const a = Math.random() * TAU, dist = Math.hypot(W, H) / 2 + 60;
        e.x = P.x + Math.cos(a) * dist; e.y = P.y + Math.sin(a) * dist;
      }
    }
    G.enemies = G.enemies.filter(e => !e.dead);

    // proiettili
    for (const p of G.projs) {
      p.x += p.vx * dt; p.y += p.vy * dt; p.life -= dt;
      if (p.life <= 0) continue;
      queryEnemies(p.x, p.y, p.r + 50, (e) => {
        if (p.hit.has(e) || p.pierce <= 0) return;
        if ((e.x - p.x) ** 2 + (e.y - p.y) ** 2 < (e.r + p.r) ** 2) {
          p.hit.add(e); p.pierce--; hurtEnemy(e, p.dmg, p.vx, p.vy, 60);
          if (p.pierce <= 0) { p.life = 0; return false; }
        }
      });
      if (Math.random() < 0.4) G.parts.push({ x: p.x, y: p.y, vx: 0, vy: 0, life: 0.25, max: 0.25, r: p.r * 0.6, hue: p.hue });
    }
    G.projs = G.projs.filter(p => p.life > 0);

    // gemme
    const mag2 = P.magnet * P.magnet;
    for (const g of G.gems) {
      const dx = P.x - g.x, dy = P.y - g.y, d2 = dx * dx + dy * dy;
      if (d2 < mag2) g.pull = true;
      if (g.pull) {
        const d = Math.sqrt(d2) || 1, sp = 420 + (g.boost = (g.boost || 0) + dt * 600);
        g.x += dx / d * sp * dt; g.y += dy / d * sp * dt;
        if (d < P.r + 6) { g.v_taken = true; gainXp(g.v); AU.blip(880 + Math.min(600, P.xp * 8), 0.04, 'sine', 0.04); }
      }
    }
    G.gems = G.gems.filter(g => !g.v_taken);

    // oggetti
    for (const it of G.pickups) {
      if ((P.x - it.x) ** 2 + (P.y - it.y) ** 2 < (P.r + 16) ** 2) {
        it.taken = true;
        if (it.type === 'cuore') { P.hp = Math.min(P.maxHp, P.hp + 30); AU.blip(660, 0.3, 'triangle', 0.1, 1.5); }
        if (it.type === 'calamita') { G.gems.forEach(g => g.pull = true); AU.blip(300, 0.5, 'sine', 0.1, 3); }
      }
    }
    G.pickups = G.pickups.filter(i => !i.taken);

    // effetti
    for (const p of G.parts) { p.x += p.vx * dt; p.y += p.vy * dt; p.vx *= 0.92; p.vy *= 0.92; p.life -= dt; }
    G.parts = G.parts.filter(p => p.life > 0);
    if (G.parts.length > 900) G.parts.splice(0, G.parts.length - 900);
    for (const t of G.texts) { t.y -= 40 * dt; t.life -= dt; }
    G.texts = G.texts.filter(t => t.life > 0);
    if (G.texts.length > 120) G.texts.splice(0, G.texts.length - 120);
    for (const b of G.bolts) b.life -= dt;
    G.bolts = G.bolts.filter(b => b.life > 0);
    for (const r of G.ripples) { r.r += 500 * dt; r.life -= dt; }
    G.ripples = G.ripples.filter(r => r.life > 0);
    G.shake = Math.max(0, G.shake - dt * 30);
    G.flash = Math.max(0, G.flash - dt);

    cam.x += (P.x - cam.x) * Math.min(1, dt * 8);
    cam.y += (P.y - cam.y) * Math.min(1, dt * 8);
  }

  // ---------- disegno ----------
  let clock = 0;
  function drawBackground() {
    const h0 = (clock * 12) % 360;
    ctx.fillStyle = `hsl(${(h0 + 260) % 360}, 50%, 7%)`;
    ctx.fillRect(0, 0, W, H);
    const sp = 64, ox = cam.x - W / 2, oy = cam.y - H / 2;
    const x0 = Math.floor(ox / sp) * sp, y0 = Math.floor(oy / sp) * sp;
    const intensity = Math.min(1, 0.35 + (P ? P.level : 1) * 0.04);
    for (let gx = x0; gx < ox + W + sp; gx += sp) {
      for (let gy = y0; gy < oy + H + sp; gy += sp) {
        const d = Math.hypot(gx - cam.x, gy - cam.y);
        const wv = Math.sin(d * 0.018 - clock * 2.4 + Math.sin(gx * 0.01 + clock) * 0.8);
        const r = 2 + (wv + 1) * 3.2;
        ctx.fillStyle = `hsla(${(h0 + d * 0.35 + (gx + gy) * 0.08) % 360}, 95%, 60%, ${(0.12 + 0.22 * (wv + 1) * 0.5) * intensity * 1.6})`;
        ctx.beginPath(); ctx.arc(gx - ox, gy - oy, r, 0, TAU); ctx.fill();
      }
    }
  }

  function drawMushroom(x, y, s, hue, bob, face, flash) {
    ctx.save(); ctx.translate(x, y + bob);
    ctx.scale(face, 1);
    // ombra
    ctx.fillStyle = 'rgba(0,0,0,.35)'; ctx.beginPath(); ctx.ellipse(0, s * 1.05 - bob, s * 0.8, s * 0.22, 0, 0, TAU); ctx.fill();
    // gambo
    ctx.fillStyle = flash ? '#fff' : '#f4ead2';
    ctx.beginPath(); ctx.ellipse(0, s * 0.45, s * 0.48, s * 0.6, 0, 0, TAU); ctx.fill();
    // occhi
    ctx.fillStyle = '#1a0b22';
    ctx.beginPath(); ctx.ellipse(s * 0.12, s * 0.38, s * 0.07, s * 0.13, 0, 0, TAU); ctx.ellipse(s * 0.32, s * 0.38, s * 0.07, s * 0.13, 0, 0, TAU); ctx.fill();
    // cappello
    const g = ctx.createLinearGradient(0, -s, 0, s * 0.2);
    g.addColorStop(0, `hsl(${hue}, 95%, 62%)`); g.addColorStop(1, `hsl(${hue + 40}, 90%, 42%)`);
    ctx.fillStyle = flash ? '#fff' : g;
    ctx.shadowColor = `hsl(${hue}, 100%, 60%)`; ctx.shadowBlur = 18;
    ctx.beginPath(); ctx.ellipse(0, s * 0.05, s * 1.1, s * 0.85, 0, Math.PI, 0); ctx.quadraticCurveTo(0, s * 0.3, -s * 1.1, s * 0.05); ctx.fill();
    ctx.shadowBlur = 0;
    // puntini
    ctx.fillStyle = `hsla(${hue + 180}, 100%, 92%, .95)`;
    [[-0.55, -0.25, 0.17], [0.05, -0.55, 0.2], [0.55, -0.2, 0.15], [-0.15, -0.1, 0.11]].forEach(([dx, dy, r]) => {
      ctx.beginPath(); ctx.arc(dx * s, dy * s, r * s, 0, TAU); ctx.fill();
    });
    ctx.restore();
  }

  function drawEnemy(e) {
    const x = e.x, y = e.y, r = e.r, fl = e.flash > 0;
    const hue = (e.hue + clock * 60 + e.ph * 30) % 360;
    const col = fl ? '#fff' : `hsl(${hue}, 85%, 55%)`;
    const dark = fl ? '#fff' : `hsl(${hue + 30}, 70%, 30%)`;
    const look = Math.atan2(P.y - y, P.x - x);
    ctx.save();
    if (e.type === 'lumaca') {
      ctx.fillStyle = dark; ctx.beginPath(); ctx.ellipse(x, y + r * 0.45, r * 1.2, r * 0.45, 0, 0, TAU); ctx.fill();
      ctx.fillStyle = col; ctx.beginPath(); ctx.arc(x, y - r * 0.1, r * 0.85, 0, TAU); ctx.fill();
      ctx.strokeStyle = dark; ctx.lineWidth = 2.5; ctx.beginPath();
      for (let a = 0; a < TAU * 2.2; a += 0.3) { const rr = a / (TAU * 2.2) * r * 0.75; ctx.lineTo(x + Math.cos(a + clock * 3) * rr, y - r * 0.1 + Math.sin(a + clock * 3) * rr); }
      ctx.stroke();
    } else if (e.type === 'zanzara') {
      const flap = Math.sin(clock * 40 + e.ph) * 0.6;
      ctx.fillStyle = 'rgba(255,255,255,.45)';
      ctx.beginPath(); ctx.ellipse(x - r * 0.6, y - r * 0.5, r * 0.8, r * 0.35, -0.6 + flap, 0, TAU); ctx.ellipse(x + r * 0.6, y - r * 0.5, r * 0.8, r * 0.35, 0.6 - flap, 0, TAU); ctx.fill();
      ctx.fillStyle = col; ctx.beginPath(); ctx.ellipse(x, y, r * 0.55, r * 0.9, look + Math.PI / 2, 0, TAU); ctx.fill();
      ctx.fillStyle = '#ff2050'; ctx.beginPath(); ctx.arc(x + Math.cos(look) * r * 0.5, y + Math.sin(look) * r * 0.5, r * 0.25, 0, TAU); ctx.fill();
    } else if (e.type === 'bruco') {
      for (let i = 3; i >= 0; i--) {
        const off = i * r * 0.55, w = Math.sin(clock * 6 + i + e.ph) * 4;
        const sx = x - Math.cos(look) * off + Math.cos(look + Math.PI / 2) * w, sy = y - Math.sin(look) * off + Math.sin(look + Math.PI / 2) * w;
        ctx.fillStyle = fl ? '#fff' : `hsl(${hue + i * 40}, 85%, ${55 - i * 5}%)`;
        ctx.beginPath(); ctx.arc(sx, sy, r * (0.75 - i * 0.08), 0, TAU); ctx.fill();
      }
      ctx.fillStyle = '#fff'; ctx.beginPath(); ctx.arc(x + Math.cos(look) * r * 0.3, y + Math.sin(look) * r * 0.3 - 3, 3.5, 0, TAU); ctx.fill();
    } else if (e.type === 'occhio') {
      ctx.fillStyle = col; ctx.shadowColor = col; ctx.shadowBlur = 14;
      ctx.beginPath();
      for (let i = 0; i < 12; i++) { const a = i / 12 * TAU, rr = r * (1.15 + 0.15 * Math.sin(clock * 5 + i)); ctx.lineTo(x + Math.cos(a) * rr, y + Math.sin(a) * rr); }
      ctx.fill(); ctx.shadowBlur = 0;
      ctx.fillStyle = '#fff'; ctx.beginPath(); ctx.arc(x, y, r * 0.85, 0, TAU); ctx.fill();
      ctx.fillStyle = `hsl(${hue + 180}, 90%, 50%)`; ctx.beginPath(); ctx.arc(x + Math.cos(look) * r * 0.3, y + Math.sin(look) * r * 0.3, r * 0.45, 0, TAU); ctx.fill();
      ctx.fillStyle = '#000'; ctx.beginPath(); ctx.arc(x + Math.cos(look) * r * 0.4, y + Math.sin(look) * r * 0.4, r * 0.2, 0, TAU); ctx.fill();
    } else if (e.type === 'boss') {
      ctx.fillStyle = fl ? '#fff' : `hsl(${hue}, 60%, 35%)`; ctx.shadowColor = `hsl(${hue}, 100%, 60%)`; ctx.shadowBlur = 30;
      ctx.beginPath();
      for (let i = 0; i <= 28; i++) { const a = i / 28 * TAU, rr = r * (1 + 0.12 * Math.sin(clock * 3 + i * 1.7) + 0.06 * Math.sin(clock * 7 + i * 3)); ctx.lineTo(x + Math.cos(a) * rr, y + Math.sin(a) * rr); }
      ctx.fill(); ctx.shadowBlur = 0;
      for (let i = 0; i < 5; i++) {
        const a = i / 5 * TAU + clock * 0.4, ex = x + Math.cos(a) * r * 0.5, ey = y + Math.sin(a) * r * 0.5;
        ctx.fillStyle = '#fff'; ctx.beginPath(); ctx.arc(ex, ey, r * 0.18, 0, TAU); ctx.fill();
        ctx.fillStyle = '#100'; ctx.beginPath(); ctx.arc(ex + Math.cos(look) * 4, ey + Math.sin(look) * 4, r * 0.08, 0, TAU); ctx.fill();
      }
      // barra vita del boss
      ctx.fillStyle = 'rgba(0,0,0,.6)'; ctx.fillRect(x - r, y - r - 18, r * 2, 6);
      ctx.fillStyle = '#ff3d7f'; ctx.fillRect(x - r, y - r - 18, r * 2 * Math.max(0, e.hp / e.maxHp), 6);
    }
    ctx.restore();
  }

  function render() {
    drawBackground();
    if (!G) return;
    const shx = rand(-G.shake, G.shake), shy = rand(-G.shake, G.shake);
    ctx.save();
    ctx.translate(Math.round(W / 2 - cam.x + shx), Math.round(H / 2 - cam.y + shy));
    const vx0 = cam.x - W / 2 - 80, vx1 = cam.x + W / 2 + 80, vy0 = cam.y - H / 2 - 80, vy1 = cam.y + H / 2 + 80;
    const inView = (o) => o.x > vx0 && o.x < vx1 && o.y > vy0 && o.y < vy1;

    // aura
    const aura = P.ws.aura;
    if (P.weapons.aura && aura && aura.r) {
      const g = ctx.createRadialGradient(P.x, P.y, aura.r * 0.2, P.x, P.y, aura.r);
      g.addColorStop(0, 'rgba(255,255,255,0)');
      g.addColorStop(0.7, `hsla(${clock * 120 % 360}, 100%, 60%, .12)`);
      g.addColorStop(1, `hsla(${(clock * 120 + 120) % 360}, 100%, 60%, .35)`);
      ctx.fillStyle = g; ctx.beginPath(); ctx.arc(P.x, P.y, aura.r, 0, TAU); ctx.fill();
      ctx.strokeStyle = `hsla(${(clock * 200) % 360}, 100%, 70%, .6)`; ctx.lineWidth = 2;
      ctx.setLineDash([10, 8]); ctx.lineDashOffset = -clock * 40; ctx.stroke(); ctx.setLineDash([]);
    }

    // onde
    for (const r of G.ripples) {
      ctx.strokeStyle = `hsla(${(r.hue + clock * 100) % 360}, 100%, 70%, ${r.life})`; ctx.lineWidth = 4;
      ctx.beginPath(); ctx.arc(r.x, r.y, r.r, 0, TAU); ctx.stroke();
    }

    // gemme
    for (const g of G.gems) {
      if (!inView(g)) continue;
      const s = g.v >= 20 ? 9 : g.v >= 5 ? 7 : 5, hue = g.v >= 20 ? 0 : g.v >= 5 ? 50 : (180 + clock * 50) % 360;
      const bob = Math.sin(clock * 4 + g.ph) * 2;
      ctx.fillStyle = `hsl(${hue}, 100%, 65%)`;
      ctx.beginPath(); ctx.moveTo(g.x, g.y - s + bob); ctx.lineTo(g.x + s * 0.7, g.y + bob); ctx.lineTo(g.x, g.y + s + bob); ctx.lineTo(g.x - s * 0.7, g.y + bob); ctx.fill();
    }

    // oggetti
    ctx.font = '22px serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    for (const it of G.pickups) {
      const bob = Math.sin(clock * 4) * 3;
      ctx.fillText(it.type === 'cuore' ? '❤️' : '🧲', it.x, it.y + bob);
    }

    // nemici
    for (const e of G.enemies) if (inView(e)) drawEnemy(e);

    // funghetti orbitanti
    if (P.weapons.orbit && P.ws.orbit && P.ws.orbit.pts) {
      P.ws.orbit.pts.forEach((p, i) => drawMushroom(p.x, p.y - 4, p.r * 0.9, (clock * 120 + i * 50) % 360, 0, 1, false));
    }

    // giocatore
    const blink = P.inv > 0 && Math.floor(clock * 20) % 2 === 0;
    if (!blink) drawMushroom(P.x, P.y - 6, 18, (clock * 40) % 360, P.moving ? Math.abs(Math.sin(P.walk)) * -4 : Math.sin(clock * 3) * 1.5, P.face, false);
    // vita sotto il giocatore
    ctx.fillStyle = 'rgba(0,0,0,.6)'; ctx.fillRect(P.x - 20, P.y + 22, 40, 5);
    ctx.fillStyle = P.hp / P.maxHp > 0.3 ? '#3dff9e' : '#ff3d5a'; ctx.fillRect(P.x - 20, P.y + 22, 40 * P.hp / P.maxHp, 5);

    // proiettili e particelle (additivi)
    ctx.globalCompositeOperation = 'lighter';
    for (const p of G.parts) {
      if (!inView(p)) continue;
      ctx.fillStyle = `hsla(${p.hue % 360}, 100%, 60%, ${p.life / p.max})`;
      ctx.beginPath(); ctx.arc(p.x, p.y, p.r, 0, TAU); ctx.fill();
    }
    for (const p of G.projs) {
      const hue = (p.hue + clock * 200) % 360;
      ctx.fillStyle = `hsla(${hue}, 100%, 60%, .5)`; ctx.beginPath(); ctx.arc(p.x, p.y, p.r * 1.9, 0, TAU); ctx.fill();
      ctx.fillStyle = `hsl(${hue}, 100%, 85%)`;
      ctx.beginPath();
      if (p.kind === 'crystal') { const a = Math.atan2(p.vy, p.vx); ctx.moveTo(p.x + Math.cos(a) * p.r * 1.8, p.y + Math.sin(a) * p.r * 1.8); ctx.lineTo(p.x + Math.cos(a + 2.4) * p.r, p.y + Math.sin(a + 2.4) * p.r); ctx.lineTo(p.x + Math.cos(a - 2.4) * p.r, p.y + Math.sin(a - 2.4) * p.r); }
      else ctx.arc(p.x, p.y, p.r, 0, TAU);
      ctx.fill();
    }
    for (const b of G.bolts) {
      ctx.strokeStyle = `hsla(${(270 + clock * 300) % 360}, 100%, 75%, ${b.life * 4})`; ctx.lineWidth = 3;
      ctx.beginPath();
      b.pts.forEach((pt, i) => {
        if (i === 0) { ctx.moveTo(pt.x, pt.y); return; }
        const prev = b.pts[i - 1];
        for (let k = 1; k <= 4; k++) { const t = k / 4; ctx.lineTo(prev.x + (pt.x - prev.x) * t + (k < 4 ? rand(-10, 10) : 0), prev.y + (pt.y - prev.y) * t + (k < 4 ? rand(-10, 10) : 0)); }
      });
      ctx.stroke();
    }
    ctx.globalCompositeOperation = 'source-over';

    // numeri di danno
    ctx.font = 'bold 14px "Trebuchet MS", sans-serif';
    for (const t of G.texts) {
      ctx.fillStyle = `hsla(${t.hue}, 100%, 75%, ${Math.min(1, t.life * 2)})`;
      ctx.fillText(t.v, t.x, t.y);
    }
    ctx.restore();

    // vignetta psichedelica
    const vg = ctx.createRadialGradient(W / 2, H / 2, Math.min(W, H) * 0.3, W / 2, H / 2, Math.max(W, H) * 0.75);
    vg.addColorStop(0, 'rgba(0,0,0,0)');
    vg.addColorStop(1, `hsla(${(clock * 30 + 280) % 360}, 90%, 20%, .65)`);
    ctx.fillStyle = vg; ctx.fillRect(0, 0, W, H);
    if (G.flash > 0) { ctx.fillStyle = `hsla(${(clock * 400) % 360}, 100%, 60%, ${G.flash * 0.5})`; ctx.fillRect(0, 0, W, H); }

    if (state !== 'menu') drawHud();
    if (touch.active && state === 'play') {
      ctx.strokeStyle = 'rgba(255,255,255,.4)'; ctx.lineWidth = 3;
      ctx.beginPath(); ctx.arc(touch.ox, touch.oy, 60, 0, TAU); ctx.stroke();
      const dx = touch.x - touch.ox, dy = touch.y - touch.oy, d = Math.hypot(dx, dy), m = Math.min(60, d);
      ctx.fillStyle = 'rgba(255,255,255,.5)'; ctx.beginPath(); ctx.arc(touch.ox + (d ? dx / d * m : 0), touch.oy + (d ? dy / d * m : 0), 22, 0, TAU); ctx.fill();
    }
  }

  function drawHud() {
    // barra esperienza
    ctx.fillStyle = 'rgba(0,0,0,.55)'; ctx.fillRect(0, 0, W, 14);
    const g = ctx.createLinearGradient(0, 0, W, 0);
    for (let i = 0; i <= 6; i++) g.addColorStop(i / 6, `hsl(${(clock * 80 + i * 60) % 360}, 100%, 60%)`);
    ctx.fillStyle = g; ctx.fillRect(0, 0, W * Math.min(1, P.xp / P.xpNext), 14);
    ctx.textBaseline = 'top'; ctx.font = 'bold 13px "Trebuchet MS", sans-serif'; ctx.fillStyle = '#fff';
    ctx.textAlign = 'right'; ctx.fillText('LV ' + P.level, W - 8, 1);
    // tempo
    ctx.textAlign = 'center'; ctx.font = 'bold 30px "Trebuchet MS", sans-serif';
    ctx.shadowColor = `hsl(${(clock * 90) % 360}, 100%, 60%)`; ctx.shadowBlur = 14;
    ctx.fillText(fmtTime(G.t), W / 2, 22); ctx.shadowBlur = 0;
    // uccisioni e vita
    ctx.textAlign = 'right'; ctx.font = 'bold 16px "Trebuchet MS", sans-serif';
    ctx.fillText('💀 ' + G.kills, W - 12, 26);
    ctx.textAlign = 'left';
    ctx.fillText('❤ ' + Math.ceil(P.hp) + ' / ' + P.maxHp, 12, 26);
    // armi possedute
    ctx.font = '18px serif';
    let x = 12;
    for (const id in P.weapons) { ctx.fillText(WEAPONS[id].icon, x, 50); ctx.font = 'bold 11px sans-serif'; ctx.fillText(P.weapons[id], x + 20, 58); ctx.font = '18px serif'; x += 38; }
    x = 12;
    for (const id in P.passives) { ctx.fillText(PASSIVES[id].icon, x, 76); ctx.font = 'bold 11px sans-serif'; ctx.fillText(P.passives[id], x + 20, 84); ctx.font = '18px serif'; x += 38; }
  }

  // ---------- ciclo principale ----------
  let last = performance.now();
  function frame(now) {
    const dt = Math.min(0.05, (now - last) / 1000); last = now;
    clock += dt;
    if (state === 'play') update(dt);
    else if (state === 'menu') { cam.x += 30 * dt; cam.y += 12 * dt; }
    render();
    requestAnimationFrame(frame);
  }
  newGame();
  showBest();
  requestAnimationFrame(frame);

  // aggancio per i test automatici
  window.__ms = { get G() { return G; }, get P() { return P; }, get state() { return state; }, update, startGame, chooseUpgrade };
})();
