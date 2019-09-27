import streams
import strutils


type
  Kind* = enum
    Name, Number, List, Builtin, Initial

  Cell* = ref object
    kind*: Kind
    name*: string
    number*: float32
    list*: seq[Cell]
    builtin*: proc (vm: VM)

  Dict* = ref object
    prev*: Dict
    name*: string
    data*: Cell

  VM* = ref object
    program*: seq[Cell]
    ip*: int
    dict*: Dict
    dstack*: seq[Cell]

proc reprCell*(cell: Cell): string =
  var str: string
  if cell.kind == Name:
    str = cell.name
  elif cell.kind == Number:
    str = cell.number.repr
  elif cell.kind == Builtin:
    str = "proc;$1" % [cell.builtin.addr.repr]
  elif cell.kind == List:
    str.add('[')
    for idx in 0..<cell.list.len:
      str.add(reprCell(cell.list[idx]))
      if idx != cell.list.len - 1:
        str.add(" ")
    str.add(']')

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
    var cell = vm.program[vm.ip]

    if cell.kind == Builtin:
      # this case may not occur
      echo "program token $1 is :builtin" % [cell.repr]
      cell.builtin(vm)

    elif cell.kind == Name:
      var word = vm.findWord(cell.name)
      if word == nil:
        raise newException(Exception, "unknown word: `$1`" % [cell.name])
      elif word.kind != Builtin:
        raise newException(Exception, "it's not a builtin: `$1`" % [cell.name])
      else:
        word.builtin(vm)

    else:
      vm.dstack.add(cell)

    vm.ip += 1


type
  Token = ref object
    kind: Kind
    buf: string
    wip: bool

proc parseProgram*(stream: Stream): seq[Cell] =
  var
    program: seq[Cell] = @[]
    stack: seq[Token]
    state = Initial

  while not stream.atEnd():
    echo state
    echo stream.peekChar()

    if state == Initial:

      if stream.peekChar() in " \n":
        discard stream.readChar()

      elif stream.peekChar.isDigit() or stream.peekChar() == '-':
        state = Number
        stack.add(Token(kind: Number, buf: ""))
        stack[stack.len-1].buf.add(stream.readChar())

      elif stream.peekChar() == '[':
        state = List

      else:
        state = Name
        stack.add(Token(kind: Name, buf: ""))
        stack[stack.len-1].buf.add(stream.readChar())

    elif state == Name:
      if stream.peekChar() in " \n":
        discard stream.readChar()
        program.add(Cell(kind: Name, name: stack[stack.len-1].buf))
        discard stack.pop()

      else:
        stack[stack.len-1].buf.add(stream.readChar())

    elif state == Number:
      if stream.peekChar() in " \n":
        discard stream.readChar()
        program.add(Cell(kind: Number, number: parseFloat(stack[stack.len-1].buf)))
        discard stack.pop()

      elif stream.peekChar().isDigit():
        stack[stack.len-1].buf.add(stream.readChar())

      elif '.' notin stack[stack.len-1].buf and stream.peekChar() == '.':
        stack[stack.len-1].buf.add(stream.readChar())

      else:
        state = Name
        stack[stack.len-1].buf.add(stream.readChar())

  echo "last!!!!"

  program


proc initVM*(vm: VM) =
  vm.addWord(".s", Cell(kind: Builtin, builtin: vmPrintStack))
