// Synthesizes the chiptune songs into music/*.wav.
// Run from the project folder:  node tools/make_music.js
// Pass --preview to render each song twice through (for listening).
const fs = require("fs");
const path = require("path");

const RATE = 22050;
const preview = process.argv.includes("--preview");

// Notes like "C5", "F#4". Rests are "-".
function freq(note) {
  const names = { C: 0, "C#": 1, D: 2, "D#": 3, E: 4, F: 5, "F#": 6, G: 7, "G#": 8, A: 9, "A#": 10, B: 11 };
  const m = note.match(/^([A-G]#?)(\d)$/);
  const midi = (Number(m[2]) + 1) * 12 + names[m[1]];
  return 440 * Math.pow(2, (midi - 69) / 12);
}

// Melody: "note:beats note:beats ..." per bar.
function parse(bars) {
  return bars.join(" ").trim().split(/\s+/).map((t) => {
    const [n, b] = t.split(":");
    return { note: n, beats: Number(b) };
  });
}

const CHORD_ROOTS = {
  C: "C3", G: "G2", Am: "A2", F: "F2", Em: "E2", D: "D3",
};

const songs = {
  happy_hop: {
    title: "Happy Hop", bpm: 140, lead: "square25", drums: "full",
    chords: ["C", "G", "Am", "F", "C", "G", "Am", "G"],
    melody: [
      "E5:.5 G5:.5 C6:1 G5:.5 E5:.5 G5:1",
      "D5:.5 G5:.5 B5:1 A5:.5 G5:.5 D5:1",
      "C5:.5 E5:.5 A5:1 G5:.5 E5:.5 C5:1",
      "F5:1 A5:.5 G5:.5 F5:1 E5:1",
      "E5:.5 G5:.5 C6:.5 D6:.5 E6:1 C6:1",
      "D6:.5 B5:.5 G5:1 B5:.5 D6:.5 B5:1",
      "C6:.5 A5:.5 E5:1 A5:.5 C6:.5 B5:1",
      "G5:1 F5:.5 E5:.5 D5:1 G4:1",
    ],
  },
  sunny_stroll: {
    title: "Sunny Stroll", bpm: 100, lead: "triangle", drums: "light",
    chords: ["G", "Em", "C", "D", "G", "Em", "C", "D"],
    melody: [
      "B4:1 D5:1 G5:1.5 F#5:.5",
      "E5:1 G5:1 B4:2",
      "C5:1 E5:1 G5:1 E5:1",
      "F#5:1.5 E5:.5 D5:2",
      "B4:1 D5:1 G5:1 A5:1",
      "B5:1.5 A5:.5 G5:2",
      "E5:1 G5:1 C6:1 B5:1",
      "A5:1 F#5:1 D5:2",
    ],
  },
  puppy_chase: {
    title: "Puppy Chase", bpm: 165, lead: "square50", drums: "full",
    chords: ["Am", "F", "C", "G", "Am", "F", "C", "G"],
    melody: [
      "A4:.5 C5:.5 E5:.5 A5:.5 G5:.5 E5:.5 C5:.5 E5:.5",
      "F4:.5 A4:.5 C5:.5 F5:.5 E5:.5 C5:.5 A4:.5 C5:.5",
      "G4:.5 C5:.5 E5:.5 G5:.5 E5:.5 G5:.5 C6:1",
      "B5:.5 A5:.5 G5:.5 D5:.5 B4:1 D5:1",
      "A5:1 E5:.5 A5:.5 C6:1 B5:.5 A5:.5",
      "F5:1 C5:.5 F5:.5 A5:1 G5:.5 F5:.5",
      "E5:.5 G5:.5 C6:.5 E6:.5 D6:.5 C6:.5 G5:1",
      "B5:.5 D6:.5 B5:.5 G5:.5 E5:1 G#5:1",
    ],
  },
};

function osc(type, phase) {
  const p = phase % 1;
  if (type === "square25") return p < 0.25 ? 1 : -1;
  if (type === "square50") return p < 0.5 ? 1 : -1;
  return 4 * Math.abs(p - 0.5) - 1; // triangle
}

// Simple attack/release so notes don't click.
function env(t, len) {
  const a = Math.min(1, t / 0.005);
  const r = Math.min(1, (len - t) / 0.03);
  return Math.max(0, Math.min(a, r));
}

let noiseSeed = 1;
function noise() {
  noiseSeed = (noiseSeed * 1103515245 + 12345) & 0x7fffffff;
  return (noiseSeed / 0x7fffffff) * 2 - 1;
}

function render(song) {
  const beat = 60 / song.bpm;
  const loops = preview ? 2 : 1;
  const total = Math.ceil(song.chords.length * 4 * beat * loops * RATE);
  const out = new Float32Array(total);

  const add = (start, len, fn) => {
    const s0 = Math.floor(start * RATE);
    const n = Math.floor(len * RATE);
    for (let i = 0; i < n && s0 + i < total; i++) out[s0 + i] += fn(i / RATE, len);
  };

  for (let loop = 0; loop < loops; loop++) {
    const offset = loop * song.chords.length * 4 * beat;

    // Lead melody
    let t = offset;
    for (const { note, beats } of parse(song.melody)) {
      const len = beats * beat * 0.92;
      if (note !== "-") {
        const f = freq(note);
        const vol = song.lead === "triangle" ? 0.30 : 0.13;
        add(t, len, (x, l) => vol * env(x, l) * osc(song.lead, x * f));
      }
      t += beats * beat;
    }

    // Bass: root on eighth notes, jumping up an octave every other note
    song.chords.forEach((chord, bar) => {
      const root = freq(CHORD_ROOTS[chord]);
      const step = song.drums === "light" ? 1 : 0.5;
      for (let b = 0; b < 4; b += step) {
        const f = (b / step) % 2 === 1 ? root * 2 : root;
        add(offset + (bar * 4 + b) * beat, step * beat * 0.85, (x, l) => 0.22 * env(x, l) * osc("triangle", x * f));
      }
    });

    // Drums
    for (let b = 0; b < song.chords.length * 4; b += 0.5) {
      const at = offset + b * beat;
      const onBeat = b % 1 === 0;
      if (onBeat && b % 2 === 0) {
        // kick: quick falling pitch
        add(at, 0.12, (x) => 0.35 * Math.exp(-x * 30) * Math.sin(2 * Math.PI * (60 + 120 * Math.exp(-x * 40)) * x));
      } else if (onBeat) {
        // snare: noise burst
        add(at, 0.1, (x) => (song.drums === "light" ? 0.06 : 0.12) * Math.exp(-x * 30) * noise());
      }
      if (song.drums === "full") {
        // hi-hat on every eighth
        add(at, 0.03, (x) => 0.035 * Math.exp(-x * 120) * noise());
      }
    }
  }
  return out;
}

function writeWav(file, samples) {
  const buf = Buffer.alloc(44 + samples.length * 2);
  buf.write("RIFF", 0); buf.writeUInt32LE(36 + samples.length * 2, 4); buf.write("WAVE", 8);
  buf.write("fmt ", 12); buf.writeUInt32LE(16, 16); buf.writeUInt16LE(1, 20); buf.writeUInt16LE(1, 22);
  buf.writeUInt32LE(RATE, 24); buf.writeUInt32LE(RATE * 2, 28); buf.writeUInt16LE(2, 32); buf.writeUInt16LE(16, 34);
  buf.write("data", 36); buf.writeUInt32LE(samples.length * 2, 40);
  for (let i = 0; i < samples.length; i++) {
    const v = Math.max(-1, Math.min(1, samples[i]));
    buf.writeInt16LE(Math.round(v * 32767), 44 + i * 2);
  }
  fs.writeFileSync(file, buf);
}

const only = process.argv.find((a) => songs[a]);
const outDir = process.argv.find((a) => a.startsWith("--out="))?.slice(6) || path.join(__dirname, "..", "music");
fs.mkdirSync(outDir, { recursive: true });
for (const [name, song] of Object.entries(songs)) {
  if (only && name !== only) continue;
  const samples = render(song);
  const file = path.join(outDir, `${name}.wav`);
  writeWav(file, samples);
  console.log(`${song.title}: ${file} (${(samples.length / RATE).toFixed(1)}s)`);
}
