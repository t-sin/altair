% make empty list
()

% push two oscillators

440 saw append
445 saw append

% mix two oscillator outputs in the list

0.5 mix

% set global unit generator to the mixer above
ug
