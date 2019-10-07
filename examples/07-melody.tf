440 saw dup .s
0 0 1 0.1 adsr dup .s
rot swap .s

% push sequence pattern and make sequencer (not `rseq`)
() :c 3 3 n :d 3 3 n :e 3 3 n :f 3 3 n :g 3 3 n :a 3 3 n :b 3 3 n :c 4 3 n
seq () swap append .s

ev
() swap append swap append .s mul
ug
