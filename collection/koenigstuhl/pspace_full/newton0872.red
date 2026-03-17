;redcode
;name RepliBomber Strain 1B
; (08_72.red)
;author Terry Newton
;strategy Evolved by RedMixer 1.0c-8K (2/17/09)
;origin 11_12.red
;parents 07_72.red 07_71.red
;generation 287 
;assert CORESIZE==8000
mul.ab < 4663 , * 7390
spl.a  #   -2 , @   -1
mov.i  $    0 , { 4824
mov.f  $ 7530 , { 4824
spl.i  #  700 , # 2989
spl.ba # 5162 , { 3220
spl.i  # 2107 , <    0
mov.i  } 7922 , }    3
mov.i  $   -2 , < 6027
add.ba # 4403 , < 1124
jmp.i  > 1464 , $  905
spl.ba } 7442 , } 4922
jmp.i  $   -4 , {   10
mov.ab {   -8 , $ 5529
mov.f  } 6737 , # 6004
dat.x  } 6737 , $ 3488
dat.f  } 6737 , $ 3488
dat.i  < 6128 , { 3448
dat.i  {   -2 , } 1425
sne.f  * 7868 , } 1425
sne.f  } 6391 , } 2026
sne.f  }  419 , * 7279
sne.f  }  419 , > 7280
spl.ab > 6833 , * 1328
spl.x  <   -4 , } 3908
sub.f  }  -21 , @   -5
add.i  > 3176 , #  -12
mov.f  @ 5082 , >   19
mov.ab >  103 , { 3009
mod.ab >  104 , { 1518
mov.ba >  932 , { 3010
mov.b  >  933 , { 6810
mov.b  >  933 , { 3009
mov.i  <  103 , { 5032
mov.i  <  105 , { 5032
dat.f  @ 5963 , @ 2747
dat.i  < 5773 , <   16
spl.ab > 3060 , > 3513
ldp.ab * 1197 , *   29
spl.i  $  813 , } 5817
mul.f  <  -22 , {  -15
jmz.a  #   37 , } 2768
spl.ab # 1457 , < 1924
spl.ab @ 4749 , * 4400
mod.a  >  165 , > 5125
mod.ab } 2138 , # 2193
sub.x  < 5188 , *    1
spl.i  } 6183 , @ 7799
ldp.f  * 7127 , {   14
sne.i  @  -32 , @  -19
sne.i  @  -32 , @  -19
spl.i  *   44 , < 4409
ldp.a  $ 5127 , >   27
mov.x  * 3860 , @   26
add.a  < 7531 , $ 2228
dat.i  @  707 , @ 1437
dat.i  *  -15 , } 1091
dat.i  *  -15 , }  -46
mov.i  < 3784 , # 5799
end 0 
;species 15_14
;wins 3
;score 123

