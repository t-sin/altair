import portaudio as PA

import ug
import ev
import tf


type
  SoundSystem* = ref object
    stream*: PStream
    mi*: MasterInfo
    vm*: VM
    playing*: bool

proc paCallback(
        inBuf, outBuf: pointer, framesPerBuf: culong,
        timeInfo: ptr TStreamCallbackTimeInfo,
        statusFlags: TStreamCallbackFlags,
        userData: pointer): cint {.cdecl.} =

  var
    soundsystem = cast[ptr SoundSystem](userData)[]
    outBuf = cast[ptr array[0xffffffff, Signal]](outBuf)
    completed = true

  for i in 0..<framesPerBuf.int:
    for ev in soundsystem.vm.ev:
      procEV(ev, soundsystem.mi)

    outBuf[i] = procUG(soundsystem.vm.ug, soundsystem.mi)

    soundsystem.mi.tick += 1
    soundsystem.mi.sec += 1.0 / soundsystem.mi.sampleRate

  for ev in soundsystem.vm.ev:
    completed = completed and procCompleted(ev)
  if soundsystem.vm.ev.len == 0 or soundsystem.vm.isREPL:
    completed = false
  soundsystem.playing = not completed

  if completed:
    scrComplete.cint
  else:
    scrContinue.cint

proc synthesize*(vm: VM) =
  var
    stream: PStream
    mi = MasterInfo(sampleRate: 44100)
    soundsystem = SoundSystem(
      stream: stream, vm: vm, mi: mi, playing: true)

  discard PA.Initialize()
  discard PA.OpenDefaultStream(
    cast[PStream](stream.addr),
    numInputChannels = 0,
    numOutputChannels = 2,
    sampleFormat = sfFloat32,
    sampleRate = mi.sampleRate,
    framesPerBuffer = 2048,
    streamCallback = paCallback,
    userData = cast[pointer](soundsystem.addr))
  discard PA.StartStream(stream)

  while true:
    PA.Sleep(500)
    if soundsystem.playing == false:
      break

  discard PA.StopStream(stream)
  discard PA.CloseStream(stream)
  discard PA.Terminate()
