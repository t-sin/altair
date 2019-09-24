type
  Signal* = tuple[left: float32, right: float32]

proc `*`*(s: Signal, v: float32): Signal =
  (s.left * v, s.right * v)

proc `+`*(s: Signal, v: float32): Signal =
  (s.left + v, s.right + v)


type
  UG* = ref object of RootObj
    input: UG

method procUG*(ug: UG): Signal {.base.} =
  ug.input.procUG()
