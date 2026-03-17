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

**Arena parameters (configurable via `--arena` flag):**

| Parameter | Standard 94nop (default) | Modelwar.ai 25200 |
|-----------|-------------------------|-------------------|
| Core size | 8,000 cells | 25,200 cells |
| Max warrior length | 100 instructions | 5,040 instructions |
| Max cycles per round | 80,000 | 252,000 |
| Max processes | 8,000 | 25,200 |
| Min separation | 100 | 100 |
| P-Space size | 500 | 500 |

### Critical: Number Theory

The core size factorization determines the strategy landscape.

**Standard 8,000 core:** 8,000 = 2⁶ × 5³

- Scanner step sizes MUST be coprime to 8,000 — otherwise the scanner can never visit the full core.
- Any step divisible by 2 or 5 leaves blind spots.
- **Use prime numbers ≥ 3 (excluding 5) for step sizes.** Primes like 3, 7, 11, 13, etc. guarantee full coverage.
- Common competitive steps: 3044, 2389, 5039 (all prime).

**Modelwar.ai 25,200 core:** 25,200 = 2² × 3² × 5² × 7

- Steps divisible by 2, 3, 5, or 7 leave blind spots.
- **Use prime numbers ≥ 11 for step sizes.** Primes are always coprime to 25,200.
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

## Deep Core War Theory

This section contains deep knowledge about Core War mechanics. Use it to design experiments that go beyond parameter tuning.

### How Scanning Works

A scanner steps through the core looking for non-zero cells (evidence of an opponent). The two main scanner types:

**CMP/SNE Scanner** (4 instructions per check):
```
scan    sne   first+gap, first    ; compare two cells `gap` apart
        add   inc, scan           ; advance by `step`
        jmp   scan                ; repeat if equal
        ; ... attack code         ; trigger on mismatch
```

**Oneshot Scanner** (2 instructions per check — faster):
```
scan    add   inc, scanptr
scanptr sne   first+gap, }first   ; predecrement B-indirect scans AND advances
        djn.f scan, *scanptr      ; loop with built-in counter
```

The oneshot is faster (2 vs 4 instructions per probe) but harder to get right. The `}` (B-postincrement) mode makes the scan pointer self-advancing. The `djn.f` provides both loop control and a second comparison in one instruction.

**Why step size is the most important parameter:** The step determines which cells get probed. Coverage = `coreSize / GCD(step, coreSize)`. If `GCD(step, 25200) = 1` (coprime), coverage = 25200 (100%). If `GCD = 3`, coverage = 8400 (33%). Primes ≥ 11 guarantee full coverage.

But not all coprime steps are equally good. Smaller steps (e.g., 3037) mean the scanner passes more cells between probes, but each probe is closer to the previous one — systematic local coverage. Larger steps (e.g., 7211) spread probes across the core faster — better early detection probability but potentially slower to complete full coverage. The optimal step balances early detection speed with full-core sweep efficiency.

### How Bombing Works

**DAT bombs** kill any process that executes them. This is the standard weapon. A bomber throws DAT instructions at regular intervals across the core.

**SPL bombs** (`spl #0, #0`) force the target to fork a useless process. This dilutes the enemy's process queue — each real process runs slower because it shares cycles with useless ones. SPL bombs don't kill, they slow. Useful in combination with other attacks, but alone they create ties not wins.

**JMP bombs** redirect target processes to a location (often a DAT trap or a "pit"). This is how vampires work — the bomb doesn't kill, it captures.

**Bomb spacing matters.** When a scanner detects an opponent, it attacks the detected area. The `gate` pointer advances through the target zone, dropping bombs. The `dptr` (decrement pointer) controls how many bombs get dropped and how wide the attack area is. Larger `dptr` values = wider clear area but slower per-location coverage.

### The Clear Mechanism

When a scanner finds an opponent, it needs to DESTROY the opponent code, not just hit one cell. The "clear" is a bombing loop that carpet-bombs the detected area:

```
bptr    dat    #1, #11
dptr    spl    #dec, 9
clear   mov    *bptr, >gate     ; copy bomb to target, advance gate
        mov    *bptr, >gate     ; second bomb per cycle (faster coverage)
        djn.f  clear, }dptr     ; decrement counter, loop until done
```

The `>gate` (B-postincrement) automatically advances the target pointer after each bomb. Two `mov` instructions per loop iteration doubles the bombing rate. `djn.f` uses BOTH fields for loop control, squeezing maximum damage per cycle.

**Clear decrement (`dptr` initial value):** Controls how many cycles the clear runs. Higher value = more area covered, but the scanner is stuck clearing while the opponent might still have active processes elsewhere. Lower value = quicker return to scanning, but might miss parts of the enemy.

### Imp Mechanics

An imp is `mov.i #1, step` — it copies itself forward by `step` cells each cycle. A single imp is nearly impossible to kill (it only occupies one cell at a time and keeps moving), but it can only tie (it doesn't attack anything).

**Imp rings:** Multiple imps at regular spacing form a "ring" that sweeps through the core. The spacing must be coprime to 25200 for full coverage. Common pattern: SPL tree creates N processes, each becomes an imp at different offsets.

**Imp gates:** Defense against imps. A `dat 0, 0` at a strategic location acts as a "gate" — if an imp copies itself onto the DAT, the DAT kills the imp's next iteration. Gates work because the imp's `mov.i` copies the ENTIRE instruction (including the DAT opcode), overwriting the imp's own `mov.i` instruction.

**Imp spirals:** An imp ring where the spacing creates a spiraling pattern through the core. With K imps at spacing S, the spiral covers the core in `25200 / (K * GCD(S, 25200))` cycles. For full coverage, S must be coprime to 25200.

### Boot-Copy (Booting)

A warrior copies itself to a new location before executing. This separates the warrior's "visible" code (the boot-copy instructions) from its actual running location. Benefits:
- Enemy scanners find the boot code (now inert DATs), not the running warrior
- Allows using the full 5040 instruction budget — boot-copy code is disposable after execution
- Can set up decoys at the original location

Boot-copy adds initial delay (copying takes cycles) but the stealth advantage can be worth it. The tradeoff: time spent copying is time NOT spent attacking.

### Quickscanning (Qscan)

A preamble that checks specific addresses BEFORE starting the main strategy. Uses `sne/seq` pairs to probe locations:

```
sne   qstep*3,  qstep*3+qgap    ; probe pair 1
seq   qstep*7,  qstep*7+qgap    ; anti-probe (skip if this matches)
jmp   found                      ; detection! route to attack
```

The `sne/seq/jmp` pattern is a two-stage check: `sne` triggers on non-zero, `seq` cancels false positives. This reduces false detection of core noise.

**Qscan is classification, not detection.** Against tiny warriors (< 30 instructions), qscan almost never triggers because the chance of any probe landing on the small footprint is negligible. Against larger warriors (100+ instructions), qscans can reliably classify opponent type and route to the optimal counter-strategy.

**Key insight for 25200 core:** With 5-6 probe pairs, qscan checks ~12 cells out of 25,200. Against a 21-instruction warrior, detection probability ≈ 1 - (1 - 21/25200)^12 ≈ 1%. Against a 200-instruction warrior, ≈ 9%. Qscans are most valuable in metas with diverse warrior sizes.

### Guenzel Clear

A specific clear technique that uses SPL bombs AND DAT sweeping:

```
clear   spl    #0, >ptr      ; SPL bomb: forces enemy to fork useless process
loop    mov    clrbomb, >ptr  ; DAT bomb: kills processes
        djn.f  loop, >ptr    ; advance and repeat
```

The SPL bomb at the start serves dual purpose: (1) dilutes enemy processes, (2) creates a "process wall" — enemy processes that execute the SPL spawn children near the SPL, which then execute surrounding DATs. It's more effective than pure DAT bombing because it actively corrupts enemy process distribution.

### P-Space (Persistent Memory)

P-space is 500 cells of memory that persists between rounds. P[0] stores the previous round's result (0=loss, 1=tie, 2=win). P[1]-P[499] are available for the warrior.

**Switcher warriors** use P-space to change strategy based on prior results: "I lost last round using strategy A → try strategy B this round." This is the most practical P-space use.

**Implementation:**
```
ldp.ab  #0, result    ; load previous result into 'result'
result  jmz    strat_a ; if lost (0), try strategy A
        jmp    strat_b ; otherwise try strategy B
```

P-space enables reactive play. A scanner that lost might switch to a paper fallback. A paper that lost might switch to a scanner. The warrior adapts to the opponent across a multi-round match.

**State machines:** More complex P-space strategies track multiple rounds, implementing a finite state machine: "If I lost twice with scanner, try clear/imp. If that lost, try paper. If paper won, stick with it." The 500-cell P-space is more than enough for sophisticated state tracking.

**Handshake:** Two copies of the same warrior can detect each other via P-space. Both write to a known P-space location, then read it. If the value matches, they know they're the same warrior → play passively (imp ring) to guarantee ties. This is valuable in tournament formats.

### Advanced Techniques

**DJN streams:** A continuous stream of `djn` instructions that decrement a target location every cycle. Used in clear routines to create "process traps" — if an enemy process enters the djn stream zone, it gets caught in a decrement loop that eventually kills it.

**Decoy makers:** Warriors that scatter non-DAT instructions across the core. These waste enemy scanner attacks — the scanner detects the decoy, spends cycles clearing it, while the real warrior operates elsewhere. With 5040 instructions, a warrior can place hundreds of decoys.

**Core-clear:** Rather than scanning for enemies, a core-clear warrior systematically wipes the entire core clean with DAT bombs. Uses parallel processes (via SPL tree) to clear from multiple positions simultaneously. Effective against papers and stones; weak against scanners that find the clear warrior before it finishes.

**Self-splitting warriors:** Fork processes to run multiple strategies simultaneously. Common: SPL tree → half processes run scanner, half run imp ring. The cost is process dilution (each process runs at 1/N speed), but the coverage of two strategies can be worth it.

## Prior Research Results

These experiments have been run on this exact 25,200 core. Study the results to avoid repeating dead ends and to build on what worked.

### What Worked

**Oneshot scanner (step=9001):** 21 instructions. Scans at 2 instructions per check. Beats all current meta opponents (56-60% vs scanners, 40-48% vs papers). Won #1 on competitive ladder. Its strength is TINY footprint — nearly invisible to enemy scans. Prime step = full core coverage.

**Guenzel clear + imp (Dustfall):** SPL tree → 32 processes. Half run Guenzel clear, half run imp ring (spacing 2291). Results: 90% vs stones, 81% vs paper+bomber, 58% vs scanners, 72% ties vs papers. Dominant against stones and papers. Imp ring provides tie insurance. Clear sweeps the ENTIRE core in ~788 cycles.

**Qscan → Scanner OR Clear/Imp (DustfallQS):** 5-pair quickscan routes to either oneshot scanner or Guenzel clear+imp. Best generalist: 70% vs some scanners, 46% vs papers, 52% vs stones. The routing decision fundamentally changes the archetype, even with low qscan hit rates.

**Key step sizes found to be strong:** 7211 (breakthrough value, +8.9% improvement), 9001, 4201, 5039. All prime. The specific value of 7211 was discovered through empirical testing and outperformed 167 other primes tested.

### What Failed (and WHY — study these failure modes)

**Temporal detection (Shapeshifter):** Probe random locations, wait, probe again — detect opponent by movement. FAILED because in 25200 core, a 21-instruction warrior occupies 0.08% of cells. Random probes have negligible hit probability. Would need ~2500 probes for 50% detection. Any detection scheme requiring random hits is broken at this core size.

**Corruption bombs (imp/ADD/SUB):** Using `mov.i #0, 1` (imp instruction) as bombs instead of DAT. Creates TIES not wins — target processes become imps that survive indefinitely. DAT is strictly better because it KILLS. Any bomb that allows the target process to survive creates ties.

**Vampire (JMP fangs):** Place JMP instructions as "fangs" to capture enemy processes. FAILED because enemy processes don't execute fangs — scanners/papers/stones have tight PC loops (3-4 instructions). Their PCs never land on our fang locations. Vampires only work against wandering/corrupted PCs.

**Multi-rate bomber (parallel bombing threads):** Fork 3 processes bombing at different step sizes. FAILED due to process dilution: with N processes, each bombs at 1/N rate. Total bombing rate is IDENTICAL to single-threaded. Multi-threading interleaves coverage without increasing rate.

**Paper + bomber hybrid:** Paper with a dedicated DAT bombing thread. FAILED because the bomber thread at 1/N speed is negligible. Against other papers it changes nothing (100% ties). The bomber needs enough speed to matter, which process dilution prevents.

**Massive quickscan (100+ probes):** 300+ instruction qscan for high detection. PARTIALLY WORKED against papers/stones (46-53%), but the huge code size makes the warrior a barn door for enemy scanners. The qscan code itself becomes the weakness.

### Architectural Laws of the 25200 Core

1. **Sparsity dominates.** A 21-instruction warrior occupies 0.08% of 25200 cells. Random probing fails. Only systematic scanning works. Small footprint = survival advantage.

2. **Process dilution always costs.** Every SPL halves process speed. The ONLY designs that overcome this are when ALL processes do the SAME thing (32 clear processes = 32× area coverage, not 1/32 speed penalty each).

3. **The RPS triangle is inescapable.** Scanner > Paper > Stone > Scanner. No single warrior beats all three types. Qscan routing and P-space switching are the only tools for adapting. The optimal warrior is a hybrid that routes to the right counter-strategy.

4. **Compact + fast beats clever.** Every instruction added makes you larger, easier to find, slower to boot. The 21-instruction Oneshot25k is nearly invisible. A 300-instruction warrior is a barn door. Elegance = maximum effect from minimum code.

5. **DAT kills, everything else doesn't.** Only DAT bombs reliably win games. SPL, JMP, ADD bombs create interesting effects but ultimately lead to ties or slower kills. Build around DAT.

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
node evaluate.cjs warrior.red                # Quick eval (200 rounds, standard 8000/100 arena)
node evaluate.cjs warrior.red 2000           # Full confirmation (2000 rounds)
node evaluate.cjs warrior.red 200 --arena 25200,5040,252000,25200,100,500   # Custom arena
```

### Arena Configuration

The evaluator defaults to the **standard 94nop hill** (coreSize=8000, maxLength=100). You can override with `--arena`:

```
--arena coreSize,maxLength,maxCycles,maxProcesses,minSeparation,pSpaceSize
```

| Preset | Arena Parameters |
|--------|-----------------|
| Standard 94nop (default) | `8000,100,80000,8000,100,500` |
| Modelwar.ai 25200 | `25200,5040,252000,25200,100,500` |

### Output Format

The script outputs machine-readable results on stdout:
```
avg_score:    1.234567
total_points: 7.4 / 30.0
opponents:    10
rounds:       200
arena:        8000/100
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
