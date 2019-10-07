0 rnd dup .s
0 0.05 0 0 adsr dup .s
rot swap .s
( 3 2 2 2 1 0 0 -2 1 1
  3 2 2 2 1 0 0 -2 1 1 )
rseq .s
ev
() swap append swap append .s mul
ug
