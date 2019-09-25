import math

import altair/ug
import altair/soundsystem as ss


var
  saw1 = Saw(phase: 0, freq: 440)
  saw2 = Saw(phase: 0, freq: 445)
  env = Env(adsr: Release, eplaced: 0, a: 0.1, d: 0, s: 1, r: 0.8)
  mix1 = Mix(sources: @[saw1.UG, saw2.UG], amp: 1)
  mul = Mul(sources: @[env.UG, mix1.UG])
  mix2 = Mix(sources: @[mul.UG], amp: 0.2)

ss.stop(ss.start(mix2))
