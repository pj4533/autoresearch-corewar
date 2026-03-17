# Core War Theory: Standard 94nop Hill (CORESIZE=8000, MAXLENGTH=100)

Comprehensive strategic reference for the standard 94nop competitive hill.

**Arena Parameters:**
- CORESIZE: 8000
- MAXLENGTH: 100 instructions
- MAXCYCLES: 80,000
- MAXPROCESSES: 8,000
- MINDISTANCE: 100
- PSPACESIZE: 500 (when enabled; 94nop = no p-space)

**Core Factorization:** 8000 = 2^6 x 5^3

---

## 1. Scanner Types

Scanners search core for non-zero cells (evidence of opponent code), then attack the detected location. They are the "scissors" in the RPS triangle: they beat papers but lose to stones.

### 1.1 CMP Scanner (SEQ/SNE)

The classic scanner compares two core locations separated by a gap. If they differ, something non-empty is there.

```redcode
scan    sne   scan+gap, scan       ; compare locations `gap` apart
        add   inc, scan            ; advance scan pointer by step
        jmp   scan                 ; loop if equal (empty core)
        ; ... attack on mismatch
inc     dat   #step, #step
```

**Speed:** 0.33c (3 instructions per probe). Each cycle checks one pair of locations.

**Variants by scan speed:**

- **0.5c scanner**: Checks one location every 2 cycles. Uses `sne/jmp` pairs with self-modifying code. Example: Blur series by Anton Marsden.
- **0.33c scanner**: The standard 3-instruction loop above.
- **0.66c scanner**: Overlaps two scan streams or uses unrolled loops. Very fast but requires more code.
- **0.8c scanner**: Heavily unrolled. Trades code size for speed. Rarely practical under MAXLENGTH=100.

**Gap selection:** The gap between the two compared locations affects what gets detected. On-axis scanners use gap = CORESIZE/2 = 4000 (comparing locations exactly opposite in core). Off-axis scanners use other values.

**Color:** Bombs dropped by the scanner are "colored" (have non-zero fields) and are thus visible to other scanners. This matters: if your bombs look like opponent code, enemy scanners waste time attacking your bomb trail.

### 1.2 Oneshot Scanner

Scans until the first target is found, then permanently switches to a core-clear. No further scanning occurs. This is the dominant scanner architecture.

```redcode
scan    add   inc, ptr
ptr     sne   first+gap, first     ; compare two locations
        djn.f scan, *ptr           ; loop with counter
        ; found something -> switch to clear
        jmp   clear
```

The `djn.f` provides both loop control and, through its field decrement, a secondary detection mechanism. Once something is found, the warrior transitions to a two-pass core-clear (SPL carpet then DAT sweep) or a D-clear.

**Why oneshot dominates in 8000 core:** The core is small enough that a single detection plus thorough clear can kill the opponent. Ongoing scanning wastes cycles that could be spent clearing.

### 1.3 B-Scanner / F-Scanner

- **B-Scanner**: Only checks B-fields for non-zero values using JMN/DJN. Faster but misses opponents whose code has all-zero B-fields.
- **F-Scanner**: Checks both A and B fields. More thorough but slower (uses SNE.I or CMP.F).

### 1.4 Bishot Scanner

Performs two scans before switching to clear. After the first detection, it notes the location and continues scanning briefly. If a second detection occurs, it attacks the second location (which may be the real warrior vs. a decoy). If no second hit, it attacks the first.

This provides rudimentary decoy avoidance at the cost of delayed attack.

### 1.5 Blur Scanner

A continuous SPL carpet scanner that lays down SPL bombs while scanning:

```redcode
scan    sne   ptr+gap, ptr         ; scan
        add   inc, scan            ; advance
        jmp   scan                 ; loop
        ; on detection:
        spl   #0, >ptr             ; begin SPL carpet
        mov   bomb, >ptr           ; DAT bomb follows
        djn.f -2, >ptr             ; continue clearing
```

"0.5c scan, 0.25c SPL carpet -> SPL/DAT core clear." The SPL carpet stuns opponent processes before the DAT sweep kills them, making the clear more thorough.

### 1.6 Optimal Parameters for 8000 Core

- **Step size:** Must be coprime to 8000 (not divisible by 2 or 5). Common competitive steps: **3044, 3039, 2389, 5039, 2667** (all coprime to 8000). Many top warriors use step values near 3000-3400.
- **Scan gap:** Commonly CORESIZE/2 = 4000 for on-axis, or values like 100-200 for off-axis.
- **Scan count before clear:** Oneshot = 1 detection. Bishot = 2 detections.

---

## 2. Clear Mechanisms

The clear is what actually kills the opponent after detection. A poor clear leaves opponent processes alive; a good clear wipes everything.

### 2.1 Two-Pass Core-Clear

The most thorough clear. First pass lays SPL bombs (stunning), second pass lays DAT bombs (killing):

```redcode
clear   spl   #0, >gate           ; Pass 1: SPL stun carpet
        mov   bomb, >gate         ; Pass 2: DAT kill sweep
        djn.f clear, >gate        ; advance gate, loop
bomb    dat   <2667, <2667        ; self-decrementing DAT bomb
```

**Why two passes:** SPL bombs force enemy processes to fork useless children. These children execute nearby instructions (which are now SPLs), creating an exponential process explosion that dilutes the enemy's process queue. When the DAT sweep arrives, the enemy has thousands of processes, each running at 1/N speed -- they cannot escape.

### 2.2 D-Clear (Decrement Clear)

A 1c (one location per cycle) clear that alternates between DAT bombs and decrementing:

```redcode
gate    spl   #0, <ptr            ; SPL + decrement
        mov   bomb, >ptr          ; DAT bomb + advance
        djn.f gate, >ptr          ; loop
bomb    dat   >-1, >1             ; self-modifying bomb
```

The D-clear continuously decrements core locations while advancing. This disrupts imp rings (which need their exact MOV instruction to survive) and damages code that relies on specific field values. It is "equally good against all imp species" -- scoring 92% wins against various imp types in testing.

**Key advantage:** The DAT `>-1, >1` bomb has postincrement fields that, when executed or overwritten, continue modifying adjacent cells. This creates cascading damage beyond the bomb's landing site.

### 2.3 Guenzel Clear

Named after its inventor. Combines SPL stunning with systematic DAT bombing:

```redcode
clear   spl   #0, >ptr           ; SPL stun
loop    mov   bomb, >ptr         ; DAT bomb
        djn.f loop, >ptr         ; advance and loop
```

The SPL at the start creates a "process wall" -- enemy processes that execute the SPL spawn children near it, which then execute surrounding DATs. More effective than pure DAT bombing because it actively corrupts enemy process distribution.

### 2.4 SSD (Split-Sweep-Destroy)

An advanced three-phase clear:
1. **Split phase:** SPL carpet to stun all enemy processes
2. **Sweep phase:** Systematic core overwrite with DAT
3. **Destroy phase:** DJN stream to catch any survivors

### 2.5 Addition Clear

Instead of overwriting with DAT, adds values to existing instructions, corrupting their fields:

```redcode
clear   add   #step, ptr
        mov.i ptr, @ptr
        jmp   clear
```

This mutates opponent code rather than replacing it. The advantage: mutated code may still "look" non-zero to enemy scanners, causing them to waste attacks on already-corrupted locations. Night Crawler stone uses this technique.

### 2.6 Optimal Clear Parameters for 8000 Core

- **Clear width:** Typically 500-2000 locations per clear cycle
- **Bomb type:** `dat <2667, <2667` is common (predecrement fields create additional damage)
- **Gate advancement:** Use `>` (B-postincrement) for automatic pointer advancement
- **DJN counter:** Controls how long the clear runs. Typical: 200-800 iterations

---

## 3. Paper / Replicator Strategies

Papers are self-replicating warriors that spawn multiple copies across the core. They are the "paper" in RPS: they beat stones (too many copies to bomb) but lose to scissors/scanners (which find and stun them systematically).

### 3.1 Looping Paper

The original replicator: copies itself in a loop, then jumps to the new copy.

```redcode
copy    mov   @src, @dst          ; copy one instruction
        add   #1, src             ; advance source
        add   #1, dst             ; advance destination
        djn   copy, count         ; loop for N instructions
        jmp   @dst                ; jump to new copy
src     dat   #0, #start
dst     dat   #0, #target
count   dat   #0, #length
```

**Weakness:** Slow. Copies sequentially, one instruction at a time. By the time the copy is complete, a scanner has likely found and killed both copies.

### 3.2 Silk Paper

The dominant paper architecture. Splits to the new copy BEFORE finishing the copy operation:

```redcode
silk    spl   @0, step            ; split to new location
        mov.i }silk, >silk        ; copy current instruction forward
        mov.i }silk, >silk        ; copy next instruction
        ; ... (repeat for warrior length)
        add.a #step, silk         ; advance copy pointer
        jmp   silk, {silk         ; restart
```

**Key insight:** The SPL happens first, creating a process at the destination. That process begins executing whatever is there (initially empty core = DAT = it dies, but it will execute the MOV'd instructions as they arrive). The source process then copies instructions to the destination. By the time the copy is complete, the destination process is alive and executing.

"Silk papers employ parallel processes for replication without looping, splitting to a new copy before it finishes duplicating." -- Juha Pohjalainen introduced silk papers in August 1994.

**Modern silk structure (competitive):**

```redcode
step    equ   2667               ; copy distance (coprime to 8000)

silk    spl   step, #0           ; fork to new copy location
        mov.i >-1, }-1           ; copy instruction using postincrement
        mov.i >-1, }-1           ; copy next instruction
        mov.i >-1, }-1           ; copy next
        mov.i bomb, >2005        ; linear bombing (attack while replicating)
        add.a #step, silk        ; advance the replication target
        jmp   silk, {silk        ; restart the cycle
bomb    dat   >2667, >5334       ; bomb with self-advancing fields
```

### 3.3 Sunset Paper

Copies itself through parallel processes and splits before copying. When overwriting opponents, sunset's self-checking mechanism prevents adversary processes from executing sunset code correctly. David Moore published the first in June 2003.

### 3.4 LP (Limited Process) Paper

Operates under constrained process count. Uses fewer SPL operations and focuses on efficient replication with minimal process overhead. Important for hills with low MAXPROCESSES.

### 3.5 Paper with Bombing

Modern competitive papers incorporate bombing into the replication loop:

```redcode
silk    spl   step, #0
        mov.i >-1, }-1
        mov.i >-1, }-1
        mov.i bomb, >target      ; drop bomb while replicating
        mov.i bomb, }target2     ; second bomb (A-indirect for anti-vamp)
        add.a #step, silk
        jmp   silk, {silk
bomb    dat.f >2667, >5334
```

The first bomb uses linear bombing (>target advances each cycle). The second uses A-indirect (}target2) for anti-vampire protection. As noted in CoreWarrior: "The first bomb laid down acts as a pointer for the following stream, laying down a carpet... very effective against 3-point imp rings."

### 3.6 Optimal Paper Parameters for 8000 Core

- **Copy step:** 2667 (= 8000/3 + 1, coprime to 8000) is the classic. Other values: 3620, various primes.
- **Paper length:** 5-8 instructions for silk papers (must fit in MAXLENGTH with any qscan/boot code)
- **Bomb type:** `dat.f >2667, >5334` -- the postincrement fields create advancing bomb trails
- **Bombing targets:** Space bombs ~2000 apart for coverage diversity

---

## 4. Stone / Bomber Strategies

Stones blindly bomb the core at regular intervals. They are the "stone" in RPS: they beat scissors/scanners (too fast and small to scan) but lose to paper (can't bomb all copies).

### 4.1 Classic Dwarf

The simplest bomber:

```redcode
        add.ab #step, 3          ; advance bomb pointer
        mov.i  2, @2             ; drop bomb at pointer
        jmp    -2                ; loop
bomb    dat    #0, #0            ; the bomb
```

**Speed:** 0.33c (bombs one location every 3 cycles).

Step must not divide 8000 evenly or the bomber hits itself. Step of 4 works (8000/4 = 2000 bombs to cover core, never self-bombing if code is 4 lines).

### 4.2 Modern Stone

```redcode
stone   add   inc, ptr           ; advance pointer
        mov.i bomb, @ptr         ; drop bomb
        jmp   stone              ; loop
inc     dat   #step, #step
ptr     dat   #0, #0
bomb    dat   >-1, >1            ; self-modifying bomb
```

The `dat >-1, >1` bomb is more destructive than plain `dat #0, #0` because when processes near the bomb execute, the postincrement/predecrement fields corrupt adjacent cells.

### 4.3 SPL Bomber (Armadillo Style)

```redcode
stone   spl   #0, <-step         ; self-split + decrement
        mov   bomb, step         ; drop bomb
        add   #step, stone       ; advance pointer
        djn   stone, <-step      ; loop + decrement
bomb    dat   >-1, >1
```

"SPL bombs are the most effective single-instruction bomb a warrior can drop." -- The self-splitting bomber maintains processes even under stun attack, and the SPL instruction itself acts as a stun bomb on the opponent.

### 4.4 Cannonade Stone

A self-splitting bomber with core-clear transition:

```redcode
stone   spl   #0, <gate          ; self-split
        mov   bomb, @ptr         ; bomb
        add.f inc, ptr           ; advance
        djn.f stone, <gate       ; loop
        ; transition to core-clear after N bombs
```

Features mod-5 bombing with DJN-stream layering. Eventually converts to core-clear with integrated imp-gate.

### 4.5 Boot-Copy Stone

Modern stones separate executable code from boot location:

```redcode
boot    mov   {boot, <bptr       ; copy stone code to remote location
        mov   {boot, <bptr
        mov   {boot, <bptr
bptr    jmp   @target, #offset
```

This leaves the original code as a decoy. The scanner finds inert boot code while the real stone operates elsewhere. "Keystone" stone detects paper opponents and branches to specialized defense code.

### 4.6 Optimal Stone Parameters for 8000 Core

**Step sizes (optima numbers for 8000 core):**

| Mod | Best Steps | Under-100 Coverage |
|-----|-----------|-------------------|
| mod-1 | 3359, 3039 | 73 |
| mod-2 | 3094, 2234 | 98 |
| mod-4 | 3364, 3044 | 76 |
| mod-5 | 3315, 2365 | 95 |
| mod-8 | 2936, 2376 | -- |
| mod-10 | 2930, 2430 | -- |

The "mod" refers to the modular pattern of bombing: mod-4 means every 4th cell gets a bomb. Choose mod based on warrior size (avoid self-bombing).

**Step selection strategy:** "Go for the biggest programs first and then fill in the gaps." Target programs of size 10-15 instructions (the average warrior) with initial step, then rely on secondary bomb patterns to cover smaller targets.

---

## 5. Imp Strategies

### 5.1 Basic Imp

```redcode
imp     mov.i #0, 2667           ; copy self forward by step
```

The imp copies itself one step ahead each cycle, marching through the core. It cannot be killed easily (it only occupies one cell) but it cannot win (it doesn't damage anything that isn't in its path).

### 5.2 Imp Rings

Multiple imp processes at regular spacing form a cooperative ring:

```redcode
; 3-point imp ring (step = 2667 for 8000 core)
        spl   1                  ; fork
        spl   1                  ; fork again (now 4 processes)
        jmp   @vector            ; jump to imp via vector table
vector  jmp   imp, imp+2667
imp     mov.i #0, 2667           ; the imp instruction
```

**Mathematics:** For an N-point ring with step S in coresize C: N * S must equal 1 (mod C). For 3-point ring: 3 * S = 1 (mod 8000), so S = 2667 (since 3*2667 = 8001 = 1 mod 8000).

**Existence rule:** "In a core of size C, there is an imp step for N if and only if N and C have no common factor." Since 8000 = 2^6 * 5^3, valid imp numbers are those not divisible by 2 or 5 (i.e., ending in 1, 3, 7, or 9).

**Common imp configurations for 8000:**
- 3-point ring: step = 2667
- 7-point ring: step = 1143 (7*1143 = 8001)
- 9-point ring: step = 889 (9*889 = 8001)
- 11-point ring: step = 727 (11*727 = 7997... need modular inverse)

### 5.3 Imp Spirals

An imp spiral uses multiple processes per imp point, creating redundancy:

```redcode
; 8-process spiral at step 2667
        spl   1                  ; 2 processes
        spl   1                  ; 4 processes
        spl   1                  ; 8 processes
        mov.i #0, 2667           ; all become imps
```

The 8 processes are evenly distributed in the process queue. Speed = 1/8 per process, but total imp coverage = 1 location per cycle. Resilience: enemies need 8+ concurrent attacks to stop all processes.

### 5.4 Gate-Crashing Spirals

Standard imp gates (DJN or DAT at fixed locations) stop normal imps. Gate-crashing uses interleaved spirals with slightly different step sizes:

```redcode
; Three interleaved spirals: step 2667 and step 2668
; Standard spiral uses 2667
; Modified spirals use 2668
; When gate decrements one spiral, the other passes through
```

"When encountering imp gates, the modified spirals absorb defensive decrements while the standard spiral penetrates through."

### 5.5 Mirrored Imps

Two imp copies placed CORESIZE/2 apart:

```redcode
imp_sz  equ   4001               ; step = 4001 (not a standard imp number)

start   mov   imp, imp+4000      ; mirror the imp
        spl   1
        spl   1
        jmp   @vector, {0
vector  jmp   imp+4000, imp
imp     mov.i #0, imp_sz
```

**Advantage:** The step 4001 is not a standard imp number, so spiral clears targeting standard steps miss the mirrored imp. Two-point imps require multiple complete core passes to eliminate.

### 5.6 Imp Gates (Defense)

An imp gate continuously bombs or decrements a location to prevent imps from passing:

```redcode
gate    jmn   gate, gate-2667    ; check if imp is approaching
        dat   0, <gate-2667      ; decrement to corrupt imp
```

Or the simpler form:
```redcode
gate    dat   0, <-2667          ; continuously decrement the location 2667 behind
```

When an imp copies itself onto a gate's target, the gate's decrement corrupts the imp instruction before it can execute, killing that imp process.

**Effectiveness:** Standard gates work against basic imp rings. Gate-crashing spirals (with mixed step sizes) defeat simple gates. D-clear is "equally good against all imp species."

### 5.7 Imp Launch Mechanisms

**Binary Launch** (fastest, most code): 2N-1 instructions for N processes.
```redcode
        spl   8
        spl   4
        spl   2
        jmp   imp+(0*step)
        jmp   imp+(1*step)
        spl   2
        jmp   imp+(2*step)
        jmp   imp+(3*step)
        ; ... etc
imp     mov.i #0, step
```

**JMP/ADD Launch** (smallest, slowest): log2(N)+3 instructions for N processes.
```redcode
imp     mov.i #0, step
        spl   1
        spl   1
        spl   1
        spl   2
        jmp   imp
        add.a #step, -1          ; modify jump target for next process
```

**Vector Launch** (fast + compact): Uses a data table of jump targets.
```redcode
table   dat   0, imp+(7*step)
        dat   0, imp+(6*step)
        ; ...
send    djn.a @table, #imp
imp     mov.i #0, step
```

**Hybrid Launch** (best of both): Interweaves two vector tables, achieving binary speed with vector compactness.

---

## 6. Quickscanning (Qscan)

Quickscanning is a rapid preamble that probes specific core locations before the main strategy begins. The goal: detect the opponent early and bomb them before they finish booting.

### 6.1 Standard Qscan

Uses unrolled SNE/SEQ pairs to check multiple locations in minimal cycles:

```redcode
; Q^2 scan: checks pairs of locations
        sne   qst+step*4, qst+step*4+gap
        seq   qst+step*4+gap*2, qst+step*4+gap*3
        mov.ab #offset, found     ; encode which pair matched
        sne   qst+step*8, qst+step*8+gap
        seq   qst+step*8+gap*2, qst+step*8+gap*3
        mov.ab #offset2, found
        ; ... repeat for more pairs
        jmn.b attack, found       ; if anything found, attack
found   dat   0, 0
```

**Speed:** Checks ~50 locations in ~25 instructions. "Probe's Q^2 scan checks 50 core locations in 25 instructions, jumping immediately to the calc/bomb routine when something is found."

**Detection rate:** Against two Q^2 scanners: "approximately 45% wins to each for a 90% find rate between the two of them."

### 6.2 Q^2 (Anders Ivner)

Uses JMP instruction modifier encoding to identify which scan pair triggered:

```redcode
        sne   loc1, loc1+gap
        seq   loc2, loc2+gap
        jmp   attack, attack       ; standard jump (encodes position 0)
        sne   loc3, loc3+gap
        seq   loc4, loc4+gap
        jmp   attack, {attack      ; { modifier (encodes position 1)
        ; ... different modifiers encode different positions
```

The six addressing modes ({, }, <, >, *, @) encode up to 6 different detection positions. A lookup table then decodes the modifier to determine the exact target:

```redcode
tab     dat   1*QS, 4*QS+QBASE-found
        dat   0*QS, 0*QS+QBASE-found
        dat   2*QS, 3*QS+QBASE-found

attack  add.ab tab, tab
found   mov.b  @attack, #0
```

**Key advantage:** "An average five cycles earlier response than standard implementations."

### 6.3 Q^3 and Q^4

Extensions that scan more locations:
- **Q^3:** Three-stage scanning with more probe pairs. Used in competitive papers like nPaper II.
- **Q^4:** Four-stage scanning. "The minimal distance between two scanned locations would be greater than 99" for optimal performance.
- **Q^4.5:** Jens Gutzeit's optimization. Mathematical requirement: qM * (qm - 1) = 1 mod 8000. "Optimal scanned location spacing cannot exceed 95 positions due to internal warrior constraints."

### 6.4 Qscan Bombing Engines

Once a target is detected, the bombing engine must efficiently destroy it:

**Forward Bombing:**
```redcode
qbomb   dat   1, -CONSTANT
loop    mov.i qbomb, @1
        mov.i qbomb, @target
        add.ab #x, -1
        djn.b loop, #10
```

**Bidirectional Bombing:**
```redcode
qbomb   dat   -step, step
found   dat   x, x+step
loop    mov   qbomb, @found
        mov   qbomb, *found
        add.f qbomb, found
        djn.b loop, #10
```

**Asymmetrical Tornado:** "Bombs down in core at 0.4c and up at 0.2c," prioritizing downward targeting.

### 6.5 Counter-Quickscan Strategies

**Decoy Maker:** Creates decoys at 3c speed "to slow down scanners and quick scans."

**Boot-copy:** Relocate warrior before qscan can hit. "Booting warriors are likely to escape the bombs, as are most pspacers."

**RetroQ:** Mirrors the standard Q^2 scan pattern backward, so both warriors detect each other simultaneously, then splits attack into two routines at locations that the opponent's bombing won't reach both.

### 6.6 Optimal Qscan for 8000 Core

- **Scan locations:** Space at least 100 apart (MINDISTANCE) to avoid self-detection
- **Number of probes:** 16-50 locations in 8-25 instructions is standard
- **Attack response:** Must begin within 4-6 cycles of detection
- **Code size tradeoff:** 25-70 instructions for qscan leaves 30-75 for the main warrior

---

## 7. P-Space Switching

P-space provides 500 cells of persistent memory between rounds. P[0] stores previous round result (0=loss, 1+=survivors). Not available on 94nop hills (no p-space), but critical on 94draft hills.

### 7.1 Basic Switcher

```redcode
        ldp.ab #0, result         ; load previous result
result  jmz   strat_a             ; if lost (0), try strategy A
        jmp   strat_b             ; otherwise try strategy B
```

### 7.2 P^2 Switcher (Table-Based)

Uses discrete finite acceptors (DFAs) with lookup tables:

```redcode
        ldp.a  #0, in             ; load fight result
        ldp.a  #PSTATE, table     ; load current state
        ; table lookup determines next state and warrior
        stp.a  *table, #PSTATE    ; store new state
        jmp    @table             ; execute chosen warrior
```

"A fast table-based switcher which can manage any conceivable strategy or combination of strategies using 6 cycles." States encode which warrior to run based on win/loss/tie history.

### 7.3 P^3 Switcher (Modular Arithmetic)

Encodes state transitions using coprime integers (r, s, t):

```redcode
        ldp.a  #0, in             ; load result
        ldp.a  #PSTATE, table     ; load state
        mod.ba *in, table         ; decode via modular arithmetic
        stp.b  *table, #PSTATE    ; store new state
```

For n states: r = n+1 (or n+2), s = r-1, t = r+1. Maximum 19 states in 8000 core (19*20*21 = 7980).

**Brainwash protection:** Opponents can write to your p-space via `stp` instructions. Modular arithmetic encoding provides natural corruption resistance -- corrupted values map to valid (if wrong) states rather than crashing.

### 7.4 Handshake Detection

Two copies of the same warrior detect self-play:

```redcode
        stp.ab #MAGIC, #SIGNAL    ; write magic number
        ldp.ab #SIGNAL, check     ; read it back
check   sne   #MAGIC, #0          ; did we write it? (only if opponent is same warrior)
        jmp   passive_strategy    ; yes -> play for tie (imp ring)
```

This inflates scores in tournament formats by guaranteeing ties against yourself.

### 7.5 94nop Note

On the standard 94nop hill, p-space is typically not available. Warriors must select strategy at compile time or use quickscanning to adapt. P-space switching is critical on 94draft and other p-space-enabled hills.

---

## 8. Vampire Strategies

Vampires bomb the core with JMP instructions ("fangs") that redirect opponent processes into a trap ("pit"):

### 8.1 Basic Vampire

```redcode
fang    jmp   trap, 4             ; the fang -- redirects to pit

inc     dat   #step, #-step
        add.f inc, fang           ; advance fang pointer
        mov.i fang, @fang         ; drop fang at target
        jmp   -2                  ; loop

trap    mov   10, <-10            ; pit: core-clear
        spl   -1                  ; amplify processes
        jmp   -2                  ; loop destruction
```

### 8.2 How Vampires Work

1. Drop JMP instructions across the core (like a stone drops DATs)
2. Enemy processes that execute the JMP are redirected to the pit
3. The pit uses the captured processes to accelerate core-clearing
4. Enemy's own processes become weapons against it

### 8.3 Advanced Vampire (myVamp)

```redcode
step    equ   3024
c       jmp   *trap, 0            ; fang with indirect targeting
s       dat.f -step, step         ; step increment

st      add.f s, c                ; advance
        mov.i c, @c               ; drop fang
        jmz.a st, *c              ; scan: if target empty, continue bombing
        mov.i @0, *c              ; if target non-empty, overwrite with pit redirect
        mov.x *c, *c              ; cross-copy fields
```

"The vamp bomb is the best bomb, unless it fights a special opponent with anti-vamp. Most programs on the hill can't afford anti-vamp."

### 8.4 Vampire Pit Design

```redcode
trap    spl   #0, <trap
        spl   5, 0
        spl   #0, 0
        ; ... multiple SPL to generate process flood
        jmp   -4, 0               ; loop pit
```

Modern pits use "permanent spl-clear" for extra stun power against silk-style papers.

### 8.5 Anti-Vampire Defense

- **A-indirect bombing:** Papers use `}` (A-postincrement) mode for bombs. This corrupts the A-field of any JMP fang it hits, redirecting vamped processes to random locations instead of the pit.
- **Stealth:** Warriors with all-zero fields are invisible to vampire scanning.
- **Process speed:** Fast-executing warriors (tight 3-4 instruction loops) rarely land on fang locations.

### 8.6 Vampire Limitations

"Vampires only work against wandering/corrupted PCs." Tight-loop warriors (scanners, papers, stones) have predictable PC sequences that rarely land on remote fang locations. Vampires are strongest against large, loosely-structured warriors.

---

## 9. Boot-Copy Techniques

### 9.1 Basic Boot

```redcode
boot    mov   {boot, <target     ; copy warrior code to target location
        mov   {boot, <target
        mov   {boot, <target
        ; ... one MOV per instruction to copy
target  jmp   @dest, offset      ; jump to copied code
```

### 9.2 Why Boot

1. **Stealth:** Scanner finds inert boot code (decoy), not running warrior
2. **Decoy:** Original location serves as scanner bait
3. **Separation:** Running code is far from boot remnants
4. **Size flexibility:** Boot code is disposable after execution

### 9.3 Boot Distance

Typical: 200-2000 cells from original position. Must be far enough that a clear attacking the boot code doesn't reach the running warrior, but not so far that the boot takes too many cycles.

### 9.4 Multi-Boot

Copy multiple components to different locations:
```redcode
; Boot stone code to location A
; Boot clear code to location B
; Boot imp code to location C
; Jump to stone, which transitions to clear, which launches imp
```

This distributes the warrior across the core, making it harder to kill with a single clear.

### 9.5 Boot Speed

Each MOV instruction copies one instruction per cycle. A 20-instruction warrior needs 20 cycles to boot. This is 20 cycles not spent attacking. Modern warriors minimize boot code by using `{` (predecrement) and `<` (predecrement) addressing to compact the copy loop:

```redcode
boot    mov   {boot, <ptr        ; copies backward through code
        ; predecrement automatically advances source pointer
```

---

## 10. Hybrid Architectures

### 10.1 Stone/Imp

The most common hybrid. A stone bomber launches an imp ring as endgame insurance:

```redcode
; Phase 1: Boot and bomb
stone   add   inc, ptr
        mov.i bomb, @ptr
        djn   stone, count
; Phase 2: Launch imp ring
        spl   1
        spl   1
        mov.i #0, 2667
```

The stone attacks first (fast, aggressive). If it hasn't won by the time its bombing cycle completes, it launches an imp ring for tie insurance. This is the dominant stone architecture -- 18 of 50 Hall of Fame entries on the 94nop hill were stone/imp warriors.

### 10.2 Paper/Imp

Paper replication with imp backup:

```redcode
silk    spl   step, #0
        mov.i >-1, }-1
        mov.i >-1, }-1
        add.a #step, silk
        jmp   silk, {silk
; Imp processes launched alongside paper copies
```

The paper scores ties against other papers while the imp ring provides additional tie insurance against clears.

### 10.3 Scanner/Clear

The oneshot scanner that transitions to a clear:

```redcode
scan    add   inc, ptr
ptr     sne   first+gap, first
        djn.f scan, *ptr
        ; detection -> clear
        mov.i bomb, >gate
        djn.f -1, >gate
```

Dominant architecture on the 94nop hill. 13 of 50 HoF entries were scanners.

### 10.4 Paper/Stone

Runs paper replication while simultaneously bombing:

```redcode
silk    spl   step, #0
        mov.i >-1, }-1
        mov.i bomb, >target       ; bomb while replicating
        add.a #step, silk
        jmp   silk, {silk
```

### 10.5 Clear/Imp

Pure core-clear with imp ring endgame:

```redcode
; SPL tree -> 32 processes
        spl   1
        spl   1
        spl   1
        spl   1
        spl   1
; Half processes run clear
        spl   clear
; Other half run imp
        mov.i #0, 2667
clear   mov   bomb, >gate
        djn.f clear, >gate
```

### 10.6 Qscan -> Warrior

Quickscan preamble routes to different warriors based on detection:

```redcode
; Qscan (25 instructions)
        sne   loc1, loc1+gap
        seq   loc2, loc2+gap
        jmp   found
        ; ... more probe pairs
        jmp   default_warrior     ; no detection -> default strategy
found   jmp   counter_warrior     ; detection -> counter strategy
```

nPaper II (which held #1 on 94nop) combined Q^3 scan with silk paper: "The culmination integrated a simplified Q^3 scan, peaking at 33 scan points across 3 table entries."

### 10.7 HoF Strategy Distribution (94nop)

From CoreWarrior #89 analysis of the top 50:
- 18 Stone/imp warriors (36%)
- 13 Scanners (26%)
- 6 Paper/imp (12%)
- 4 Bombers (8%)
- 3 Oneshots (6%)
- 3 Papers (6%)
- 3 Paper/stones (6%)

Stone/imp and scanner architectures together account for 62% of the Hall of Fame.

---

## 11. Common Step Sizes for 8000 Core

### 11.1 Theory

A step size S for bombing or scanning must satisfy:
- GCD(S, 8000) = 1 for full core coverage (hits every cell eventually)
- S should not divide 8000 evenly (would create blind spots)
- S must avoid the warrior's own code (mod-N consideration)

Since 8000 = 2^6 * 5^3, any step not divisible by 2 or 5 is coprime to 8000.

### 11.2 Optima Numbers Table

From Steven Morrell's analysis. The "optima number" minimizes the maximum gap between bombed locations after N bombs:

**For targeting warriors of size ~10-15 (average competitive warrior):**

| Step | Mod | Coverage Quality | Notes |
|------|-----|-----------------|-------|
| 3044 | 4 | Excellent | Classic competitive step |
| 3039 | 1 | Excellent | Near-optimal for mod-1 |
| 3359 | 1 | Excellent | Best mod-1 optima |
| 3364 | 4 | Excellent | Best mod-4 optima |
| 3094 | 2 | Excellent | Best mod-2 optima |
| 3315 | 5 | Very good | Best mod-5 optima |
| 2667 | 1 | Good | Classic imp step (8000/3+1) |
| 2389 | 1 | Good | Common competitive step |
| 5039 | 1 | Good | Large step, fast initial coverage |
| 2936 | 8 | Good | Best mod-8 optima |

### 11.3 Imp Steps for 8000 Core

For N-point imp rings: N * S = 1 (mod 8000)

| Points | Step | Verification |
|--------|------|-------------|
| 3 | 2667 | 3*2667 = 8001 = 1 mod 8000 |
| 7 | 1143 | 7*1143 = 8001 = 1 mod 8000 |
| 9 | 889 | 9*889 = 8001 = 1 mod 8000 |
| 11 | 727 | 11*727 = 7997; need exact inverse |
| 13 | 615 | 13*615 = 7995; need exact inverse |

Note: For exact computation, use Euclid's extended algorithm: find S such that N*S mod 8000 = 1.

### 11.4 Scanner Step Selection

**Principles:**
- Larger steps (5000+) spread initial probes wider = faster first detection of large warriors
- Smaller steps (2500-3500) create denser local coverage = better at finding small warriors
- The optimal step depends on the expected opponent size distribution
- Steps near CORESIZE/3 (~2667) or CORESIZE/phi (~4944) are mathematically interesting but not necessarily optimal

### 11.5 Silver Bullet Multi-Step

A technique using ascending/descending step sequences that switch every few thousand cycles:

```redcode
; Step sequence: 5266, 4954, 4154, 3174, ...
; Each step bombs for ~12000 cycles (4000 bombs at 0.33c)
; Six steps = 72000 cycles (within 80000 MAXCYCLES)
```

"Remarkably effective against CMP-scanners and also against larger self-splitting bombers because they have an improved ability to destroy SPL 0 instructions."

---

## 12. The Competitive Meta-Game

### 12.1 The RPS Triangle

Core War follows a rock-paper-scissors dynamic:
- **Paper beats Stone:** Too many copies to bomb
- **Stone beats Scanner (Scissors):** Too fast and small to find before bombing kills
- **Scanner beats Paper:** Systematic detection and clearing destroys all copies

No single warrior beats all three types. The meta-game is about:
1. Building hybrids that handle multiple matchups
2. Using qscan/p-space to route to the right counter-strategy
3. Accepting some bad matchups while maximizing good ones

### 12.2 Hill Ecology

The competitive hill has an ecological dynamic:
- When many scanners are on the hill, papers thrive (scanners beat stones, fewer stones to threaten papers)
- When papers dominate, scanners rise (scanners beat papers)
- When scanners dominate, stones return (stones beat scanners)
- The cycle repeats

"Of course, any time you have several programs doing the same thing on the Hill, a niche is created which is also an opportunity."

### 12.3 Dominant Architectures

**Stone/Imp** (most HoF entries): Small, fast, aggressive bombing with imp ring insurance. The imp ring makes pure losses rare (converts potential losses to ties). Weak against papers.

**Scanner/Clear** (oneshot): Find opponent, clear them. Strong against papers. Weak against tiny, fast stones that bomb before detection.

**Paper with bombing** (silk+bombs): Self-replicating with DAT trail. Beats stones, ties papers, loses to scanners.

**Qscan hybrids** (Q^2/Q^3 -> warrior): Quickscan preamble routes to different strategies. Most flexible but complex to optimize.

### 12.4 Decoy Strategy

**Decoys** are non-functional instructions placed to confuse enemy scanners:

```redcode
; Scatter DATs with non-zero fields
        dat   #1, #1
        dat   $1, $1
        dat   @1, @1
```

Scanners waste cycles attacking decoys. With MAXLENGTH=100, a warrior can deploy 50-80 decoys and still have 20-50 instructions for the actual warrior.

**Decoy makers** rapidly construct decoys at runtime:
```redcode
        mov   decoy, >ptr
        add   #offset, ptr
        djn   -2, count
```

Speed: 3c (one decoy every 3 cycles). Can place ~100 decoys in ~300 cycles.

**Counter:** CMP scanners that compare two locations are harder to fool with decoys (both locations must match the decoy pattern). F-scanners that check full instructions are even harder to fool.

### 12.5 Stealth Techniques

**Mirror:** Place a copy of the warrior CORESIZE/2 away. On-axis CMP scanners compare locations 4000 apart. If both locations contain identical code, the scanner sees no difference and skips them.

```redcode
; Place mirror copy 4000 cells from real code
boot    mov   {boot, <mirror_ptr
        ; ... copy all instructions to position + 4000
```

**Zero fields:** Keep all B-fields at zero. B-scanners (which check `jmn/djn` on B-fields) cannot detect zero-B instructions.

**Small footprint:** The ultimate stealth is being tiny. A 4-instruction warrior occupies 0.05% of 8000 cells. Even systematic scanners take thousands of cycles to find it.

### 12.6 Process Management

**Process dilution:** Each SPL halves effective speed. 32 processes = each runs at 1/32 speed. This is fine when all processes do the same work (clear = 32x area coverage). It's devastating when processes compete for different strategies (half scan, half bomb = both at half speed = worse than either alone).

**Process advantage:** When your warrior has more active processes than the opponent, you execute more instructions per cycle. SPL carpet bombing creates this advantage by flooding the enemy with useless processes while your processes remain productive.

### 12.7 Endgame Theory

Most fights in 8000 core end in one of three ways:
1. **Kill:** One warrior's processes all execute DATs. Clear victory.
2. **Imp tie:** Surviving imp processes prevent kill. Both warriors have imp processes marching through core.
3. **Timeout tie:** 80,000 cycles elapsed. Both warriors still alive. Typically happens when two papers face each other.

**Imp endgame insurance:** Launching imp rings after the main attack gives tie insurance. Without imps, a warrior that fails to kill the opponent dies to the opponent's clear. With imps, the worst case is a tie.

### 12.8 The Airbag Technique

A bombing loop designed to survive DAT bomb hits:

```redcode
; Multiple processes execute the same bombing loop
; If one process is killed by a DAT bomb, others detect the corruption
; Detection triggers transition to clear phase
```

"Use a bombing loop that won't die if it is dat bombed, but also without self-splitting." The key: N parallel processes execute identically. A DAT bomb kills one process, but the remaining N-1 detect the missing modification and escape to a clear phase.

Used by Behemot (with 7 parallel processes at 0.6c bombing speed) and Return of the Fugitive.

### 12.9 DJN Streams

A continuous decrement loop that traps and kills enemy processes:

```redcode
stream  djn   stream, target     ; decrement target, loop forever
```

When an enemy process enters the DJN stream's range, it gets caught: the DJN decrements the enemy's instruction fields, eventually corrupting them to DATs or invalid instructions. DJN streams are used in clear routines as a secondary kill mechanism.

### 12.10 Competitive Development Process

From CoreWarrior newsletters, the development cycle for competitive warriors:

1. **Choose architecture:** Stone/imp, scanner/clear, paper, or hybrid
2. **Implement basic version:** Get the mechanism working correctly
3. **Optimize constants:** Use tools like Corestep for step sizes, benchmark against known opponents
4. **Add qscan:** Prepend Q^2 or Q^3 scan if code budget allows
5. **Add endgame:** Imp ring, core-clear, or both
6. **Benchmark:** Test against representative suite (scanners, papers, stones)
7. **Iterate:** Adjust constants, try alternative bombs, modify clear parameters
8. **Submit to hill:** Real competition reveals weaknesses benchmarks miss

---

## Appendix A: Key Warriors and Their Architectures

| Warrior | Author | Architecture | Notable Feature |
|---------|--------|-------------|-----------------|
| Son of Vain | Oversby/Pihlaja | Hybrid | Held #1, age 2573 (record) |
| nPaper II | Khuong/Metcalf | Paper+Q^3 | #1 on 94nop with 151 points |
| Devilstick | van Rijn | Unknown | 151.8 score |
| Blacken | Oversby | Stone+Qscan | First warrior to exceed age 1000 |
| Carbonite | Sutton | Stone | "All-time classic" with D-clear transition |
| Behemot | Janeczek | Stun bomber | Airbag technique pioneer |
| Winter Werewolf | Mintardjo | Stone | "First modern program to compete against imp-rings" |
| myVamp | Paulsson | Vampire | Modern vampire with scanning |
| Blur 2 | Marsden | Scanner | 0.5c scan, SPL carpet, DAT/DJN clear |
| RetroQ | Kline | Scanner | Reverse Q^2 scan with silk-imp fallback |

## Appendix B: ICWS-94 Instruction Reference

| Opcode | Action | Kill? |
|--------|--------|-------|
| DAT | Remove process from queue | Yes |
| MOV | Copy A to B | No |
| ADD | Add A to B | No |
| SUB | Subtract A from B | No |
| MUL | Multiply A by B | No |
| DIV | Divide B by A (kills on /0) | On div-by-zero |
| MOD | B modulo A (kills on %0) | On mod-by-zero |
| JMP | Jump to A | No |
| JMZ | Jump to A if B is zero | No |
| JMN | Jump to A if B non-zero | No |
| DJN | Decrement B, jump to A if non-zero | No |
| SEQ/CMP | Skip next if A equals B | No |
| SNE | Skip next if A not equal B | No |
| SLT | Skip next if A less than B | No |
| SPL | Fork: queue next + queue A | No |
| NOP | No operation | No |
| LDP | Load from P-space | No |
| STP | Store to P-space | No |

## Appendix C: Number Theory Quick Reference

**8000 = 2^6 x 5^3**

Numbers coprime to 8000 (valid steps): any number not divisible by 2 or 5.
- Coprime: 1, 3, 7, 9, 11, 13, 17, 19, 21, 23, 27, 29, 31, 33, ...
- NOT coprime: 2, 4, 5, 6, 8, 10, 12, 14, 15, 16, 18, 20, ...

**Euler's totient:** phi(8000) = 8000 * (1 - 1/2) * (1 - 1/5) = 3200 coprime values exist.

**Modular inverse:** For imp ring with N points, step S = N^(-1) mod 8000. Use extended Euclidean algorithm.

**Speed notation:**
- 1c = 1 location per cycle (speed of light)
- 0.5c = 1 location every 2 cycles
- 0.33c = 1 location every 3 cycles
- 0.66c = 2 locations every 3 cycles

## Appendix D: Sources

- corewar.co.uk/strategy.htm -- Core War Strategy Guide
- corewar.co.uk/karonen/guide.htm -- Beginner's Guide to Redcode v1.23 (Ilmari Karonen)
- corewar.co.uk/icws94.txt -- ICWS-94 Standard
- corewar.co.uk/imp.htm -- Imp strategies
- corewar.co.uk/paper.htm -- Paper/Replicator strategies
- corewar.co.uk/faq/glossary.htm -- Core War Glossary
- corewar.co.uk/morrell/chapter1.txt -- My First Corewar Book: Imp Rings (Steven Morrell)
- corewar.co.uk/morrell/chapter2.txt -- My First Corewar Book: Stones (Steven Morrell)
- corewar.co.uk/grabun/carbonite.htm -- Carbonite stone analysis
- corewar.co.uk/grabun/behemot.htm -- Behemot stun bomber analysis
- corewar.co.uk/cw/ -- CoreWarrior newsletters (issues 1-92)
- corewars.org/docs/guide.html -- Beginner's guide to Redcode
