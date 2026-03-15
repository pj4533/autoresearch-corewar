;redcode-94nop
;name Silk Paper
;author autoresearch-corewar (archetype)
;strategy Self-replicating paper — copies itself forward through core
;strategy Silk variant: uses SPL @0 for faster spreading
;strategy Difficult to kill because new copies keep spawning
;assert CORESIZE==25200

        dest equ 1400
        org  silk

silk    spl  @0,    >dest
        mov  }-1,   >-1
        mov  bomb,  >pos1
        djn  silk,  #0

pos1    dat  0,     930
bomb    dat  <2667, <5334
