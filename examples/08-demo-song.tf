% %%
% %% Title: A Song for Altair
% %% Author: t-sin
% %%


% %%
% %% first track

440 sin              % oscillator
dup
0.05 0.1 0.3 0.05 adsr  % envelope
dup rot swap

% sequence 1
()
:d 3 2 n :r 4 -2 n :a 3 2 n :r 4 -2 n :f+ 3 2 n :r 4 -2 n :b 3 2 n :r 4 -2 n
:d 3 2 n :r 4 -2 n :a 3 2 n :r 4 -2 n :f+ 3 2 n :r 4 -2 n :b 3 2 n :r 4 -2 n

:c 3 2 n :r 4 -2 n :g 3 2 n :r 4 -2 n :d 3 2 n :r 4 -2 n :b 3 2 n :r 4 -2 n
:c 3 2 n :r 4 -2 n :g 3 2 n :r 4 -2 n :d 3 2 n :r 4 -2 n :b 3 2 n :r 4 -2 n

:a+ 2 2 n :r 4 -2 n :d 3 2 n :r 4 -2 n :f 2 2 n :r 4 -2 n :a+ 3 2 n :r 4 -2 n
:a+ 2 2 n :r 4 -2 n :d 3 2 n :r 4 -2 n :f 2 2 n :r 4 -2 n :a+ 3 2 n :r 4 -2 n

:a 3 2 n :r 4 -2 n :a 2 2 n :r 4 -2 n :e 3 2 n :r 4 -2 n :a 2 2 n :r 4 -2 n
:a 3 2 n :r 4 -2 n :g 3 2 n :r 4 -2 n :f+ 3 2 n :r 4 -2 n :e 3 2 n :r 4 -2 n

:d 3 2 n :r 4 -2 n :a 3 2 n :r 4 -2 n :f+ 3 2 n :r 4 -2 n :b 3 2 n :r 4 -2 n
:d 3 2 n :r 4 -2 n :a 3 2 n :r 4 -2 n :f+ 3 2 n :r 4 -2 n :b 3 2 n :r 4 -2 n

:c 3 2 n :r 4 -2 n :g 3 2 n :r 4 -2 n :d 3 2 n :r 4 -2 n :b 3 2 n :r 4 -2 n
:c 3 2 n :r 4 -2 n :g 3 2 n :r 4 -2 n :d 3 2 n :r 4 -2 n :b 3 2 n :r 4 -2 n

:a+ 2 2 n :r 4 -2 n :d 3 2 n :r 4 -2 n :f 2 2 n :r 4 -2 n :a+ 3 2 n :r 4 -2 n
:a+ 2 2 n :r 4 -2 n :d 3 2 n :r 4 -2 n :f 2 2 n :r 4 -2 n :a+ 3 2 n :r 4 -2 n

:a 3 2 n :r 4 -2 n :a 2 2 n :r 4 -2 n :e 3 2 n :r 4 -2 n :a 2 2 n :r 4 -2 n
:a 3 2 n :r 4 -2 n :g 3 2 n :r 4 -2 n :f+ 3 2 n :r 4 -2 n :e 3 2 n :r 4 -2 n

:d 3 2 n :r 4 -2 n :a 3 2 n :r 4 -2 n :f+ 3 2 n :r 4 -2 n :b 3 2 n :r 4 -2 n
:d 3 2 n :r 4 -2 n :a 3 2 n :r 4 -2 n :f+ 3 2 n :r 4 -2 n :b 3 2 n :r 4 -2 n

:c 3 2 n :r 4 -2 n :g 3 2 n :r 4 -2 n :d 3 2 n :r 4 -2 n :b 3 2 n :r 4 -2 n
:c 3 2 n :r 4 -2 n :g 3 2 n :r 4 -2 n :d 3 2 n :r 4 -2 n :b 3 2 n :r 4 -2 n

:a+ 2 2 n :r 4 -2 n :d 3 2 n :r 4 -2 n :f 2 2 n :r 4 -2 n :a+ 3 2 n :r 4 -2 n
:a+ 2 2 n :r 4 -2 n :d 3 2 n :r 4 -2 n :f 2 2 n :r 4 -2 n :a+ 3 2 n :r 4 -2 n

:a 3 2 n :r 4 -2 n :a 2 2 n :r 4 -2 n :e 3 2 n :r 4 -2 n :a 2 2 n :r 4 -2 n
:a 3 2 n :r 4 -2 n :g 3 2 n :r 4 -2 n :f+ 3 2 n :r 4 -2 n :e 3 2 n :r 4 -2 n

:a 3 4 n
seq
() swap append


% %%
% %% second track

440 sin              % oscillator
swap over
0.05 0.1 0.3 0.05 adsr  % envelope
swap over

% sequence 2
()
:a 3 4 n :e 3 4 n :a 3 4 n :e 3 4 n
:g 3 4 n :e 3 4 n :g 3 4 n :e 3 4 n
:f 3 4 n :d 3 4 n :f 3 4 n :d 3 4 n
:c+ 3 4 n :e 3 4 n :a 2 4 n :e 3 4 n

:a 3 4 n :e 3 4 n :a 3 4 n :e 3 4 n
:g 3 4 n :e 3 4 n :g 3 4 n :e 3 4 n
:f 3 4 n :d 3 4 n :f 3 4 n :d 3 4 n
:c+ 3 4 n :e 3 4 n :a 2 4 n :e 3 4 n

:a 3 4 n :e 3 4 n :a 3 4 n :e 3 4 n
:g 3 4 n :e 3 4 n :g 3 4 n :e 3 4 n
:f 3 4 n :d 3 4 n :f 3 4 n :d 3 4 n
:c+ 3 4 n :e 3 4 n :a 2 4 n :e 3 4 n
:f+ 3 4 n
seq
rot swap append


% %%
% %% third track
440 saw              % oscillator
swap over
0.05 0 0.8 0.05 adsr  % envelope
swap over

% sequence 3
()
:r 3 -6 n :r 3 -6 n :r 3 -6 n :r 3 -6 n :r 3 -6 n

:f+ 3 5 n :r 3 -4 n
:e 3 2 n :r 3 -2 n :f+ 3 2 n :r 3 -2 n :g 3 5 n :r 3 -4 n
:f+ 3 2 n :r 3 -2 n :g 3 2 n :r 3 -2 n :a 3 5 n :r 3 -4 n
:a 3 2 n :r 3 -2 n :a+ 3 2 n :r 3 -2 n :a 3 5 n :r 3 -4 n :r 3 -4 n

:f+ 3 5 n :r 3 -4 n
:e 3 2 n :r 3 -2 n :f+ 3 2 n :r 3 -2 n :g 3 5 n :r 3 -4 n
:f+ 3 2 n :r 3 -2 n :g 3 2 n :r 3 -2 n :a 3 4 n :d 3 4 n :r 3 -4 n
:a 3 2 n :r 3 -2 n :g 3 2 n :f+ 3 2 n :e 3 5 n :r 3 -4 n :r 3 -4 n

:d 3 5 n
seq
rot swap append


% %%
% %% setup

% set sequencers
ev

% multiply each pair of oscillator and envelope
() swap append swap append mul
() swap append
rot rot
() swap append swap append mul
append rot rot
() swap append swap append mul
append

% mix three tracks
0.2 mix

% set unit generators
ug
