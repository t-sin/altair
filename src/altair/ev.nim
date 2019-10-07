import math

import ug


type
  Note* = tuple[freq: float32, sec: float, adsr: ADSR]

proc keyToFreq*(s: string, o: int): float =
  var
    pos = "a bc d ef g".find(s[0])
    octave = o
  if s[0] in "ab":
    octave += 1
  if s.len > 1:
    if s[1] == '+':
      pos += 1
    elif s[1] == '-':
      pos -= 1
  440.0 * pow(2.0, (pos.float / 12.0 + octave.float - 4.0))

proc noteToRatio*(n: int): float =
  (1.0 / 32.0) * pow(2.0, n.float)

proc notesToPos*(bpm: float, notes: seq[tuple[n: int, f: float]]): seq[Note] =
  var
    sec = 0.0
    measure = bpm / 60.0
    result: seq[Note] = @[]

  for note in notes:
    if note.n < 0:
      if result[result.len - 1].adsr != Release:
        result.add((note.f.float32, sec, Release))
      sec += measure * noteToRatio(abs(note.n))
    else:
      var len_sec = measure * noteToRatio(note.n)
      result.add((note.f.float32, sec, Attack))
      result.add((note.f.float32, sec + len_sec, Release))
      sec += len_sec

  result


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
