;redcode-94nop
;name Pyre
;author autoresearch-corewar
;strategy Qscan → oneshot scanner OR Guenzel clear+imp fallback
;strategy Hybrid: adapts behavior based on what qscan detects
;assert CORESIZE==25200

        qstep equ 9001
        qgap  equ 7
        ispacing equ 2291
        org qs1

; --- Qscan: 6 probes to detect large opponents ---
qs1     sne    qstep*3,  qstep*3+qgap
        seq    qstep*7,  qstep*7+qgap
        jmp    qhit
qs2     sne    qstep*11, qstep*11+qgap
        seq    qstep*17, qstep*17+qgap
        jmp    qhit
qs3     sne    qstep*23, qstep*23+qgap
        seq    qstep*29, qstep*29+qgap
        jmp    do_clear

; --- Scanner mode: incremental scan with clear-on-hit ---
qhit    jmp    scan
        gate   equ clear_s-4
        step   equ 4201
        gap    equ 9
        first  equ bptr-1+step

bptr    dat    #1,       #11
dptr    spl    #12600,   9
clear_s mov    *bptr,    >gate
        mov    *bptr,    >gate
        mov    *bptr,    >gate
        djn.f  clear_s,  }dptr

        for    5
        dat    0,0
        rof

scan    add    inc,      scanptr
scanptr sne    first+gap,}first
        djn.f  scan,     *scanptr
        mov    scanptr,  gate
        jmp    clear_s-1, <gate

        for    5
        dat    0,0
        rof

inc     dat    step,     step

; --- Clear/Imp fallback: carpet bomb + imp ring ---
ptr     dat    0, 300
clrbomb dat    <2667, 25
        for    15
        dat    0, 0
        rof

clear_g spl    #0,     >ptr
loop    mov    clrbomb, >ptr
        djn.f  loop,   >ptr

        for    26
        dat    0, 0
        rof

lstep   dat    ispacing, -10
do_clear:
        spl    1
        spl    1
        spl    1
        spl    1
        spl    1
        spl    2
        djn.f  imp, <-500
        add    lstep, -1
        djn.f  clear_g, <-1300
imp     mov.i  #1, ispacing
        end    qs1
