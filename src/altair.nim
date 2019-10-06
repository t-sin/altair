import math
import os
import streams

import altair/ug
import altair/soundsystem
import altair/tf

echo """

Programmable Synthesizer

          _|    _|                _|
  _|_|_|  _|  _|_|_|_|    _|_|_|      _|  _|_|
_|    _|  _|    _|      _|    _|  _|  _|_|
_|    _|  _|    _|      _|    _|  _|  _|
  _|_|_|  _|      _|_|    _|_|_|  _|  _|

"""

var
  filename: string
  stream: Stream
  vm = makeVM()

if "--help" in os.commandLineParams():
  echo """Usage:
  altair [TFORTHFILE]
"""
  quit(0)

vm.resetVM()
vm.initVM()
vm.ug = Mix(sources: @[Saw(phase: 0, freq: 440).UG], amp: 0.2)
vm.ev = @[]

if os.paramCount() >= 1:
  filename = $(os.commandLineParams()[0])
  stream = newFileStream(filename, fmRead)

  if stream.isNil():
    echo filename & " does not exists."
    quit(0)

  vm.isREPL = false
  vm.program = parseProgram(stream)
  vm.interpret()

proc handleCtrlC() {.noconv.} =
  echo "interrupted by user!"
  raise newException(Exception, "interrupted by user!")

setControlCHook(handleCtrlC)

proc threadFn(vmPtr: pointer) {.thread.} =
  var vm = cast[ptr VM](vmPtr)[]
  synthesize(vm)

proc startSynth(vm: VM) =
  var thread: Thread[pointer]
  try:
    createThread(thread, threadFn, cast[pointer](vm.unsafeAddr))
    if vm.isREPL:
      while true:
        stdout.write "> "
        var line = readLine(stdin) & "\n"
        vm.resetVM()
        vm.program = parseProgram(newStringStream(line))
        vm.interpret()
    else:
      joinThread(thread)

  except Exception:
    quit(0)

startSynth(vm)
