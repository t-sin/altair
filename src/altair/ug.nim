import math
import random


type
  Signal* = tuple[left: float32, right: float32]
  MasterInfo* = ref object
    sampleRate*: float32
    tick*: uint64
    sec*: float

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
  Sin* = ref object of Osc
  Rnd* = ref object of Osc
    v: float32

method procUG*(ug: Saw, mi: MasterInfo): Signal =
  var
    ph = ug.phase mod 1.0f32
    s: Signal

  if ph == 0.0f32:
    s = (1.0f32, 1.0f32)
  else:
    var v = -2 * ph + 1
    s = (v, v)

  ug.phase += ug.freq / mi.sampleRate / 2
  s

method procUG*(ug: Sin, mi: MasterInfo): Signal =
  var
    ph = ug.phase mod (2 * PI).float32
    v = sin(ph)
    s: Signal = (v, v)

  ug.phase += ug.freq / mi.sampleRate / PI
  s

method procUG*(ug: Rnd, mi: MasterInfo): Signal =
  if ug.phase >= ug.freq:
    ug.phase = 0
    ug.v = (rand(2.0) - 1.0).float32

  ug.phase += 1
  (ug.v, ug.v)


type
  ADSR* = enum
    None, Attack, Decay, Sustin, Release
  Env* = ref object of UG
    adsr*: ADSR
    eplaced*: uint64
    a*: float32
    d*: float32
    s*: float64
    r*: float32

method procUG*(ug: Env, mi: MasterInfo): Signal =
  var
    a: uint64 = (ug.a * mi.sampleRate).uint64
    d: uint64 = (ug.d * mi.sampleRate).uint64
    s: float32 = ug.s
    r: uint64 = (ug.r * mi.sampleRate).uint64
    v: float32

  if ug.adsr == Attack:
    if ug.eplaced < a:
      v = ug.eplaced.float32 / a.float32

    elif ug.eplaced < a + d:
      v = 1.0 - (1.0 - s) * ((ug.eplaced - a).float32 / d.float32)
      ug.adsr = Decay

    else:
      v = ug.eplaced.float32 / a.float32
      ug.adsr = Decay

  elif ug.adsr == Decay:
    if ug.eplaced < a + d:
      v = 1.0 - (1.0 - s) * ((ug.eplaced - a).float32 / d.float32)

    elif ug.eplaced >= a + d:
      v = s
      ug.adsr = Sustin

    else:
      v = 0.0
      ug.adsr = None

  elif ug.adsr == Sustin:
    v = s

  elif ug.adsr == Release:
    if ug.eplaced < r:
      v = s - ug.eplaced.float32 * (s / r.float32)
    else:
      v = 0.0
      ug.adsr = None

  else:  # None
    v = 0.0f32

  ug.eplaced += 1
  (v, v)


type
  Mix* = ref object of UG
    sources*: seq[UG]
    amp*: float32
  Mul* = ref object of UG
    sources*: seq[UG]

method procUG*(ug: Mix, mi: MasterInfo): Signal =
  var
    s = (0.0f32, 0.0f32)

  for src in ug.sources:
    s = s + src.procUG(mi)

  s * ug.amp

method procUG*(ug: Mul, mi: MasterInfo): Signal =
  var
    s = (1.0f32, 1.0f32)

  for src in ug.sources:
    s = s * src.procUG(mi).left

  s
