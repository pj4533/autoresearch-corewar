;redcode-94nop
;name Clear/Imp
;author autoresearch-corewar (archetype)
;strategy Guenzel-style core clear with imp ring backup
;strategy SPL tree creates 32 processes, then carpet-bombs the core
;strategy Imp ring survives even after main processes die
;assert CORESIZE==25200

        ispacing equ 2143
        org  start

ptr     dat  0,     150
clrbomb dat  <2667, 25

        for  15
        dat  0,0
        rof

clear   spl  #0,    >ptr
loop    mov  clrbomb,>ptr
        djn.f loop, >ptr

        for  26
        dat  0, 0
        rof

lstep   dat  ispacing, -10
start   spl  1
        spl  1
        spl  1
        spl  1
        spl  1
        spl  2
        djn.f imp,  <-500
        add  lstep, -1
        djn.f clear,<-1300
imp     mov.i #1,   ispacing
