;redcode-94
;name BackWriter v1
;author https://github.com/kd00r
;strategy writing backwards hoping to corrupt forward-executing programs. Fails miserably at this exact task, however.
ORG 0;

mov 2, -1;
sub #1, -1;
jmp -2;
