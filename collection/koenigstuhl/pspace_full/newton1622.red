;redcode
;name RepliBomber Strain 2B
; (16_22.red)
;author Terry Newton
;strategy Evolved by RedMixer 1.0c-8K (2/17/09)
;origin 11_12.red
;parents 17_23.red 18_23.red
;generation 271 
;assert CORESIZE==8000
spl.i  #  306 , #  113
spl.i  #   -1 , # 3477
spl.ba # 2474 , } 2966
spl.a  # 6811 , }    1
mov.i  } 7920 , >   -2
mov.i  } 7920 , }    3
mov.i  $   -3 , { 6027
add.ba #  178 , { 1123
jmp.x  }  492 , < 4092
spl.x  #  810 , *    0
dat.ab @ 5265 , * 4008
mov.ab $  697 , > 6573
dat.f  } 7184 , *   -8
sub.ab * 2697 , # 3585
seq.i  { 1344 , > 5566
dat.f  @ 5380 , # 3045
dat.f  @ 6555 , @ 3426
seq.ba @ 5595 , {  -10
seq.i  { 6503 , > 3227
mov.ba $ 5468 , > 2065
spl.i  > 4055 , } 3012
jmn.i  { 3403 , { 6560
jmz.x  $   10 , @ 6853
dat.i  $   10 , @ 6850
dat.i  $ 6454 , @   23
dat.i  { 4016 , } 6853
spl.i  # 6693 , * 7788
dat.f  # 1676 , $  611
spl.b  } 2482 , $  610
dat.b  } 7543 , $  610
spl.ab > 4333 , > 2598
spl.f  *   12 , > 1996
add.ba * 7240 , #   13
add.ab *   37 , @   -1
jmz.a  <  275 , @ 3185
dat.i  <  884 , * 6100
sne.f  } 5538 , >   31
spl.i  #  753 , >   -4
stp.ba { 2073 , $ 6595
mov.x  } 1913 , @ 3624
mov.b  < 7659 , $ 6264
jmn.i  @ 3200 , >  -18
dat.x  { 4276 , # 7842
jmn.i  @ 3201 , @  -18
jmn.a  } 3200 , < 2933
mul.f  @    7 , {  -25
mov.x  @    6 , *    4
sub.i  * 7188 , * 3574
spl.i  >  295 , > 1357
sne.x  @    0 , @  -17
jmz.i  { 1851 , { 1296
dat.i  < 6526 , @    2
mov.b  < 3290 , * 5609
sne.f  $  902 , {    0
mov.ba * 7617 , <   41
mov.x  @ 6410 , {  -43
dat.i  > 6836 , {  867
jmp.i  @ 6279 , $    1
dat.i  { 1076 , * 7483
dat.ba # 4929 , < 3632
spl.a  > 1773 , *  -25
mov.a  > 7575 , } 4364
mov.a  { 6030 , } 6841
dat.x  @ 3733 , $ 4070
mul.i  {   16 , >   10
end 1 
;species 11_01
;wins 4
;score 140
