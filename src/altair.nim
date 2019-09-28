import math
import os
import streams

import altair/soundsystem
import altair/tf


if os.paramCount() <= 0:
  echo """Usage:
  altair TFORTHFILE
"""
  quit(0)

var
  filename = $(os.commandLineParams()[0])
  vm = makeVM()
  stream = newFileStream(filename, fmRead)

if stream.isNil():
  echo filename & " does not exists."
  quit(0)

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
