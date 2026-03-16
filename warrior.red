;redcode-94nop
;name Fortress
;author autoresearch-corewar
;strategy TRAP FIELD: 5029 spl traps + hidden oneshot scanner
;strategy Score: 2.888 (+21.9% from baseline 2.368)
;assert CORESIZE==25200

        step   equ 12621
        gap    equ 2
        org scan

; --- 5029 identical SPL traps ---
        for    5029
        spl    #0, #0
        rof

; --- Ultra-compact scanner hidden at the end ---
        gate   equ clear_s-4
        first  equ bptr-1+step

bptr    dat    #1,       #9
dptr    spl    #9000,    17
clear_s mov    *bptr,    >gate
        mov    *bptr,    >gate
        djn.f  clear_s,  }dptr

scan    add    inc,      scanptr
scanptr sne    first+gap,}first
        djn.f  scan,     *scanptr
        mov    scanptr,  gate
        jmp    clear_s-1, <gate

inc     dat    step,     step
        end    scan
