import math
import streams

import altair/ug
import altair/ev
import altair/soundsystem
import altair/tf


var
  saw1 = Saw(phase: 0, freq: 440)
  saw2 = Saw(phase: 0, freq: 445)
  rnd = Rnd(phase: 0, freq: 0)

var
  env = Env(adsr: Release, eplaced: 0, a: 0, d: 0.04, s: 0.1, r: 0.2)
  rhythm = Seq(env: env, osc: rnd.Osc, pat: len_to_pos(120, @[2,-1,1,1,1,1,1,2,2,2,2]))

var
  mix1 = Mix(sources: @[saw1.UG, saw2.UG], amp: 1)
  mul = Mul(sources: @[env.UG, rnd.UG])
  mix2 = Mix(sources: @[mul.UG], amp: 0.2)


proc handleCtrlC() {.noconv.} =
  echo "interrupted by user!"
  raise newException(Exception, "interrupted by user!")

setControlCHook(handleCtrlC)

try:
  synthesize(mix2, @[rhythm.EV])

except Exception:
  quit(0)


var vm = makeVM()
vm.initVM()
vm.addWord("hoge", Cell(kind: Number, number: 42.0))

var
  program = "{ .s .s } .s"
  stream = newStringStream(program)

echo program
vm.program = parseProgram(stream)
vm.interpret()
