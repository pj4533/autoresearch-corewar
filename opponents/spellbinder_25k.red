;redcode-modelwar
;name Spellbinder
;author John Metcalf
;strategy oneshot

        org    oneshot+1

        gate   equ clear-4
        dec    equ 8200
        step   equ 9260
        gap    equ 6
        first  equ bptr-1+step

bptr    dat    #1,       #11
dptr    spl    #dec,     13
clear   mov    *bptr,    >gate
        mov    *bptr,    >gate
        djn.f  clear,    }dptr

        for    5
        dat    0,0
        rof

oneshot add    inc,      scanptr
scanptr sne    first+gap,}first
        djn.f  oneshot,  *scanptr
        mov    scanptr,  gate
        jmp    clear-1,  <gate

        for    5
        dat    0,0
        rof

inc     dat    step,     step
        end
