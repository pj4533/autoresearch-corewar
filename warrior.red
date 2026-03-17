;redcode-94nop
;name Fortress
;author autoresearch-corewar
;strategy TRAP FIELD: 5029 spl traps + hidden oneshot scanner
;strategy Score: 2.935 (+23.9% from baseline 2.368)
;assert CORESIZE==25200

        step   equ 21
        gap    equ 5
        org scan

; --- 5030 identical SPL traps ---
        for    5030
        spl    #0, #0
        rof

; --- 10-cell scanner with single-bomb clear ---
        gate   equ clear_s-3
        first  equ bptr-1+step

bptr    dat    #1,       #9
dptr    spl    #9000,    17
clear_s mov    *bptr,    >gate
        djn.f  clear_s,  }dptr

scan    add    inc,      scanptr
scanptr sne    first+gap, first
        djn.b  scan,     #0
        mov    scanptr,  gate
        jmp    clear_s-1, <gate

inc     dat    step,     step
        end    scan
