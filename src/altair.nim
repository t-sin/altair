import math

import altair/ug
import altair/soundsystem as ss


var
  saw1 = Saw(phase: 0, freq: 440)
  saw2 = Saw(phase: 0, freq: 445)
  mix = Mix(sources: @[saw1.UG, saw2.UG], amp: 0.2)

ss.stop(ss.start(mix))
