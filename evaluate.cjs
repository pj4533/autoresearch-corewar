#!/usr/bin/env node
// evaluate.cjs — Fixed evaluation harness for autoresearch-corewar
// Runs a warrior against the opponent suite and reports average score.
// DO NOT MODIFY — this is the ground truth metric.
//
// Usage: node evaluate.cjs warrior.red [rounds]
//   rounds: rounds per opponent (default 200, use 2000 for confirmation)
//
// Output format:
//   avg_score:    7.234
//   total_points: 43.4 / 90.0
//   opponents:    6
//
// Opponent breakdown printed to stderr (won't pollute grep-friendly stdout).

const pmars = require('pmars-ts');
const { readFileSync, readdirSync } = require('fs');
const path = require('path');

// === Arena constants (match modelwar.ai 25200 settings) ===
const ARENA = {
  coreSize: 25200,
  maxLength: 5040,
  minSeparation: 100,
  maxProcesses: 25200,
  maxCycles: 252000,
  pSpaceSize: 500
};

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
const args = process.argv.slice(2);
if (args.length < 1) {
  console.error('Usage: node evaluate.cjs warrior.red [rounds]');
  process.exit(1);
}

const warriorPath = args[0];
const rounds = parseInt(args[1] || '200', 10);

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

console.error(`\nEvaluating ${path.basename(warriorPath)} vs ${opponents.length} opponents (${rounds} rounds each)\n`);
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
