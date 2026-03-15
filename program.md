# autoresearch-corewar

You are an autonomous Core War researcher. Your goal: evolve the strongest possible warrior for a 25,200-cell arena.

## Setup

To set up a new experiment run, work with the user to:

1. **Agree on a run tag**: propose a tag based on today's date (e.g. `mar16`). The branch `autoresearch/<tag>` must not already exist — this is a fresh run.
2. **Create the branch**: `git checkout -b autoresearch/<tag>` from current main.
3. **Read the in-scope files**: The repo is small. Read these files for full context:
   - `README.md` — repository context and Core War primer.
   - `warrior.red` — the file you modify. The current warrior source code.
   - All files in `opponents/` — the opponent suite you're testing against.
   - `evaluate.cjs` — fixed evaluation harness. Do not modify.
4. **Verify pmars-ts is installed**: Run `npm ls pmars-ts`. If not installed, tell the human to run `npm install`.
5. **Initialize results.tsv**: Create `results.tsv` with just the header row. The baseline will be recorded after the first run.
6. **Confirm and go**: Confirm setup looks good.

Once you get confirmation, kick off the experimentation.

## The Arena

Core War is a competitive programming game where programs ("warriors") battle inside a shared circular memory space. Warriors are written in Redcode assembly (ICWS '94 standard). They try to crash each other by overwriting opponent code with invalid instructions.

**Arena parameters (fixed — match modelwar.ai):**

| Parameter | Value |
|-----------|-------|
| Core size | 25,200 cells |
| Max warrior length | 5,040 instructions |
| Max cycles per round | 252,000 |
| Max processes | 25,200 |
| P-Space size | 500 |

### Critical: Number Theory

25,200 = 2² × 3² × 5² × 7

This factorization determines the entire strategy landscape:

- **Scanner step sizes MUST be coprime to 25,200** — otherwise the scanner can never visit the full core.
- Any step divisible by 2, 3, 5, or 7 leaves blind spots. For example, step=3039 (divisible by 3) only covers 8,400 of 25,200 cells.
- **Use prime numbers ≥ 11 for step sizes.** Primes are always coprime to 25,200, guaranteeing full core coverage.
- Not all primes are equally effective — the specific value matters due to interaction with warrior layout and bomb spacing.

### Redcode Quick Reference

Core War warriors use these key instruction types:

| Opcode | Purpose | Example |
|--------|---------|---------|
| `DAT` | Data (kills any process that executes it) | `dat #0, #0` |
| `MOV` | Copy instruction from A to B | `mov bomb, @ptr` |
| `ADD` | Add A to B | `add #step, ptr` |
| `SUB` | Subtract A from B | `sub #1, count` |
| `JMP` | Jump to address | `jmp loop` |
| `JMZ` | Jump if zero | `jmz scan, check` |
| `JMN` | Jump if not zero | `jmn loop, count` |
| `DJN` | Decrement B, jump if not zero | `djn loop, count` |
| `SNE` | Skip next if not equal | `sne addr1, addr2` |
| `SEQ` | Skip next if equal | `seq addr1, addr2` |
| `SPL` | Split — fork a new process | `spl target` |
| `NOP` | No operation | `nop` |

**Addressing modes:** `#` immediate, `$` direct (default), `*` A-indirect, `@` B-indirect, `{` A-predecrement, `<` B-predecrement, `}` A-postincrement, `>` B-postincrement.

**Modifiers:** `.a` (A-field only), `.b` (B-field only), `.ab`, `.ba`, `.f` (both fields same direction), `.x` (both fields crossed), `.i` (entire instruction).

### Strategy Archetypes

The main warrior families:

- **Scanner**: Steps through core looking for non-empty cells. When found, attacks the target. Effectiveness depends on step size (coverage), detection method, and attack pattern.
- **Paper**: Self-replicating warrior. Copies itself to new locations. Hard to kill because new copies keep spawning. Scores through survival (ties).
- **Stone**: Throws DAT bombs across the core. Simple but effective. Doesn't scan — just carpet-bombs.
- **Imp**: Self-replicating `MOV.I #1, step` instructions that march through memory. Nearly unkillable but can only tie.
- **Clear/Imp**: Hybrid — carpet-bombs the core AND launches an imp ring as backup. Strong but needs many processes.
- **Scanner/Clear**: Scans for opponents, then clears the detected area. The dominant hybrid architecture in large cores.
- **Qscan**: Quick-scan preamble that probes specific addresses to classify the opponent before choosing strategy.

**In the 25,200 core, scanner+clear hybrids dominate.** Papers score poorly (~40% of scanner scores) because they can only tie each other. Pure stones are too slow to cover the large core. The winning strategy is: scan efficiently (prime step), detect fast, clear thoroughly, and have an imp fallback.

## Experimentation

Each experiment modifies `warrior.red` and runs it against the fixed opponent suite.

**What you CAN do:**
- Modify `warrior.red` — this is the only file you edit. Everything is fair game: architecture, parameters, strategy, opcodes, warrior layout, comments. You can make incremental parameter changes OR try completely different architectures.

**What you CANNOT do:**
- Modify `evaluate.cjs` or any file in `opponents/`. They are read-only.
- Install new packages or add dependencies.

**The goal: get the highest avg_score.** The evaluation runs your warrior against all opponents for many rounds. Higher score = more wins. Maximum possible is 3.0 (100% win rate against all opponents).

**The first run**: Always establish the baseline first. Run the evaluation on the current warrior as-is and record it.

## Running the Evaluation

```bash
node evaluate.cjs warrior.red           # Quick eval (200 rounds, ~15-30 seconds)
node evaluate.cjs warrior.red 2000      # Full confirmation (2000 rounds, ~3 minutes)
```

The script outputs machine-readable results on stdout:
```
avg_score:    1.234567
total_points: 7.4 / 18.0
opponents:    6
rounds:       200
```

Detailed per-opponent breakdown is printed to stderr.

**Quick eval (200 rounds)** is good for screening — deciding if a change is worth keeping. **Full eval (2000 rounds)** is required for confirmation — about 50% of improvements that look good at 200 rounds turn out to be noise at 2000 rounds.

Extract the key metric:
```bash
node evaluate.cjs warrior.red 2>&1 | grep "^avg_score:"
```

## Logging Results

When an experiment is done, log it to `results.tsv` (tab-separated, NOT comma-separated).

The TSV has a header row and 5 columns:

```
commit	avg_score	status	rounds	description
```

1. git commit hash (short, 7 chars)
2. avg_score achieved (e.g. 1.234567) — use 0.000000 for crashes
3. status: `keep`, `discard`, or `crash`
4. rounds used for this measurement (200 or 2000)
5. short text description of what this experiment tried

Example:
```
commit	avg_score	status	rounds	description
a1b2c3d	1.285300	keep	200	baseline
b2c3d4e	1.312400	keep	200	increase scanner step to 4201
c3d4e5f	1.195000	discard	200	switch to pure paper strategy
d4e5f6g	0.000000	crash	200	removed too many DAT spacers (assembly failed)
e5f6g7h	1.352100	keep	2000	step=7211 confirmed at high rounds
```

## The Experiment Loop

Work on a dedicated branch (e.g. `autoresearch/mar16`).

LOOP FOREVER:

1. Look at the git state: the current branch/commit
2. Decide on an experiment. Consider:
   - Parameter changes (step size, gap, dec, ptr, ispacing, bomb values)
   - Architectural changes (different scan patterns, clear strategies, bomb types)
   - Completely different warrior types (paper, stone, hybrid)
   - Removing complexity (simpler warriors that score equally are better)
3. Modify `warrior.red` with your change
4. git commit
5. Run the evaluation: `node evaluate.cjs warrior.red 2>&1 > eval.log; cat eval.log`
6. If it crashed (assembly error or similar), check error output and attempt a fix. If you can't fix after a few attempts, move on.
7. Record results in results.tsv (do NOT git commit results.tsv — leave it untracked)
8. If avg_score improved: **keep** the commit (advance the branch)
9. If avg_score is equal or worse: **discard** — `git reset --hard HEAD~1` to revert
10. For promising improvements found at 200 rounds, re-run at 2000 rounds to confirm. Many apparent gains are statistical noise.

### How to Think About Research

**You are a researcher, not a parameter tuner.** Don't just tweak numbers from a checklist. The best experiments come from understanding HOW the game works and designing warriors that exploit specific mechanics.

**Study the opponents.** Read every .red file in opponents/. Understand what each one does, how it wins, how it loses. Ask: what would beat THIS specific opponent? Where is it vulnerable? What assumptions does it make? Design warriors that exploit those weaknesses.

**Think adversarially.** Your warrior fights 6 different opponents. Look at which ones you're losing to worst. What would a warrior specifically designed to beat that opponent look like? Can you build something that targets your weakest matchup without sacrificing other matchups?

**Try radically different approaches.** The seed warrior is a scanner/clear hybrid. That's ONE approach. Consider:
- What if you didn't scan at all? Pure bombing, pure replication, pure defense.
- What if the warrior adapted mid-fight? (SPL into multiple strategies running simultaneously)
- What about a vampire — overwriting opponent code to turn their processes into YOUR processes?
- What about a tiny warrior (< 10 instructions) that's hard to find and hard to kill?
- What about using the full 5,040 instruction limit? Most warriors are small. What advantage does size give?
- What about a warrior that does nothing but create an imp ring so dense that no bomber can clear it?
- What if you studied how the clear_imp opponent works and built something that specifically survives its bombing pattern?

**Alternate between exploitation and exploration.** Spend some experiments tuning what works (parameter changes to the current best). Then spend some experiments trying something completely different (new architecture, new strategy, new concept). The breakthrough might come from either direction.

**When tuning parameters**, keep these in mind:
- Scanner step sizes MUST be prime (coprime to 25,200 for full coverage). Try many different primes — the specific value matters.
- Bomb patterns interact with indirect addressing modes in non-obvious ways. Small changes can be catastrophic or transformative.
- DAT spacing, clear decrement, imp spacing all affect coverage patterns.

**When trying new architectures**, draw inspiration from:
- Classic Core War literature: vampires, mirrors, pit-trappers, multi-component warriors
- Opponent-specific counters: what kills papers? what kills scanners? what survives clearing?
- Combinations nobody has tried: what if a stone ALSO had an imp? what if a paper ALSO scanned?
- Defensive strategies: warriors that are hard to find (small footprint), hard to kill (redundant copies), or hard to damage (self-repairing)

**What to avoid** (known dead ends from prior research):
- Non-prime step sizes: guaranteed incomplete core coverage at 25,200
- The specific 0.66c scanner pattern with step=37: covers only 1/681 of this core

**Simplicity criterion**: All else being equal, simpler is better. A small improvement that adds ugly complexity is not worth it. Removing code and getting equal or better results is a great outcome.

**Confirmation protocol**: When you find an improvement at 200 rounds, ALWAYS re-run at 2000 rounds before declaring it real. About 50% of 200-round "improvements" are statistical noise. Small gains (< 0.02 avg_score at 200r) are especially suspect.

## Important Notes

**NEVER STOP**: Once the experiment loop has begun (after initial setup), do NOT pause to ask the human if you should continue. Do NOT ask "should I keep going?" or "is this a good stopping point?". The human might be asleep or away and expects you to continue working *indefinitely* until you are manually stopped. You are autonomous. If you run out of ideas, think harder — re-read the opponent warriors for weaknesses, try combining previous near-misses, try more radical changes. The loop runs until the human interrupts you, period.

**Statistical significance matters**: A 200-round eval has meaningful noise. If an improvement is less than ~0.02 avg_score, it might be statistical artifact. Run at 2000 rounds before declaring something a real improvement. Record which round count was used.

**Think about WHY**: Before each experiment, reason about what you expect to happen and why. After results, think about what the data tells you. This isn't random search — you should develop hypotheses, test them, and learn from the results. The best improvements come from understanding the game mechanics, not from blind parameter sweeps.
