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


type
  Mix = ref object of UG
    sources*: seq[UG]
    amp*: float32

method procUG*(ug: Mix, sampleRate: float32): Signal =
  var
    s = (0.0f32, 0.0f32)

  for src in ug.sources:
    s = s + procUG(src, sampleRate)

  s * ug.amp


var
  saw1 = Saw(phase: 0, freq: 440)
  saw2 = Saw(phase: 0, freq: 445)
  mix = Mix(sources: @[saw1.UG, saw2.UG], amp: 0.2)

ss.stop(ss.start(mix))
