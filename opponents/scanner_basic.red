;redcode-94nop
;name Basic Scanner
;author autoresearch-corewar (archetype)
;strategy Simple oneshot scanner — scans core looking for non-zero cells
;strategy Uses step=4201 (prime, coprime to 25200 = full coverage)
;strategy When found: bombs target with SPL/DAT combination
;assert CORESIZE==25200

        step equ 4201
        org  scan

scan    add  inc,   ptr
ptr     jmz  scan,  step
        mov  bomb,  @ptr
        mov  bomb2, <ptr
        djn  scan,  #20

inc     dat  step,  step
bomb    spl  #0,    #0
bomb2   dat  <2667, <2667
