import streams
import strutils


type
  Type* = enum
    Name, Num, Builtin

  Cell* = ref object
    kind*: Type
    name*: string
    num*: float32
    builtin*: proc (vm: VM)

  Dict* = ref object
    prev*: Dict
    name*: string
    data*: Cell

  VM* = ref object
    program*: seq[string]
    ip*: int
    dict*: Dict
    dstack*: seq[Cell]

proc reprCell*(cell: Cell): string =
  var str: string
  if cell.kind == Name:
    str = cell.name
  elif cell.kind == Num:
    str = cell.num.repr

  "<$1:$2>" % [cell.kind.repr, str]

proc vmPrintStack(vm: VM) =
  stdout.write "["
  for idx in 0..<vm.dstack.len:
    stdout.write reprCell(vm.dstack[idx])
    if idx != vm.dstack.len - 1:
      stdout.write " "
  echo "]"

proc makeVM*(): VM =
  var
    dict = Dict(prev: nil, name: "<tf/nil>", data: nil)
    vm = VM(program: @[], ip: 0, dict: dict, dstack: @[])

  vm

proc addWord*(vm: VM, name: string, data: Cell) =
  var
    top = vm.dict
    dict = Dict(prev: top, name: name, data: data)

  vm.dict = dict

proc findWord*(vm: VM, name: string): Cell =
  var dict = vm.dict

  while true:
    if dict.isNil():
      return nil
    elif dict.name == name:
      return dict.data

    dict = dict.prev

proc interpret*(vm: VM) =
  while vm.ip >= 0 and vm.ip < vm.program.len:
    var
      name = vm.program[vm.ip]
      cell = vm.findWord(name)

    if cell == nil:
      raise newException(Exception, "unknown word: `$1`" % [name])

    if cell.kind == Builtin:
      cell.builtin(vm)
    else:
      vm.dstack.add(cell)

    vm.ip += 1


proc parseProgram*(stream: Stream): seq[string] =
  var
    program: seq[string] = @[]
    buf = ""
    readingSpaces = false

  while not stream.atEnd():
    if stream.peekChar() in " \n":
      discard stream.readChar()

      if readingSpaces == false:
        readingSpaces = true
        program.add(buf)
        buf = ""

    else:
      readingSpaces = false
      buf.add(stream.readChar())

  program


proc initVM*(vm: VM) =
  vm.addWord(".s", Cell(kind: Builtin, builtin: vmPrintStack))


