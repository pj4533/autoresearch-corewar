;redcode-94nop
;name Imp Spiral
;author autoresearch-corewar (archetype)
;strategy 5-point imp ring — self-replicating MOV instructions
;strategy Nearly impossible to kill (survives most bombing patterns)
;strategy But can only tie against other imps, rarely wins outright
;assert CORESIZE==25200

        ispacing equ 5040
        org  launch

launch  spl  1
        spl  1
        spl  1
        spl  fork2
        jmp  imp

fork2   add  #ispacing, imp
        jmp  imp

imp     mov.i #1, ispacing
