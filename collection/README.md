# CoreWar Warrior Collection

2,500+ warriors for testing and research. Mix of 94nop, P-space (94 with LDP/STP), and classic formats.

## Sources

| Directory | Count | Source | Notes |
|-----------|-------|--------|-------|
| `n1ls/` | 567 | [n1LS/redcode-warriors](https://github.com/n1LS/redcode-warriors) | Mixed hill warriors |
| `koenigstuhl/94nop/HILL32/` | 1157 | [Koenigstuhl](https://asdflkj.net/COREWAR/) | Full 94nop infinite hill |
| `koenigstuhl/94nop_top50/HILL32/` | 63 | Koenigstuhl | 94nop top 50 |
| `koenigstuhl/pspace_full/` | 206 | Koenigstuhl | Full P-space hill (ALL use LDP/STP) |
| `koenigstuhl/pspace_top50/HILL32/` | 53 | Koenigstuhl | P-space top 50 |
| `corewar_co_uk/` | 3 | [corewar.co.uk](https://corewar.co.uk) | Azathoth, Combatra, Tolypeutes |
| `drq_human/` | 317 | [SakanaAI/drq](https://github.com/SakanaAI/drq) | Human-authored baseline warriors |
| `drq_evolved/` | 270 | SakanaAI/drq | LLM-evolved warriors (GPT) |
| `samurai/` | 10 | [samurai/corewars-warriors](https://github.com/samurai/corewars-warriors) | Personal collection |
| `kd00r/` | 1 | [kd00r/corewar-redcode-warriors](https://github.com/kd00r/corewar-redcode-warriors) | Simple warriors |

## Key Warriors for Testing

### 94nop Top-Tier (in `koenigstuhl/94nop_top50/HILL32/`)
- **azathoth.red** — John Metcalf, paper/stone, #1 all-time on 94nop-Koenigstuhl
- **tolypeutes.red** — Roy van Rijn, stone/imp with 34-location qscan
- **nightstalker.red** — top scanner
- **armadillo.red** — classic stone/imp
- **hazylazya70.red** — Steve Gunnell, mod-scan (basis of Innovation's HF_C)
- **olivia.red** — top paper
- **sonnofvain.red** — classic paper/stone

### P-space Legends (in `koenigstuhl/pspace_full/` or `corewar_co_uk/`)
- **combatra.red** — David Moore, multi-round adaptive with boot distance computation
- **sunset.red** — #1 on P-space Koenigstuhl
- **cbd.red** — Cooperative Black Dimension
- **mantraparcade.red** — #3 P-space
- **selfmod011.red** — Self-Modifying Code v0.11
- **chameleon.red** — strategy switcher

## Format Notes

- ModelWar uses CORESIZE=8000, MAXLENGTH=3900, 100 rounds per battle
- Standard KOTH uses MAXLENGTH=100 — many warriors here are <=100 instructions
- P-space warriors use LDP/STP which requires `redcode-94` (not `94nop`)
- Test with: `node modelwar/test_arena.cjs warrior1.red warrior2.red`
