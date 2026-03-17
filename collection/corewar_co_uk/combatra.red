;redcode-94
;name Combatra
;author David Moore
;strategy Start each battle with a few quick scans. If nothing
;strategy is found, then run either a core clear or a bomber.
;strategy Otherwise, assume that Combatra found the opponent's
;strategy original 100 instructions. Probe to discover where its
;strategy processes run. Remember where everything is. Compute
;strategy the bootstrap distance. Later, a scanner finds the enemy
;strategy simply by locating its enormous boot code.
;assert CORESIZE==8000 && MAXLENGTH==100

org start

cgate   dat    -1,  sFirst
        dat <5334, <2667
        dat    -1,  12
clear   spl #3891,  sScan
        mov    -1, >cgate
        mov   *-1, >cgate
        djn.a  -2,  cgate
        djn.a  -3, *-1

        dat 0,0
        dat 0,0
        dat 0,0
        dat 0,0

sDiff   equ    65
sStep   equ    98
sFirst  equ  1283

sBoot   mov  <away, <where
        ldp.a #pBoot, sStore
        mov  <away, <where
        mov  >clear, >sJump
        djn -2, #7
sJump   djn.f start+dist-3+sDiff+1, #start+dist-3+sDiff

sScan   add.ab #sStep+1, @2
        jmz.f  sScan, <sScan-sDiff
        jmz.f  sScan, <sScan-sDiff
        spl (-3-sDiff)+3, <(-3-sDiff)
        djn.a  #6, #4
sStore  add.ab #0, -5-sDiff
        dat 0,0

bstep   equ 7829
btime   equ  863
btime2  equ  420

bomb    spl #bstep*2, -bstep
        mov {(bomb-2)+bstep*btime2, @3-(bstep*2)*btime
        mov   bomb, @-1
        add.x bomb,  -2
        djn.f -3, {-(bstep*2)*(btime-1)
        mov    2, >bomb-3
        djn.f -1, >bomb-3
        dat <2667, 6-bomb

check   ldp.a #pTroll, tab
        add.a   #5,  tab
tab     slt.ab  #0, #11
        jmp compute,  9
        jmp bBoot,   10

compute ldp.a #pQuick, diff
diff    sub.a  #0, tab
        add.a #((start-qPtr)+tDist+5-6)-11-196, tab
        stp.ab tab, #pBoot
        stp.ab #6, #pMode
        jmp boot, 0

        dat 0,0
        dat 0,0
        dat 0,0
        dat 0,0

pMode   equ 271
pBoot   equ 292
pQuick  equ 433
pTroll  equ 454

start   ldp.a #0, tab
        ldp.a #pMode, state
        mod.ba *tab,state
        stp.b *1, #pMode
state   jmp     }0, 472
        spl #check, 472
        spl #bBoot, 472
        spl #sBoot, 943
        spl #bBoot,  qA
qTable  spl #cBoot,  qB
        spl #sBoot,  qC
        spl #sBoot, 267
        spl #sBoot, 768
        spl #sBoot, 849
        jmp #cBoot, 455

tStep  equ 98
tTime  equ 2448

troll  mov    @0, *5
       add.f   3,  4
       jmz.a  -2,  1
       stp.ab #0, #pTroll
       jmp  #tStep, <-tStep
       mov.a #(-2-tStep*tTime), -2-(-2-tStep*tTime)

tDist   equ  2100

tBoot   mov <tJump, {tJump
        mov <tJump, {tJump
        djn -2, #3
qCalc   mul.ba qTable, qPtr
qPtr    sne     qX, datZero
        add.a #qDiff, qPtr
        stp.ab qPtr, #pQuick
        stp.ab  #1,  #pMode
        stp.ab  #0,  #pTroll
tJump   djn.f start+tDist+6, #troll+6

bAway   dat -3, bomb-(clear-3)

        dat 0,0
datZero dat 0,0
        dat 0,0
        dat 0,0

bBoot   add.f bAway, away

qX      equ 5072
qInv    equ 6831
qDiff   equ 5983
qA      equ (((qX+(qTable-qPtr)-2)*qInv)%CORESIZE)
qB      equ (((qX+(qTable-qPtr)-1)*qInv)%CORESIZE)
qC      equ (((qX+(qTable-qPtr)-0)*qInv)%CORESIZE)

cBoot   sne qPtr+(qA-0)*qX, qDiff+qPtr+(qA-0)*qX
        seq      <qTable-1, qDiff+qPtr+(qA-1)*qX
        jmp          tBoot, {qCalc
        sne qPtr+(qC-0)*qX, qDiff+qPtr+(qC-0)*qX
        seq      <qTable+1, qDiff+qPtr+(qC-1)*qX
        jmp          tBoot, }qCalc
        sne qPtr+(qB-0)*qX, qDiff+qPtr+(qB-0)*qX
        seq      <qTable+0, qDiff+qPtr+(qB-1)*qX
where   jmp          tBoot, start+dist+5

dist    equ 6942

boot    mov <away, <where
        mov <away, <where
        mov <away, <where
        mov <away, <where
        djn -4, #2
away    djn.f start+dist, #clear+5

end
