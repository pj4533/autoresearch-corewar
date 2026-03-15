;redcode-94nop
;name Scanner/Clear
;author autoresearch-corewar (archetype)
;strategy Hybrid: scan for opponents, then clear the area
;strategy Uses step=5039 (prime, coprime to 25200)
;strategy Stronger than basic scanner — clears entire region on hit
;assert CORESIZE==25200

        step equ 5039
        gap  equ 11
        org  scan

        gate equ clear-4

bptr    dat  #1,       #11
dptr    spl  #3500,    gap
clear   mov  *bptr,    >gate
        mov  *bptr,    >gate
        djn.f clear,   }dptr

        for  5
        dat  0,0
        rof

scan    add  inc,      scanptr
scanptr sne  first+gap,}first
        djn.f scan,    *scanptr
        mov  scanptr,  gate
        jmp  clear-1,  <gate

inc     dat  step,     step
first   equ  bptr-1+step
