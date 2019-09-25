import portaudio as PA

import ug
import ev


type
  SoundSystem* = ref object
    stream*: PStream
    mi*: MasterInfo
    rootUG*: UG
    events*: seq[Seq]

proc paCallback(
        inBuf, outBuf: pointer, framesPerBuf: culong,
        timeInfo: ptr TStreamCallbackTimeInfo,
        statusFlags: TStreamCallbackFlags,
        userData: pointer): cint {.cdecl.} =

  var
    soundsystem = cast[ptr SoundSystem](userData)[]
    outBuf = cast[ptr array[0xffffffff, Signal]](outBuf)

  for i in 0..<framesPerBuf.int:
    for ev in soundsystem.events:
      procSeq(ev, soundsystem.mi)

    outBuf[i] = procUG(soundsystem.rootUG, soundsystem.mi)

    soundsystem.mi.tick += 1
    soundsystem.mi.sec += 1.0 / soundsystem.mi.sampleRate

  scrContinue.cint


proc start*(ug: UG, ev: seq[Seq]): SoundSystem =
  var
    stream: PStream
    mi = MasterInfo(sampleRate: 44100)
    soundsystem = SoundSystem(stream: stream, rootUG: ug, events: ev, mi: mi)

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

  PA.Sleep(2000)
  soundsystem


proc stop*(ss: SoundSystem) =
  discard PA.StopStream(ss.stream)
  discard PA.CloseStream(ss.stream)
  discard PA.Terminate()
