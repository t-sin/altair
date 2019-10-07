% push oscillator
0 rnd dup .s

% push envelope generator
0 0.05 0 0 adsr dup .s

% some stack manipulation...
rot swap .s

% push rhythm pattern
( 3 2 2 2 1 0 0 -2 1 1
  3 2 2 2 1 0 0 -2 1 1 )

% make rseq (rhythm sequencer) with oscillator, envelope and pattern
rseq .s

% set global events
ev

% set global ug to osc above
() swap append swap append .s mul
ug
