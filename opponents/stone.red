;redcode-94nop
;name Stone
;author autoresearch-corewar (archetype)
;strategy Classic stone — throws DAT bombs across the core
;strategy Uses two processes: one bombing forward, one bombing backward
;strategy Simple but effective against scanners that don't clear fast enough
;assert CORESIZE==25200

        step equ 3463
        org  start

start   spl  bomb2
bomb1   mov  dat1,  @ptr1
        add  inc1,  ptr1
        jmp  bomb1

bomb2   mov  dat1,  @ptr2
        add  inc2,  ptr2
        jmp  bomb2

ptr1    dat  0,     step
ptr2    dat  0,     -step
inc1    dat  0,     step
inc2    dat  0,     -step
dat1    dat  <2667, <2667
