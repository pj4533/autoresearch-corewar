#!/usr/bin/env node
// evaluate.cjs — Evaluation harness for autoresearch-corewar
// Runs a warrior against the opponent suite and reports average score.
//
// Usage:
//   node evaluate.cjs warrior.red [rounds] [--arena coreSize,maxLength,maxCycles,maxProcesses,minSeparation,pSpaceSize]
//
// Examples:
//   node evaluate.cjs warrior.red                    # Quick eval, 200 rounds, standard 8000 arena
//   node evaluate.cjs warrior.red 2000               # Full confirmation, 2000 rounds
//   node evaluate.cjs warrior.red 200 --arena 25200,5040,252000,25200,100,500   # Custom arena (e.g. modelwar.ai)
//
// Arena defaults (standard 94nop hill):
//   coreSize=8000, maxLength=100, maxCycles=80000, maxProcesses=8000, minSeparation=100, pSpaceSize=500
//
// Output format (stdout, machine-readable):
//   avg_score:    1.234567
//   total_points: 7.4 / 30.0
//   opponents:    10
//   rounds:       200
//   arena:        8000/100
//
// Opponent breakdown printed to stderr (won't pollute grep-friendly stdout).

const pmars = require('pmars-ts');
const { readFileSync, readdirSync } = require('fs');
const path = require('path');

// === Parse arguments ===
const args = process.argv.slice(2);

if (args.length < 1 || args[0] === '--help' || args[0] === '-h') {
  console.error('Usage: node evaluate.cjs warrior.red [rounds] [--arena coreSize,maxLength,maxCycles,maxProcesses,minSeparation,pSpaceSize]');
  console.error('');
  console.error('Arguments:');
  console.error('  warrior.red    Path to the warrior file to evaluate');
  console.error('  rounds         Rounds per opponent (default: 200, use 2000 for confirmation)');
  console.error('  --arena        Comma-separated arena parameters (default: 8000,100,80000,8000,100,500)');
  console.error('');
  console.error('Arena parameter order: coreSize,maxLength,maxCycles,maxProcesses,minSeparation,pSpaceSize');
  console.error('');
  console.error('Preset arenas:');
  console.error('  Standard 94nop:    8000,100,80000,8000,100,500    (default)');
  console.error('  Modelwar.ai 25200: 25200,5040,252000,25200,100,500');
  process.exit(1);
}

// Find warrior path and rounds (positional args before any --)
let warriorPath = null;
let rounds = 200;
let arenaArg = null;

for (let i = 0; i < args.length; i++) {
  if (args[i] === '--arena' && i + 1 < args.length) {
    arenaArg = args[i + 1];
    i++; // skip next
  } else if (!warriorPath) {
    warriorPath = args[i];
  } else if (!isNaN(parseInt(args[i]))) {
    rounds = parseInt(args[i], 10);
  }
}

// === Arena configuration ===
// Defaults: standard 94nop hill
const ARENA_DEFAULTS = {
  coreSize: 8000,
  maxLength: 100,
  maxCycles: 80000,
  maxProcesses: 8000,
  minSeparation: 100,
  pSpaceSize: 500
};

let ARENA = { ...ARENA_DEFAULTS };

if (arenaArg) {
  const parts = arenaArg.split(',').map(Number);
  if (parts.length >= 1) ARENA.coreSize = parts[0];
  if (parts.length >= 2) ARENA.maxLength = parts[1];
  if (parts.length >= 3) ARENA.maxCycles = parts[2];
  if (parts.length >= 4) ARENA.maxProcesses = parts[3];
  if (parts.length >= 5) ARENA.minSeparation = parts[4];
  if (parts.length >= 6) ARENA.pSpaceSize = parts[5];
}

// === Load opponent suite ===
const OPPONENT_DIR = path.join(__dirname, 'opponents');

function loadWarrior(filepath) {
  const code = readFileSync(filepath, 'utf-8');
  const asm = new pmars.Assembler(ARENA);
  const result = asm.assemble(code);
  if (!result.success) {
    const msgs = result.messages.map(m => m.text || m).join('; ');
    throw new Error(`Assembly failed for ${path.basename(filepath)}: ${msgs}`);
  }
  return result.warrior;
}

function runBattle(w1, w2, rounds) {
  let wins = 0, losses = 0, ties = 0;
  const opts = { ...ARENA, seed: Math.floor(Math.random() * 2147483647) };
  const sim = new pmars.Simulator(opts);
  sim.loadWarriors([w1, w2]);

  for (let r = 0; r < rounds; r++) {
    if (r > 0) sim.setupRound({ seed: Math.floor(Math.random() * 2147483647) });
    const result = sim.run();
    const outcome = result[0];
    if (outcome.winnerId === 0) wins++;
    else if (outcome.winnerId === 1) losses++;
    else ties++;
  }

  return { wins, losses, ties };
}

// === Main ===

// Load warrior under test
let warrior;
try {
  warrior = loadWarrior(warriorPath);
} catch (e) {
  console.log(`avg_score:    ERROR`);
  console.error(`ASSEMBLY_ERROR: ${e.message}`);
  process.exit(1);
}

// Load all opponents
const opponentFiles = readdirSync(OPPONENT_DIR)
  .filter(f => f.endsWith('.red'))
  .sort();

if (opponentFiles.length === 0) {
  console.error('No opponent .red files found in opponents/');
  process.exit(1);
}

const opponents = [];
for (const file of opponentFiles) {
  try {
    const w = loadWarrior(path.join(OPPONENT_DIR, file));
    opponents.push({ name: file.replace('.red', ''), warrior: w });
  } catch (e) {
    console.error(`WARNING: Skipping ${file}: ${e.message}`);
  }
}

// Run battles
let totalPoints = 0;
const maxPoints = opponents.length * (3 * rounds);

console.error(`\nEvaluating ${path.basename(warriorPath)} vs ${opponents.length} opponents (${rounds} rounds each)`);
console.error(`Arena: coreSize=${ARENA.coreSize} maxLength=${ARENA.maxLength} maxCycles=${ARENA.maxCycles}\n`);
console.error(`${'Opponent'.padEnd(25)} ${'W'.padStart(5)} ${'L'.padStart(5)} ${'T'.padStart(5)} ${'Win%'.padStart(7)} ${'Pts'.padStart(8)}`);
console.error('-'.repeat(62));

for (const opp of opponents) {
  const { wins, losses, ties } = runBattle(warrior, opp.warrior, rounds);
  const points = 3 * wins + ties;  // 3 pts for win, 1 for tie, 0 for loss
  totalPoints += points;
  const winPct = (100 * wins / rounds).toFixed(1);
  const ptsStr = `${points}/${3 * rounds}`;
  console.error(`${opp.name.padEnd(25)} ${String(wins).padStart(5)} ${String(losses).padStart(5)} ${String(ties).padStart(5)} ${(winPct + '%').padStart(7)} ${ptsStr.padStart(8)}`);
}

console.error('-'.repeat(62));

const avgScore = totalPoints / opponents.length / rounds;
const totalPossible = 3 * opponents.length;

console.error(`\nTotal: ${totalPoints} / ${maxPoints} points\n`);

// Machine-readable output on stdout (for grep)
console.log(`avg_score:    ${avgScore.toFixed(6)}`);
console.log(`total_points: ${(totalPoints / rounds).toFixed(1)} / ${(maxPoints / rounds).toFixed(1)}`);
console.log(`opponents:    ${opponents.length}`);
console.log(`rounds:       ${rounds}`);
console.log(`arena:        ${ARENA.coreSize}/${ARENA.maxLength}`);
