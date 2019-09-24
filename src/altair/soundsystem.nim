import portaudio as PA

import ug


type
  SoundSystem* = ref object
    stream*: PStream
    rootUG*: UG

proc paCallback(
        inBuf, outBuf: pointer, framesPerBuf: culong,
        timeInfo: ptr TStreamCallbackTimeInfo,
        statusFlags: TStreamCallbackFlags,
        userData: pointer): cint {.cdecl.} =

  var
    soundsystem = cast[ptr SoundSystem](userData)[]
    outBuf = cast[ptr array[0xffffffff, Signal]](outBuf)

  for i in 0..<framesPerBuf.int:
    outBuf[i] = procUG(soundsystem.rootUG)

  scrContinue.cint


proc start*(ug: UG): SoundSystem =
  var
    stream: PStream
    soundsystem: SoundSystem = SoundSystem(stream: stream, rootUG: ug)

  discard PA.Initialize()
  discard PA.OpenDefaultStream(
    cast[PStream](stream.addr),
    numInputChannels = 0,
    numOutputChannels = 2,
    sampleFormat = sfFloat32,
    sampleRate = 44_100,
    framesPerBuffer = 256,
    streamCallback = paCallback,
    userData = cast[pointer](soundsystem.addr))
  discard PA.StartStream(stream)

  PA.Sleep(2000)
  soundsystem

proc stop*(ss: SoundSystem) =
  discard PA.StopStream(ss.stream)
  discard PA.CloseStream(ss.stream)
  discard PA.Terminate()
