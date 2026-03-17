;redcode-94b
;name dwarf booter 5.4d
;author Rimbecano
;strategy Dwarf with tweaked stepsize, boot, a new bomb,
;strategy And a surprise. :-)
;assert 1
pstep equ 3257 ;paper step
pstep2 equ 4596
bstep equ 100 ; paper bomb step
dlnc equ 4000  ;dwarf boot distance
dwln equ 3     ;number of lines in dwarf
dbtln equ 1    ;line to boot to in copied dwarf
Enemyp equ 99 ;not location in actual warrior
Win equ 99 ;not location in actual warrior
Lose equ 99 ; "..."
warrior equ pbrain
start equ 3000
hop equ 4
step equ 2288
wscore equ 6
lscore equ -2
tscore equ -1

sStep equ 4954 ;step modding stone constants taken from Core Warrior 65

mov.i {1601, 1-sStep
loc sub.x #sStep, $-1
jmp.b $-2, }-2

dboot   mov -dwln, dlnc-dwln
       mov -dwln, dlnc-dwln
       mov -dwln, dlnc-dwln
;       mov -dwln, dlnc-dwln
       spl (dlnc-6)+dbtln
       mov 0, paper

for 5
       dat #99, #99
rof

pbrain   ldp.ab #1, check
       jmz.b switch, check  ; washed or first round, just do a switch
check   mod.ab #99, #0000   ; if not multiple of 99, have been
                            ; washed! Not wash constant used in actual warrior
       jmn.b vamp, check    ; washed --> do vamp (can do any plogic)
       ldp.a #0, keeper
       ldp.ab #2, adjust
keeper  jmp @0, adjust+1       ; result == 0 == loss
       jmp 0, adjust           ; result == 1 == win
       jmp 0, adjust+2         ; result == 2 == tie
adjust  add.ab #wscore, #0     ; win
       add.ab #lscore, adjust  ; lose
       add.ab #tscore, adjust  ; tie
       ldp.a #1, select        ; again.  can't seem to save it.
       slt.b adjust, #7000     ; did it go negative?
       jmp switch
return  stp.b adjust, #2
       mod.a #3, select
select  jmp @0, vamp
       jmp 0, dboot
       jmp 0, paper
switch  add.a #99, select
       stp.ab select, #1
       mov.ab #10, adjust
       jmp return

paper
launch  spl 1
       mov -1, 0
       spl 1
silk    spl pstep, 0
       mov.i   >silk,  }silk
       mov.i   bomb, <bstep
       mov.i   <silk, {bsilk
bsilk   jmp.a   pstep2, 0

bomb    dat <99, {99

vamp    mov 0, dboot

       mov trap, trap+1000
       mov trap+1, trap+1001
       mov trap+2, trap+1002
       jmp strt

fang  jmp trap+1000,1

inc   dat #3364, #-3364 ; start here
strt add inc,fang
     mov fang,@fang
     djn -2, #475
     jmp a1

     dat 0, 0

ptr1    dat a1, en+100
a4      dat 0,  en+2+1
a3      dat 1,  en+2+2
a2      spl #2, en+2+3         ; spl #X, <-Y acts like a split 0.
a1      spl #3, en+2+4         ; you can use x and Y as step values
       mov *ptr1, >ptr1        ; and use the decrement in the b-
field
       mov *ptr1, >ptr1        ; as part of an imp gate.
       mov *ptr1, >ptr1        ; > (post-increment) keeps adding 1 to
en     djn.f -3, <4000         ; the b-field of ptr1 to move the bomb
                               ; through core.
trap
     spl #3, 0
     mov -1, }-1
     spl -2

for 9
       dat <99, {99
rof

; handshake from CW 20


enemy   ldp #Enemyp, #0
       jmn warrior, $enemy
last    ldp #0, #0
       sne #-1, $last
       jmp search
shake   jmz lost, $last
won     stp #0, #Lose
       stp #1, #Win
loser   ldp #Lose, #0
       jmz foe, $loser
       jmp 0

lost    stp #0, #Win
       stp #1, #Lose
winner  ldp #Win, #0
       jmz foe, $winner
       dat $0, $0
foe     stp #1, #Enemyp
jmp     warrior
search  jmz.f search, {count
count   sne.i #-100, {count
       jmp $0, {count

end enemy

