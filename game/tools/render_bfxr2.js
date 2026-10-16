#!/usr/bin/env node
// Bfxr2 parameter-mode renderer with a seeded Math.random source.
const fs = require('node:fs');
const path = require('node:path');

function arg(name) {
  const index = process.argv.indexOf(name);
  if (index < 0 || !process.argv[index + 1]) throw new Error(`Missing ${name}`);
  return process.argv[index + 1];
}

function mulberry32(seed) {
  let state = seed | 0;
  return function random() {
    state = state + 0x6D2B79F5 | 0;
    let value = Math.imul(state ^ state >>> 15, 1 | state);
    value = value + Math.imul(value ^ value >>> 7, 61 | value) ^ value;
    return ((value ^ value >>> 14) >>> 0) / 4294967296;
  };
}

async function main() {
  const root = path.resolve(arg('--bfxr2-root'));
  const params = JSON.parse(fs.readFileSync(arg('--params-file'), 'utf8'));
  const output = path.resolve(arg('--output'));
  const seed = Number(arg('--seed'));
  const sampleRate = Number(arg('--sample-rate'));
  const bitDepth = Number(arg('--bit-depth'));
  if (!Number.isInteger(seed) || !Number.isInteger(sampleRate) || !Number.isInteger(bitDepth)) {
    throw new Error('Seed, sample rate, and bit depth must be integers');
  }

  const engine = require(path.join(root, 'js/audio/headless_engine.js'));
  const { WavEncoder } = require(path.join(root, 'js/cli/audio_encoders.js'));
  engine.setSeed(seed);
  Math.random = mulberry32(seed);
  const samples = engine.generateAudio(params);
  const wav = new WavEncoder({ sampleRate, bitDepth, numChannels: 1 }).encode(samples);
  fs.writeFileSync(output, wav);
}

main().catch(error => {
  console.error(`bfxr2 render failed: ${error.message}`);
  process.exitCode = 1;
});
