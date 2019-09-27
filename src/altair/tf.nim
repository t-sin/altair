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

  str

proc vmPrintStack(vm: VM) =
  stdout.write "["
  for idx in 0..<vm.dstack.len:
    stdout.write reprCell(vm.dstack[idx])
    if idx != vm.dstack.len - 1:
      stdout.write " "
  echo "]"

proc vmAdd(vm: VM) =
  var
    a = vm.dstack.pop()
    b = vm.dstack.pop()
  vm.dstack.add(Cell(kind: Number, number: b.number + a.number))

proc vmSub(vm: VM) =
  var
    a = vm.dstack.pop()
    b = vm.dstack.pop()
  vm.dstack.add(Cell(kind: Number, number: b.number - a.number))

proc vmMul(vm: VM) =
  var
    a = vm.dstack.pop()
    b = vm.dstack.pop()
  vm.dstack.add(Cell(kind: Number, number: b.number * a.number))

proc vmDiv(vm: VM) =
  var
    a = vm.dstack.pop()
    b = vm.dstack.pop()
  vm.dstack.add(Cell(kind: Number, number: b.number / a.number))

proc vmMod(vm: VM) =
  var
    a = vm.dstack.pop()
    b = vm.dstack.pop()
  vm.dstack.add(Cell(kind: Number, number: (b.number.int64 mod a.number.int64).float32))

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
    str: string
    list: seq[Cell]

proc top(stack: seq[Token]): Token =
  if stack.len > 0:
    stack[stack.len-1]
  else:
    Token(kind: Initial)


proc parseProgram*(stream: Stream): seq[Cell] =
  var
    program: seq[Cell] = @[]
    stack: seq[Token] = @[]

  proc append(cell: Cell) =
    if stack.top().kind == List:
      stack.top().list.add(cell)
    else:
      program.add(cell)

  proc dispatch() =
    if stream.peekChar() in " \n":
      discard stream.readChar()

    elif stream.peekChar.isDigit() or stream.peekChar() == '-':
      var token = Token(kind: Number, str: "")
      token.str.add(stream.readChar())
      stack.add(token)

    elif stream.peekChar() == '[':
      discard stream.readChar()
      var token = Token(kind: List, list: @[])
      stack.add(token)

    else:
      var token = Token(kind: Name, str: "")
      token.str.add(stream.readChar())
      stack.add(token)

  while not stream.atEnd():
    if stack.top().kind == Initial:
      dispatch()

    elif stack.top().kind == List:
      if stream.peekChar() == ']':
        discard stream.readChar()
        var
          token = stack.pop()
          cell = Cell(kind: List, list: token.list)
        append(cell)

      else:
        dispatch()

    elif stack.top().kind == Name:
      if stream.peekChar() in " \n":
        discard stream.readChar()
        var cell = Cell(kind: Name, name: stack.pop().str)
        append(cell)

      else:
        stack.top().str.add(stream.readChar())

    elif stack.top().kind == Number:
      if stream.peekChar() in " \n":
        discard stream.readChar()
        var cell = Cell(kind: Number, number: parseFloat(stack.pop().str))
        append(cell)

      elif stream.peekChar().isDigit():
        stack.top().str.add(stream.readChar())

      elif '.' notin stack.top().str and stream.peekChar() == '.':
        stack.top().str.add(stream.readChar())

      else:
        stack.top().str.add(stream.readChar())

  program


proc initVM*(vm: VM) =
  vm.addWord(".s", Cell(kind: Builtin, builtin: vmPrintStack))
  vm.addWord("+", Cell(kind: Builtin, builtin: vmAdd))
  vm.addWord("-", Cell(kind: Builtin, builtin: vmSub))
  vm.addWord("*", Cell(kind: Builtin, builtin: vmMul))
  vm.addWord("/", Cell(kind: Builtin, builtin: vmDiv))
  vm.addWord("%", Cell(kind: Builtin, builtin: vmMod))
