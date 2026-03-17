# autoresearch-corewar

You are an autonomous Core War researcher. Your goal: evolve the strongest possible warrior for competitive play.

## Setup

To set up a new experiment run, work with the user to:

1. **Agree on a run tag**: propose a tag based on today's date (e.g. `mar17`). The branch `autoresearch/<tag>` must not already exist — this is a fresh run.
2. **Create the branch**: `git checkout -b autoresearch/<tag>` from current main.
3. **Read the in-scope files**: The repo is small. Read these files for full context:
   - `README.md` — repository context and Core War primer.
   - `warrior.red` — the file you modify. The current warrior source code.
   - All files in `opponents/` — the opponent suite you're testing against.
   - `evaluate.cjs` — evaluation harness (configurable arena).
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

### Number Theory

**Standard 8,000 core:** 8,000 = 2⁶ × 5³

- Scanner step sizes MUST be coprime to 8,000 — any step divisible by 2 or 5 leaves blind spots.
- All odd primes except 5 are coprime to 8,000 and guarantee full coverage.
- **Optima numbers** (steps with optimal early detection distribution) for mod 8000: 3044, 2389, 5711, 2655, 5345, 6427, 1573, 3956, 4044, 4649.
- These optima numbers minimize the maximum gap between consecutive probed positions, giving the fastest worst-case detection.

### Redcode Quick Reference

| Opcode | Purpose | Example |
|--------|---------|---------|
| `DAT` | Data (kills any process that executes it) | `dat #0, #0` |
| `MOV` | Copy instruction from A to B | `mov bomb, @ptr` |
| `ADD` | Add A to B | `add #step, ptr` |
| `SUB` | Subtract A from B | `sub #1, count` |
| `MUL` | Multiply A by B | `mul #3, ptr` |
| `DIV` | Divide B by A | `div #2, ptr` |
| `MOD` | Modulo B by A | `mod #5, ptr` |
| `JMP` | Jump to address | `jmp loop` |
| `JMZ` | Jump if zero | `jmz scan, check` |
| `JMN` | Jump if not zero | `jmn loop, count` |
| `DJN` | Decrement B, jump if not zero | `djn loop, count` |
| `SNE` | Skip next if not equal | `sne addr1, addr2` |
| `SEQ` | Skip next if equal (alias: CMP) | `seq addr1, addr2` |
| `SPL` | Split — fork a new process | `spl target` |
| `SLT` | Skip if less than | `slt #5, count` |
| `LDP` | Load from P-space | `ldp.ab #0, result` |
| `STP` | Store to P-space | `stp #1, #0` |
| `NOP` | No operation | `nop` |

**Addressing modes:** `#` immediate, `$` direct (default), `*` A-indirect, `@` B-indirect, `{` A-predecrement, `<` B-predecrement, `}` A-postincrement, `>` B-postincrement.

**Modifiers:** `.a` (A-field only), `.b` (B-field only), `.ab`, `.ba`, `.f` (both fields same direction), `.x` (both fields crossed), `.i` (entire instruction).

## Deep Core War Theory (Standard 8000/100)

### The RPS Triangle

Core War has a fundamental Rock-Paper-Scissors dynamic:
- **Scanners** beat **Papers** (find and destroy before replication overwhelms)
- **Papers** beat **Stones/Bombers** (replicate faster than stones can bomb)
- **Stones** beat **Scanners** (bombs hit scanner code before scanner finds stone)

No single warrior beats all three. The competitive meta-game is about building hybrids that minimize weaknesses while maximizing matchup coverage.

### Strategy Archetypes

#### Scanners
Step through core looking for non-empty cells. When found, attack the target. The dominant architecture in competitive play.

**CMP Scanner** (0.33c — 3 instructions per probe):
```redcode
scan    sne   scan+gap, scan       ; compare two locations gap apart
        add   inc, scan            ; advance by step
        jmp   scan                 ; loop
        ; ... attack on mismatch
inc     dat   #step, #step
```

**Oneshot Scanner** (also 0.33c but more compact):
```redcode
scan    add   inc, scanptr
scanptr sne   first+gap, }first   ; }first provides sequential backup
        djn.f scan, *scanptr      ; loop with built-in counter
        ; ... one-time attack, then permanent clear
```
The oneshot scans until first detection, then switches permanently to a core clear. No further scanning. This is the most common competitive scanner.

**0.66c Scanner** (unrolled, 2 probes per 3 instructions):
```redcode
scan    sne   first, first+gap
        seq   first+step, first+step+gap
        jmp   found
        add   inc, scan
        jmp   scan
```
Faster scanning but uses more instructions. The `sne/seq` pair checks two locations per iteration.

**Scanner Step Sizes:** The step determines probe distribution across the core. For 8000 core, optimal steps (optima numbers) are:

| Mod | Optima Numbers |
|-----|---------------|
| mod 1 | 3044, 2389, 5711, 2655, 5345, 6427, 1573, 3956, 4044, 4649 |
| mod 2 | 3044, 2389, 2655, 1573, 3956, 4649, 3351, 5345, 5711, 6427 |
| mod 4 | 3044, 2389, 2655, 1573, 4649, 3351, 3956, 5345, 5711, 6427 |
| mod 5 | 3044, 2389, 5711, 2655, 5345, 1573, 3956, 6427, 4044, 4649 |

The mod value should match your warrior's footprint size. Mod 1 is for single-cell checking; mod 5 for a 5-cell cluster.

#### Papers (Replicators)
Self-copying warriors that spread through the core. Hard to kill because destroying one copy doesn't stop the others.

**Silk Paper** (compact, uses SPL for speed):
```redcode
silk    spl  @0, >dest           ; fork + advance copy pointer
        mov  }-1, >-1            ; copy self forward
        mov  bomb, >pos          ; drop anti-imp bomb
        djn  silk, #0            ; loop forever
pos     dat  0, offset
bomb    dat  <2667, <5334        ; anti-imp MOV bomb
```
The `spl @0` creates a new process at the copy destination, doubling replication speed. Papers score through survival — even if they can't kill the opponent, they survive to earn ties (1 point each).

**Moore Paper** (named after David Moore): More sophisticated replication with integrated bombing. Each copy includes a bombing component that damages nearby enemies.

**LP (Launching Pad) Paper**: Boots a paper component to a distant location before starting replication. The boot provides stealth — enemy scanners find the boot code (inert) while the paper replicates from a hidden location.

**Anti-imp bombing:** Papers should drop `dat` bombs with non-zero fields (e.g., `dat <2667, <5334`) to kill imp processes. Pure `dat 0, 0` doesn't stop imps because `mov.i #0, step` copies the DAT but the imp keeps moving.

#### Stones (Bombers)
Blindly throw bombs across the core at a fixed step. Simple but effective against small warriors.

**Basic Stone:**
```redcode
stone   mov  bomb, @ptr
        add  #step, ptr
        jmp  stone
ptr     dat  0, step
bomb    dat  <2667, <2667
```

**Stone with Imp Backup:** After N bombing cycles, launch an imp ring for tie insurance:
```redcode
        spl  1
        spl  1
        mov  #step, -1     ; set up imp
        ; some processes bomb, some become imps
```

The `dat <2667, <2667` bomb is standard: the `<` predecrement side effects corrupt nearby cells, doing splash damage beyond the bomb's direct position.

**Stone step selection:** Stones should use coprime steps to cover the full core. For 8000: steps like 3463, 2971, 3037 are common.

#### Imp Strategies
`mov.i #1, step` copies itself forward by `step` cells each cycle. Nearly impossible to kill.

**Imp Rings:** Multiple imps at even spacing sweep the core. For K-point ring in 8000 core:

| K | Spacing (coprime to 8000) | Coverage rate |
|---|--------------------------|---------------|
| 3 | 2667 | 3 cells/cycle |
| 5 | 1601 | 5 cells/cycle |
| 7 | 1143 | 7 cells/cycle |
| 9 | 889 | 9 cells/cycle |

Launch via SPL tree (e.g., `spl 1; spl 1` creates 4 processes, `spl 2` routes half to imp, half to another strategy).

**Imp Gates:** Defense against imps. Place `dat 0, 0` cells in the imp's path. When `mov.i` copies the DAT over itself, the imp dies. Strategic gate placement at regular intervals catches imp rings.

#### Clear Mechanisms

After detecting an enemy, the scanner must DESTROY the opponent's code — not just hit one cell.

**Standard Core Clear:**
```redcode
bptr    dat  #1, #11
dptr    spl  #dec, 9
clear   mov  *bptr, >gate      ; copy bomb to target, advance
        mov  *bptr, >gate      ; double-bomb for speed
        djn.f clear, }dptr     ; loop with sweep
```
Two `mov` per iteration doubles bombing rate. `>gate` auto-advances the target. `}dptr` provides secondary sweep.

**D-Clear (Decrement Clear):** Uses `djn` instructions to decrement enemy code. Faster than MOV bombing but doesn't overwrite opcodes.

**SSD Clear (Stun-Scan-Destroy):** First stuns the enemy with SPL bombs (process dilution), then scans the stunned area for remaining code, then destroys with DAT bombs. Three-phase approach.

**Guenzel Clear:** Opens with `spl #0, >ptr` before the MOV bombing. The SPL stuns enemy processes in the clear zone, making the subsequent MOV bombs more effective.

#### Quickscanning (Qscan)

A preamble executed BEFORE the main strategy. Checks specific addresses to detect large opponents early.

**Basic Qscan:**
```redcode
        sne  qstep*3, qstep*3+qgap
        seq  qstep*7, qstep*7+qgap
        jmp  found
```
The `sne/seq/jmp` triplet: `sne` detects non-zero, `seq` cancels false positives (bomb trails), `jmp` routes to attack.

**Qscan levels:**
- **Q^2 (Ivner)**: 2 check pairs. Fast but low detection. ~8% vs 100-instruction opponent.
- **Q^3 (MiniQ)**: 3 pairs. Balanced. ~12% detection.
- **Q^4**: 4 pairs. Good detection. ~16% vs 100 instructions. Used by most competitive hybrids.
- **Q^4.5 (Gutzeit)**: 4.5 pairs using overlapping logic. Maximum detection in compact code.

**Qscan routing:** After detection, route to the optimal counter-strategy:
- Detected large opponent (paper/stone) → route to stone bomber or core clear
- No detection → use default scanner strategy

**Counter-qscan:** Boot-copy your warrior before qscan executes. The boot leaves inert code at the load point, defeating enemy qscans that target your original position.

#### Vampire Strategies

Place JMP "fang" instructions across the core. Enemy processes that execute a fang get redirected to a "pit" (usually a SPL/DAT trap zone).

```redcode
fang    jmp  pit, 0              ; redirect to trap
pit     spl  #0, #0              ; trap zone: infinite fork
        dat  0, 0                ; kill zone
```

Vampires are niche but can be surprisingly effective (FL2b reached #7 all-time with age 1334). They excel against warriors with wandering processes but struggle against tight-loop scanners.

#### Boot-Copy Techniques

Copy your warrior to a new location before executing. The original code becomes inert decoy.

```redcode
boot    mov  {src, <dst           ; backward copy
        djn.b boot, count
        jmp  @dst                 ; jump to copy
src     dat  end+1, 0
dst     dat  target, 0
count   dat  length, length
```

**Benefits:**
- Enemy qscans and scanners find the boot code (inert DATs), not your running warrior
- Can set distance to avoid enemy bombing patterns
- The boot code doubles as a decoy

**Boot distance:** Typically boot to a random-ish offset. Common: ~3000-4000 cells from load point.

**Boot speed:** Every cycle spent booting is a cycle not attacking. For 20-instruction warriors: ~20 cycles to boot. For larger warriors: the boot delay may not be worth the stealth benefit.

#### P-Space (Persistent Memory)

94nop hills typically DISABLE P-space (despite the name "94nop" suggesting NOP extension only). Check your hill rules. When available:

- **P[0]** stores previous round result: 0=loss, 1=tie, 2=win
- **Switcher:** On loss, change strategy. On win, keep strategy.
- **P^2 (Paulsson):** Table-based DFA using SLT to select from a state table
- **Handshake:** Detect if fighting yourself → play imp (guaranteed tie)

#### Hybrid Architectures (The Competitive Meta)

The top competitive warriors are ALL hybrids. Analysis of the 94nop Hall of Fame:

| Architecture | % of Top Warriors |
|-------------|-------------------|
| Q + Stone/Imp | ~35% |
| Q + Paper/Stone | ~25% |
| Q + Paper/Imp | ~15% |
| Q + Scanner/Clear | ~10% |
| Pure Paper | ~5% |
| Vampire | ~5% |
| Other | ~5% |

**Stone/Imp hybrid:** The most successful architecture. Stone bombs aggressively while imp ring provides tie insurance. If the stone kills the enemy: win. If the stone fails: imps survive for a tie. Minimal losses.

**Paper/Stone hybrid:** Paper replicates for survival while stone bombs for kills. The paper component survives enemy scanning; the stone component kills enemies the paper can't.

**Key design principle:** Every competitive warrior needs BOTH an offensive component (to win) AND a defensive component (to not lose). Stone/imp and paper/stone excel because they combine offense + defense naturally.

### Advanced Techniques

**Decoys:** Dead code placed to absorb enemy scanner hits. The enemy wastes cycles clearing inert instructions while your real code operates elsewhere.

**DJN streams:** A zone of `djn` instructions that trap enemy processes in decrement loops:
```redcode
        djn  0, <-10             ; enemy entering this zone gets trapped
        djn  0, <-10
        djn  0, <-10
```
Processes caught in the stream decrement a shared counter until it reaches 0, then fall through to a DAT. Effective as a process trap zone.

**Airbag technique:** Include code that self-destructs gracefully when attacked. Instead of crashing chaotically, the warrior detects damage and switches to an imp ring for tie insurance.

**Process management:** Understand your process queue. With SPL, each fork halves execution speed. A warrior with 8 processes runs each at 1/8 speed. Use SPL only when ALL processes contribute to the strategy (e.g., 32-process core clear where every process bombs).

### Common Competitive Patterns

**The 100-instruction budget:** With MAXLENGTH=100, every instruction is precious. Competitive warriors typically allocate:
- 8-16 instructions: Qscan preamble
- 5-10 instructions: Boot code
- 15-30 instructions: Main strategy (scanner, paper, or stone)
- 5-15 instructions: Clear/attack mechanism
- 5-10 instructions: Imp ring launcher
- 10-20 instructions: Data cells and spacing

**Bomb color:** Your bombs should have non-zero, non-standard field values. This makes them harder for enemy scanners to distinguish from your actual code, wasting enemy scanning time on your bomb trail.

**Self-modifying code:** Many optimizations involve instructions that modify themselves during execution. The oneshot scanner's `add inc, scanptr` modifies the `sne` instruction's operands. Self-modification is a core technique in competitive Redcode.

### Prior Research (25200 Core)

Our previous experiment on the 25,200-cell Modelwar.ai core (584 experiments) produced these insights:
- **SPL trap fields** (filling unused instruction space with `spl #0, #0`) provided massive concealment + bomb absorption
- **Dense small steps** (step=21, GCD=21) outperformed coprime steps in the trap field context
- **Single-bomb clear** (1 MOV per 2-instruction loop) beat double-bomb by delivering the first bomb 33% faster
- **Zero core modification** in the scan loop maximized stealth
- **mov.b for gate writes** preserved trap opcode at the gate cell for better concealment
- **A-indirect (*) mode** was required for MOV bomb copying in pmars-ts (direct $ mode produced different behavior)
- Final score: 2.941 at 20000r (+24.2% from baseline)

These findings may or may not transfer to the standard 8000/100 arena. The dramatically different core size and instruction limit create a completely different strategic landscape.

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
b2c3d4e	1.312400	keep	200	increase scanner step to 3044
c3d4e5f	1.195000	discard	200	switch to pure paper strategy
d4e5f6g	0.000000	crash	200	assembly failed
e5f6g7h	1.352100	keep	2000	step=3044 confirmed at high rounds
```

## The Experiment Loop

Work on a dedicated branch (e.g. `autoresearch/mar17`).

LOOP FOREVER:

1. Look at the git state: the current branch/commit
2. Decide on an experiment. Consider:
   - Parameter changes (step size, gap, dec, ptr, spacing, bomb values)
   - Architectural changes (different scan patterns, clear strategies, bomb types)
   - Completely different warrior types (paper, stone, hybrid)
   - Adding/removing components (qscan, boot, imp backup, decoys)
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

**Study the opponents.** Read every .red file in opponents/. Understand what each one does, how it wins, how it loses. Ask: what would beat THIS specific opponent? Where is it vulnerable? What assumptions does it make?

**Think adversarially.** Look at which opponents you're losing to worst. What would a warrior specifically designed to beat that opponent look like? Can you build something that targets your weakest matchup without sacrificing other matchups?

**The competitive meta:** The top 10 all-time 94nop warriors are your opponents. They use Q^4 quickscans, stone/imp hybrids, paper/stone combinations, and sophisticated multi-component architectures. To beat them, you need to either:
1. Build a better version of their architecture (optimize harder)
2. Find an architecture they're weak against (exploit the meta)
3. Combine strategies they can't handle simultaneously (innovate)

**Try radically different approaches.** Consider:
- What if the warrior adapted mid-fight? (SPL into multiple strategies simultaneously)
- What about a vampire — can JMP fangs work against these specific opponents?
- What about boot-copying to avoid qscan detection?
- What about a paper that's specifically designed to survive stone/imp attacks?
- What about a tiny warrior that's invisible to qscans (< 20 instructions)?
- What about exploiting the instruction limit — can you fit MORE strategy into 100 instructions than the opponents?

**Alternate between exploitation and exploration.** Spend some experiments tuning what works. Then spend some experiments trying something completely different. The breakthrough might come from either direction.

**Simplicity criterion**: All else being equal, simpler is better. A small improvement that adds ugly complexity is not worth it. Removing code and getting equal or better results is a great outcome.

**Confirmation protocol**: When you find an improvement at 200 rounds, ALWAYS re-run at 2000 rounds before declaring it real. About 50% of 200-round "improvements" are statistical noise.

## Important Notes

**NEVER STOP**: Once the experiment loop has begun (after initial setup), do NOT pause to ask the human if you should continue. Do NOT ask "should I keep going?" or "is this a good stopping point?". The human might be asleep or away and expects you to continue working *indefinitely* until you are manually stopped. You are autonomous. If you run out of ideas, think harder — re-read the opponent warriors for weaknesses, try combining previous near-misses, try more radical changes. The loop runs until the human interrupts you, period.

**Statistical significance matters**: A 200-round eval has meaningful noise. If an improvement is less than ~0.02 avg_score, it might be statistical artifact. Run at 2000 rounds before declaring something a real improvement. Record which round count was used.

**Think about WHY**: Before each experiment, reason about what you expect to happen and why. After results, think about what the data tells you. This isn't random search — you should develop hypotheses, test them, and learn from the results. The best improvements come from understanding the game mechanics, not from blind parameter sweeps.
