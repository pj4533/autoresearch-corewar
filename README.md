# autoresearch-corewar

Karpathy's [autoresearch](https://github.com/karpathy/autoresearch) pattern applied to [Core War](https://en.wikipedia.org/wiki/Core_War) — AI agents evolve warriors autonomously in a competitive programming arena.

The idea: give an AI agent a warrior and a fixed evaluation harness, then let it experiment overnight. It modifies the Redcode, runs battles, checks if the result improved, keeps or discards, and repeats. You wake up to a log of experiments and (hopefully) a stronger warrior.

![diagram](https://img.shields.io/badge/loop-modify→evaluate→keep/discard-green)

## How It Works

Three files matter:

| File | Who Edits | What It Does |
|------|-----------|-------------|
| `warrior.red` | The AI agent | Redcode warrior source — architecture, parameters, strategy |
| `evaluate.cjs` | Nobody | Fixed evaluation harness — runs battles, outputs score |
| `program.md` | The human | Agent instructions — the research strategy |

The agent reads `program.md`, modifies `warrior.red`, runs `evaluate.cjs`, and iterates forever on a git branch. Each experiment is a commit. Improvements advance the branch; failures revert.

This is the same convergence engine pattern Karpathy uses for LLM training, applied to a domain where each "training run" takes seconds instead of minutes.

## What Is Core War?

[Core War](https://en.wikipedia.org/wiki/Core_War) (1984) is a competitive programming game where programs ("warriors") battle inside a shared circular memory space. Warriors are written in Redcode assembly (ICWS '94). They try to crash each other by overwriting opponent code with `DAT` instructions (which kill any process that executes them).

The arena is a 25,200-cell circular memory. Warriors can scan for opponents, throw bombs, replicate themselves, or some combination. The math of 25,200 (= 2² × 3² × 5² × 7) determines which strategies work — scanner step sizes must be coprime to the core size for full coverage, meaning prime numbers ≥ 11 are mandatory.

**This arena is from [ModelWar](https://www.modelwar.ai)**, a competitive Core War platform designed for AI agents.

## Quick Start

**Requirements:** Node.js 18+, an AI coding agent (Claude Code, Codex, Cursor, etc.)

```bash
# 1. Clone and install
git clone https://github.com/pj4533/autoresearch-corewar.git
cd autoresearch-corewar
npm install

# 2. Run the evaluation manually to verify setup
node evaluate.cjs warrior.red

# 3. Point your agent at the repo and prompt:
#    "Read program.md and let's kick off a new experiment!"
```

The evaluation runs the warrior against 6 opponents (scanner, paper, stone, clear/imp, imp spiral, scanner/clear) for 200 rounds each. Output:

```
avg_score:    1.234567
total_points: 7.4 / 18.0
opponents:    6
rounds:       200
```

Higher avg_score = stronger warrior. Maximum is 3.0 (100% win rate against all opponents).

## Project Structure

```
warrior.red         — the warrior (agent modifies this)
evaluate.cjs        — evaluation harness (do not modify)
program.md          — agent instructions (human iterates on this)
opponents/          — opponent suite (do not modify)
  scanner_basic.red   — simple oneshot scanner
  scanner_clear.red   — scanner + clear hybrid
  paper_silk.red      — self-replicating silk paper
  stone.red           — classic DAT bomb thrower
  clear_imp.red       — Guenzel clear + imp ring
  imp_spiral.red      — 5-point imp ring
package.json        — dependencies (just pmars-ts)
```

## How Fast Is It?

| Eval Type | Rounds | Time | Experiments/Hour |
|-----------|--------|------|-----------------|
| Quick screening | 200 | ~15-30s | ~120-240 |
| Confirmation | 2000 | ~3 min | ~20 |

Compare to Karpathy's autoresearch: ~12 experiments/hour (5-minute LLM training runs). Core War evaluation is **10x faster**, meaning an overnight run can test ~1,000+ variations.

## The Seed Warrior

The repo ships with a **scanner/clear hybrid** as the starting warrior — a working but unoptimized architecture with known room for improvement. The agent's job is to find those improvements through autonomous experimentation.

Key parameters available for tuning:
- **Scanner step** (currently 3037) — the number of cells to skip between scan probes. Must be coprime to 25,200.
- **Scanner gap** — spacing between paired scan addresses
- **Clear decrement** — how aggressively the clear routine works
- **Imp spacing** — spacing of the backup imp ring
- **Bomb patterns** — the instruction values used for bombing

Or the agent can try entirely different architectures. The `program.md` provides strategy context and Core War knowledge to guide experimentation.

## Design Choices

- **Single file to modify.** The agent only touches `warrior.red`. This keeps diffs reviewable and the loop simple.
- **Fast evaluation.** Each eval takes seconds, not minutes. The bottleneck is idea generation, not testing.
- **Representative opponents.** Six opponents cover the main archetype space (scanner, paper, stone, clear, imp, hybrid). A warrior that beats all of them is genuinely strong.
- **Statistical validation.** The `program.md` teaches the agent about noise: 200-round evals are for screening, 2000-round evals for confirmation. ~50% of 200-round "improvements" are noise.

## Background

This project emerged from applying the autoresearch pattern to [ModelWar](https://www.modelwar.ai), a competitive Core War arena. The same convergence engine architecture — `modify → evaluate → keep/discard → repeat` — works in any domain with a measurable objective:

- **Karpathy's autoresearch**: modify training code → train 5 min → check val_bpb → keep/discard
- **This repo**: modify warrior → run battles → check avg_score → keep/discard

The human's job: write `program.md` (the spec). The agent's job: run the loop indefinitely. The value is in the decomposition.

## License

MIT
