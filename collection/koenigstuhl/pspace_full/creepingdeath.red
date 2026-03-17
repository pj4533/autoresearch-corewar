;redcode-94
;name Creeping Death
;author Christian Schmidt
;strategy stone, scanner, oneshot, paper
;strategy new developed p-switching pattern
;assert 1

org think 

;###########Constants##############
;----------p-switcher--------------
STORE   equ     159
;----------paper-------------------
cDst1   equ     2359
cDst2   equ     3201
cDst3   equ     2899
cHit1   equ     1529
cHit2   equ     7273
pAwa    equ     7750
;----------oneshot----------------
step    equ     16
sep     equ     (step/2)
stream  equ     (ptr-500);412)
scan1   equ     (inc+step)
imp     equ     2667
cstart  equ     (last+2-ptr)
off     equ     100
boff    equ     684
;-------------scanner-------------
sStep   equ     7982 
sHit    equ     20 
sTrain  equ     573 
cGate   equ     (sHead-2) 
pBoot   equ     4414 
;--------------stone--------------
dstep   equ     81
dhop    equ     5277
dtime   equ     1677
dbmb    equ     (dend+4)
dAwa    equ     4764

;#######STONE################

dwarf mov   dend,      @dptr
      mov   {dwarf,    <dptr
      mov   {dwarf,    <dptr
dptr  mov   datb,      *dAwa
      mov   {dwarf,    <dptr
      mov   {dwarf,    <dptr
djmp  djn.f @ dptr,    dptr

      spl   #0,        <dhop+2 
dloop mov   dbmb,      {(dstep*dtime)+1
      mov   dbmb,      @dloop 
      sub   #dstep,    dloop
dend  djn.f dloop,     <dhop-2
datb  dat   <dhop+1,   >1

;#######P-SWITCHER################
w0    equ dwarf    ;stone
w1    equ scanb    ;scanner
w2    equ clear    ;o-shot
w3    equ pboot    ;paper 

think   ldp.a #0, in
    ldp.a #STORE, table
    mod.ba *in, table
    stp.b *table, #STORE
                  ;St L W T
table jmp }0, 441   ; 1 0 1 891 ;0  1 0 0 ;initial
      dat w0, 792    ;2 0 2 243 ;1  3 0 1   
      dat w1, 893 ;2  3 2 2   
      dat w1, 344 ;3  4 2 3   
      dat w1, 785   ; 5 2 4 246 ;4  6 3 4
      dat w2, 896 ;5  6 5 5
      dat w2, 347 ;6  7 5 6
      dat w2, 689   ; 9 5 7 249;;7  9 6 7
      dat w3, 899 ;8  9 8 8
      dat w3,1241 ;9  1 8 9

      dat w3, 349 ;   9 7 8 ;unreachable
in    dat 0, 10  
pboot spl 2,  9
      spl 2, 11

;#######PAPER################

      spl    1
      mov    -1, 0

      mov    <pGo,  {pGo
pGo   jmp    pAwa,  cBomb+1

      spl    @0         , >cDst1
      mov    }-1        , >-1
cSlk2 spl    @0         , >cDst2
      mov    }-1        , >-1
      mov    cBomb      , >cHit1
      mov    cBomb      , >cHit2
      mov    {cSlk2     , <1
      djn    @0         , <cDst3
cBomb dat    <2667      , <5334

;#######SCANNER################

scanb   spl     1,           cBmb+2

    for 6 
        mov.i   {scanb,       {scanS
    rof 
        djn     sScan+pBoot-1,  #1 
scanS   mov.i   cBmb+pBoot+1,   -1 

 dat 0, 0
 dat 0, 0

sHead   mov    }sFlag,     >1800 
sWip    mov    *sAdd,      >sHead 
sAdd    add.f  stepX,      sScan 
sScan   sne    }2*sStep+8, 2*sStep 
sFlag   djn.f  sAdd,       <sTrain 
        mov.b  sScan,      @sWip 
        djn    {sFlag,     #sHit 
stepX   spl    #sStep,     sStep 
cLoo    mov    cBmb,       >cGate 
        djn.f  cLoo,       >cGate 
cBmb    dat    <2667,      2-cGate 


;#######ONESHOT################

ptr     dat.f   bomb1,#0
bomb3   dat <5334, <2667         
inc     dat.f   step,step
bomb2   spl.a   #(bomb3-ptr),cstart
mEnd    dat 0, 0

for 3
dat 0, 0
rof

loop    add.f   inc,cscan
cscan    sne.i   scan1+off,scan1+sep+off
        djn.f   loop,<stream
        mov.ab  cscan,ptr
bomb1   spl.a   #(bomb2-ptr),cstart
cclear   mov.i   *ptr,>ptr
last    djn.f   cclear,<stream
oEnd    dat     0,     0

for 3
dat 0, 0
rof

clear   mov.i   {mEnd, {mBoo
        mov.i   {mEnd, {mBoo
        djn     -2,    #2
        mov.i   {oEnd, {oBoo
        mov.i   {oEnd, {oBoo
        mov.i   {oEnd, {oBoo
        djn     -3,    #2
        mov.i   {oEnd, {oBoo
oBoo    jmp     oEnd+boff
mBoo    dat     mEnd+boff, 0

end

