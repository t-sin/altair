import math
import portaudio as PA

type
  Signal = tuple[left: float32, right: float32]

proc `*`(s: Signal, v: float32): Signal =
  return (s.left * v, s.right * v)

proc `+`(s: Signal, v: float32): Signal =
  return (s.left + v, s.right + v)


type
  Unit = ref object of RootObj
    prev: Unit

  Saw = ref object
    phase: float32

method procUnit(u: Unit): Signal {.base.} =
  return u.prev.procUnit()

method procUnit(u: Saw): Signal =
  u.phase += 0.01

  var
    ph = u.phase mod 1.0f32
    s: Signal

  if ph <= 0.0f32:
    s = (1.0f32, 1.0f32)
  else:
    var v = -2 * ph + 1
    s = (v, v) * 0.3f32

  return s

var
  stream: PStream
  osc = Saw(phase: 0)

proc fillPaBuffer(
  inBuf, outBuf: pointer, framesPerBuf: culong,
      timeInfo: ptr TStreamCallbackTimeInfo,
      statusFlags: TStreamCallbackFlags,
      userData: pointer): cint {.cdecl.} =

  var
    osc = cast[ptr Saw](userData)[]
    outBuf = cast[ptr array[0xffffffff, Signal]](outBuf)

  for i in 0..< framesPerBuf.int:
    outBuf[i] = procUnit(osc)

  scrContinue.cint

discard PA.Initialize()
discard PA.OpenDefaultStream(cast[PStream](stream.addr),
                     numInputChannels = 0,
                     numOutputChannels = 2,
                     sampleFormat = sfFloat32,
                     sampleRate = 44_100,
                     framesPerBuffer = 256,
                     streamCallback = fillPaBuffer,
                     userData = cast[pointer](osc.addr))
discard PA.StartStream(stream)

PA.Sleep(2000)

discard PA.StopStream(stream)
discard PA.CloseStream(stream)
discard PA.Terminate()
