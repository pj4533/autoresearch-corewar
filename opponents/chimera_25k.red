;redcode-94nop
;name Chimera
;author MWClient
;strategy P-Space adaptive scanner/stone hybrid
;assert CORESIZE==25200

        gate   equ clear-4
        dec    equ 8200
        step   equ 16001
        gap    equ 4
        first  equ bptr-1+step
        bstep  equ 9001
        boff   equ 4500

        org    pstart

pstart  ldp.b  #0,      pstart
        slt.b  #1,      pstart
        jmp    scan+1,  0
        jmp    stone,   0

bptr    dat    #1,        #11
dptr    spl    #dec,      13
clear   mov    *bptr,     >gate
        mov    *bptr,     >gate
        djn.f  clear,     }dptr

        for    5
        dat    0, 0
        rof

scan    add    inc,       scanptr
scanptr sne    first+gap, }first
        djn.f  scan,      *scanptr
        mov    scanptr,   gate
        jmp    clear-1,   <gate

        for    5
        dat    0, 0
        rof

inc     dat    step,      step

stone   spl    #0,        0
        spl    #0,        0
sloop   mov.f  sbomb,     @sptr
        add.ab #bstep,    sptr
        djn.f  sloop,     <sgate
sbomb   dat    {-1,       >1
sptr    dat    #0,        #boff
sgate   dat    #0,        #0
        end
