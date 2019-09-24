import math

import altair/ug
import altair/soundsystem as ss

type
  Saw = ref object of UG
    phase: float32

method procUG(ug: Saw): Signal =
  ug.phase += 0.01

  var
    ph = ug.phase mod 1.0f32
    s: Signal

  if ph <= 0.0f32:
    s = (1.0f32, 1.0f32)
  else:
    var v = -2 * ph + 1
    s = (v, v) * 0.3f32

  s

var
  saw = Saw(phase: 0)
  soundsystem = ss.start(saw)

ss.stop(soundsystem)
