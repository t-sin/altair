import math

type
  Signal* = tuple[left: float32, right: float32]
  MasterInfo* = ref object
    sampleRate*: float32

proc `*`*(s: Signal, v: float32): Signal =
  (s.left * v, s.right * v)

proc `+`*(s: Signal, v: float32): Signal =
  (s.left + v, s.right + v)

proc `+`*(s1, s2: Signal): Signal =
  (s1.left + s2.left, s1.right + s2.right)


type
  UG* = ref object of RootObj
    input: UG

method procUG*(ug: UG, mi: MasterInfo): Signal {.base.} =
  ug.input.procUG(mi)


type
  Osc* = ref object of UG
    phase*: float32
    freq*: float32
  Saw* = ref object of Osc

method procUG*(ug: Saw, mi: MasterInfo): Signal =
  var
    ph = ug.phase mod 1.0f32
    s: Signal

  if ph == 0.0f32:
    s = (1.0f32, 1.0f32)
  else:
    var v = -2 * ph + 1
    s = (v, v)

  ug.phase += ug.freq / mi.sampleRate / math.PI
  s


type
  Mix* = ref object of UG
    sources*: seq[UG]
    amp*: float32

method procUG*(ug: Mix, mi: MasterInfo): Signal =
  var
    s = (0.0f32, 0.0f32)

  for src in ug.sources:
    s = s + src.procUG(mi)

  s * ug.amp
