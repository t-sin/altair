type
  Signal* = tuple[left: float32, right: float32]

proc `*`*(s: Signal, v: float32): Signal =
  (s.left * v, s.right * v)

proc `+`*(s: Signal, v: float32): Signal =
  (s.left + v, s.right + v)

proc `+`*(s1, s2: Signal): Signal =
  (s1.left + s2.left, s1.right + s2.right)


type
  UG* = ref object of RootObj
    input: UG

method procUG*(ug: UG, sampleRate: float32): Signal {.base.} =
  ug.input.procUG(sampleRate)
