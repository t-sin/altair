import streams
import strutils


type
  Kind* = enum
    Name, Number, List, ExList, Builtin, Initial

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

  IP = ref object
    ip: int
    program: seq[Cell]

  VM* = ref object
    program*: seq[Cell]
    ip*: int
    dict*: Dict
    dstack*: seq[Cell]
    cstack*: seq[IP]

proc reprCell*(cell: Cell): string =
  var str: string
  if cell.kind == Name:
    str = cell.name
  elif cell.kind == Number:
    str = cell.number.repr
  elif cell.kind == Builtin:
    str = "proc;$1" % [cell.builtin.addr.repr]
  elif cell.kind == ExList:
    str.add('{')
    for idx in 0..<cell.list.len:
      str.add(reprCell(cell.list[idx]))
      if idx != cell.list.len - 1:
        str.add(" ")
    str.add('}')
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

proc vmPrint(vm: VM) =
  var a = vm.dstack.pop()
  echo reprCell(a)

proc vmSwap(vm: VM) =
  var
    a = vm.dstack.pop()
    b = vm.dstack.pop()
  vm.dstack.add(a)
  vm.dstack.add(b)

proc vmDuplicate(vm: VM) =
  var
    a = vm.dstack.pop()
  vm.dstack.add(a)
  vm.dstack.add(a)

proc vmOver(vm: VM) =
  var
    a = vm.dstack.pop()
    b = vm.dstack.pop()
  vm.dstack.add(b)
  vm.dstack.add(a)
  vm.dstack.add(b)

proc vmRotate(vm: VM) =
  var
    a = vm.dstack.pop()
    b = vm.dstack.pop()
    c = vm.dstack.pop()
  vm.dstack.add(a)
  vm.dstack.add(b)
  vm.dstack.add(c)

proc vmDrop(vm: VM) =
  discard vm.dstack.pop()

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

proc vmExecute(vm: VM) =
  var a = vm.dstack.pop()
  if a.kind != ExList:
    raise newException(Exception, "$1 is not a executable list" % [a.kind.repr])
  vm.cstack.add(IP(ip: vm.ip, program: vm.program))
  vm.ip = -1
  vm.program = a.list

proc vmIfElse(vm: VM) =
  var
    elseExlist = vm.dstack.pop()
    thenExlist = vm.dstack.pop()
    cond = vm.dstack.pop()
  if cond.kind == Number and cond.number == 0.0:
    vm.dstack.add(elseExlist)
    vm.ip += 1
    vm.vmExecute()
  else:
    vm.ip += 1
    vm.dstack.add(thenExlist)
    vm.vmExecute()

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
  while true:
    if vm.ip < 0 or vm.ip >= vm.program.len:
      if vm.cstack.len() == 0:
        break
      else:
        var ip = vm.cstack.pop()
        vm.ip = ip.ip
        vm.program = ip.program
        vm.ip += 1
        continue

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
    if stack.top().kind in [List, ExList]:
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

    elif stream.peekChar() == '{':
      discard stream.readChar()
      var token = Token(kind: ExList, list: @[])
      stack.add(token)

    else:
      var token = Token(kind: Name, str: "")
      token.str.add(stream.readChar())
      stack.add(token)

  proc parse() =
    if stack.top().kind == Initial:
      dispatch()

    elif stack.top().kind == List:
      if stream.peekChar() == ']':
        discard stream.readChar()
        var
          token = stack.pop()
          cell = Cell(kind: List, list: token.list)
        append(cell)

    elif stack.top().kind == ExList:
      if stream.peekChar() == '}':
        discard stream.readChar()
        var
          token = stack.pop()
          cell = Cell(kind: ExList, list: token.list)
        append(cell)

      else:
        dispatch()

    elif stack.top().kind == Name:
      if stream.atEnd():
        var cell = Cell(kind: Name, name: stack.pop().str)
        append(cell)

      elif stream.peekChar() in " \n":
        discard stream.readChar()
        var cell = Cell(kind: Name, name: stack.pop().str)
        append(cell)

      else:
        stack.top().str.add(stream.readChar())

    elif stack.top().kind == Number:
      if stream.atEnd():
        var cell = Cell(kind: Number, number: parseFloat(stack.pop().str))
        append(cell)

      elif stream.peekChar() in " \n":
        discard stream.readChar()
        var cell = Cell(kind: Number, number: parseFloat(stack.pop().str))
        append(cell)

      elif stream.peekChar().isDigit():
        stack.top().str.add(stream.readChar())

      elif '.' notin stack.top().str and stream.peekChar() == '.':
        stack.top().str.add(stream.readChar())

      else:
        stack.top().str.add(stream.readChar())

  while not stream.atEnd():
    parse()

  parse()
  program


proc initVM*(vm: VM) =
  vm.addWord("swap", Cell(kind: Builtin, builtin: vmSwap))
  vm.addWord("dup", Cell(kind: Builtin, builtin: vmDuplicate))
  vm.addWord("over", Cell(kind: Builtin, builtin: vmOver))
  vm.addWord("rot", Cell(kind: Builtin, builtin: vmRotate))
  vm.addWord("drop", Cell(kind: Builtin, builtin: vmDrop))

  vm.addWord("exec", Cell(kind: Builtin, builtin: vmExecute))
  vm.addWord("ifelse", Cell(kind: Builtin, builtin: vmIfElse))

  vm.addWord("+", Cell(kind: Builtin, builtin: vmAdd))
  vm.addWord("-", Cell(kind: Builtin, builtin: vmSub))
  vm.addWord("*", Cell(kind: Builtin, builtin: vmMul))
  vm.addWord("/", Cell(kind: Builtin, builtin: vmDiv))
  vm.addWord("%", Cell(kind: Builtin, builtin: vmMod))

  vm.addWord(".", Cell(kind: Builtin, builtin: vmPrint))
  vm.addWord(".s", Cell(kind: Builtin, builtin: vmPrintStack))
