;redcode-PW
;name AeroPap AI
;author Christian Schmidt
;strategy p-switch LP paper and 94 paper
;assert 1

;----Replication----
l       equ     26
zofs    equ     2309

;------Bombing------
bo1     equ     6327
bo2     equ     2285
color   equ     686
a       equ     4029
b       equ     5354
c       equ     4846

zero    equ     pGo

org think

pStep   equ   (2946)
pStep2  equ   (-200+355)
pInd    equ   (3472)

pGo
tG      spl    2            ,0
tH      spl    1            ,0
tI      spl    1            ,0
        spl    pB           ,0
        mov    <pAj         ,{pAj
pAj     jmp    pPap-2667+6  ,pPap+6
pB      mov    @pAj         ,{pBj
pBj     spl    pPap+2667+6  ,0

pPap    spl    @0           ,>pStep
        mov    }pPap        ,>pPap
        mov    {pPap        ,<1
        spl    @0           ,>pStep2
        mov.i  #-2668-pInd  ,}pInd
null    dat    0            ,0

    for 32
        dat 0,0
    rof

storage equ 234

think   ldp.a  #0,      mtab
        ldp.ba  2,      table
        mod.ba *mtab,   table
        stp.b  *table, #storage
table   jmp }0,     724 ; =  80*9 + 4 = 65*11 +  9 = 72*10 + 4
        jmp from,  130 ; =  14*9 + 4 = 11*11 +  9 = 13*10 + 0
        dat pGo, 666 ; =  74*9 + 0 = 60*11 +  6 = 66*10 + 6
        dat from,  835 ; =  92*9 + 7 = 75*11 + 10 = 83*10 + 5
        dat pGo, 448 ; =  49*9 + 7 = 40*11 +  8 = 44*10 + 8
        dat from,  857 ; =  95*9 + 2 = 77*11 + 10 = 85*10 + 7
        dat pGo, 776 ; =  86*9 + 2 = 70*11 +  6 = 77*10 + 6
        dat from,  362 ; =  40*9 + 2 = 32*11 + 10 = 36*10 + 2
        dat pGo, 778 ; =  86*9 + 4 = 70*11 +  8 = 77*10 + 8
        dat from,  801 ; =  89*9 + 0 = 72*11 +  9 = 80*10 + 1
        dat from,  923 ; = 102*9 + 5 = 83*11 + 10 = 92*10 + 3
mtab    dat 0,  9
        dat 0, 11
        dat 0, 10

    for 27
        dat 0,0
    rof

from    mov     #l,      #0
loop    mov     d1 ,     >a
       mov     d1 ,     >b
       mov     d1 ,     >c
       mov     <from,   {to
       jmn     loop,    from
       spl     >from,   }color
to      jmz     zofs,    *0
d1      dat     <5334 ,  <2667


end

