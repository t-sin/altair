import math

import altair/ug
import altair/soundsystem as ss


type
  Osc = ref object of UG
    phase*: float32
    freq*: float32
  Saw = ref object of Osc

method procUG*(ug: Saw, sampleRate: float32): Signal =
  var
    ph = ug.phase mod 1.0f32
    s: Signal

  if ph == 0.0f32:
    s = (1.0f32, 1.0f32)
  else:
    var v = -2 * ph + 1
    s = (v, v)

  ug.phase += ug.freq / sampleRate / math.PI
  s

var
  saw = Saw(phase: 0, freq: 440)
  soundsystem = ss.start(saw)

ss.stop(soundsystem)
