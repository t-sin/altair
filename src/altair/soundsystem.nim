import portaudio as PA

import ug


type
  SoundSystem* = ref object
    stream*: PStream
    masterInfo*: MasterInfo
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
    outBuf[i] = procUG(soundsystem.rootUG, soundsystem.masterInfo)

  scrContinue.cint


proc start*(ug: UG): SoundSystem =
  const
    sampleRate = 44100
  var
    stream: PStream
    mi: MasterInfo = MasterInfo(sampleRate: sampleRate)
    soundsystem: SoundSystem = SoundSystem(stream: stream, rootUG: ug, masterInfo: mi)

  discard PA.Initialize()
  discard PA.OpenDefaultStream(
    cast[PStream](stream.addr),
    numInputChannels = 0,
    numOutputChannels = 2,
    sampleFormat = sfFloat32,
    sampleRate = sampleRate,
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
