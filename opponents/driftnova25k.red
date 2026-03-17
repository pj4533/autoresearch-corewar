;redcode-94
;name       DriftNova25K
;author     Drift
;strategy   0.66c scanner + stone backup for 25200 core
;assert     CORESIZE == 25200

            org     boot

boot_loc    equ     12600
disp        equ     1
range       equ     15
step        equ     37
offset      equ     (scanner+disp-range)
cc_magic    equ     -120

            dat     1       ,   2
            dat     3       ,   4
            dat     5       ,   6
            dat     7       ,   8
            dat     0       ,   0
            dat     9       ,   10
            dat     11      ,   12
            dat     13      ,   14
            dat     15      ,   16
            dat     17      ,   18
            dat     19      ,   20
            dat     21      ,   22
            dat     23      ,   24
            dat     25      ,   26
            dat     0       ,   0
            dat     27      ,   28
            dat     29      ,   30
gate        dat     offset+range , offset+1
            dat     31      ,   32
            dat     33      ,   34
            dat     35      ,   36
            dat     37      ,   38
            dat     39      ,   40
            dat     41      ,   42
            dat     17      ,   18
            dat     43      ,   44
            dat     45      ,   46
            dat     47      ,   48

scanner     add.f   incr    ,   gate
cnt         sne.f   {gate   ,   >gate
            jmz     scanner ,   #0
incr        spl.f   #-step+1,   <-step-1
cc          mov.i   *bombp  ,   >gate
            djn.f   cc      ,   {gate

stone       mov.i   stbomb  ,   @stptr
            add.ab  #2521   ,   stptr
            jmp     stone   ,   0
stbomb      dat     #0      ,   #0
stptr       dat     #0      ,   #2521

            mov.i   *10     ,   @10
            dat     57      ,   58
            dat     59      ,   60
            dat     61      ,   62

bombp       dat     5       ,   6
boot        mov.i   @boot   ,   {boot_loc
            mov.i   boot-1  ,   <boot
            djn.a   boot    ,   #60
            spl     boot_loc+1, 0
            jmp     boot_loc, 0
            end
