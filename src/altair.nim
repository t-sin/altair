import math
import streams

import altair/ug
import altair/ev
import altair/soundsystem
import altair/tf


var
  vm = makeVM()
  program = """
0 rnd dup
0 0.1 0 0 adsr dup rot swap
( 3 3 3 3 )
seq
ev
() swap append swap append .s mul
ug
"""
  stream = newStringStream(program)

echo program
vm.initVM()
vm.program = parseProgram(stream)
vm.interpret()

proc handleCtrlC() {.noconv.} =
  echo "interrupted by user!"
  raise newException(Exception, "interrupted by user!")

setControlCHook(handleCtrlC)

try:
  synthesize(vm.ug, vm.ev)

except Exception:
  quit(0)
