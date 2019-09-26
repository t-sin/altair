import math

import ug


type
  Note* = tuple[freq: float32, sec: float, adsr: ADSR]

proc len_to_ratio*(n: int): float =
  (1.0 / 32.0) * pow(2.0, n.float)

proc len_to_pos*(bpm: float, len: seq[int]): seq[Note] =
  var
    sec = 0.0
    measure = bpm / 60.0
    notes: seq[Note] = @[]

  for len in len:
    if len < 0:
      if notes[notes.len - 1].adsr != Release:
        notes.add((0f32, sec, Release))
      sec += measure * len_to_ratio(abs(len))

    else:
      var len_sec = measure * len_to_ratio(len)
      notes.add((0f32, sec, Attack))
      notes.add((0f32, sec + len_sec, Release))
      sec += len_sec

  notes


type
  EV* = ref object of RootObj

method procEV*(ev: EV, mi: MasterInfo) {.base.} =
  discard

method procCompleted*(ev: EV): bool {.base.} =
  true


type
  Seq* = ref object of EV
    osc*: Osc
    env*: Env
    pat*: seq[Note]
    idx: int

method procEV*(ev: Seq, mi: MasterInfo) =
  while ev.idx < ev.pat.len and mi.sec >= ev.pat[ev.idx].sec:
      ev.env.adsr = ev.pat[ev.idx].adsr
      ev.env.eplaced = 0
      ev.osc.freq = ev.pat[ev.idx].freq
      ev.idx += 1

method procCompleted*(ev: Seq): bool =
  ev.idx >= ev.pat.len and ev.env.adsr == None
