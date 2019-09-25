import math

import ug


type
  Note* = tuple[freq: float32, sec: float, adsr: ADSR]

proc len_to_ratio*(n: int): float =
  echo $(n, (1.0 / 32.0) * pow(2.0, n.float))
  (1.0 / 32.0) * pow(2.0, n.float)

proc len_to_pos*(bpm: float, len: seq[int]): seq[Note] =
  var
    sec = 0.0
    measure = bpm / 60.0
    notes: seq[Note] = @[]

  for len in len:
    var len_sec = measure * len_to_ratio(len)
    notes.add((0f32, sec, Attack))
    notes.add((0f32, sec + len_sec, Release))
    sec += len_sec

  notes


type
  Seq* = ref object of RootObj
    osc*: Osc
    env*: Env
    pat*: seq[Note]
    idx: int

method procSeq*(s: Seq, mi: MasterInfo) {.base.} =
  while s.idx < s.pat.len and mi.sec >= s.pat[s.idx].sec:
      s.env.adsr = s.pat[s.idx].adsr
      s.env.eplaced = 0
      s.osc.freq = s.pat[s.idx].freq
      s.idx += 1
