import sequtils
import streams
import strutils
import typetraits

import ug
import ev

type
  Kind* = enum
    Initial,
    Name, Number, List, ExList,
    UGen, Event, Envelope, Note,
    Builtin,

  Cell* = ref object
    kind*: Kind
    name*: string
    number*: float32
    ug*: UG
    env*: Env
    ev*: EV
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
    isREPL*: bool
    program*: seq[Cell]
    ip*: int
    dict*: Dict
    dstack*: seq[Cell]
    cstack*: seq[IP]
    ug*: UG
    ev*: seq[EV]

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
    str.add('(')
    for idx in 0..<cell.list.len:
      str.add(reprCell(cell.list[idx]))
      if idx != cell.list.len - 1:
        str.add(" ")
    str.add(')')
  elif cell.kind == UGen:
    str.add("$1:$2" % [cell.ug.type.name, cell.ug.addr.ptr.repr.split('\n')[0]])
  elif cell.kind == Note:
    str.add("%n$1:$2:$3" % [
      $(cell.list[0].name), $(cell.list[1].number.int), $(cell.list[2].number.int)])
  elif cell.kind == Envelope:
    str.add("$1:$2" % [cell.env.type.name, cell.env.addr.ptr.repr.split('\n')[0]])
  elif cell.kind == Event:
    str.add("$1:$2" % [cell.ev.type.name, cell.ev.addr.ptr.repr.split('\n')[0]])

  str

## I/O words

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

## Stack manupilation words

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
  vm.dstack.add(b)
  vm.dstack.add(a)
  vm.dstack.add(c)

proc vmDrop(vm: VM) =
  discard vm.dstack.pop()

proc vmIsStackEmpty(vm: VM) =
  if vm.dstack.len > 0:
    vm.dstack.add(Cell(kind: Number, number: -1))
  else:
    vm.dstack.add(Cell(kind: Number, number: 0))

## List mamupilation words

proc vmMakeList(vm: VM) =
  var
    list:seq[Cell] = @[]
    cell = Cell(kind: List, list: list)
  vm.dstack.add(cell)

proc vmAddList(vm: Vm) =
  var
    a = vm.dstack.pop()
    list = vm.dstack.pop()
  if list.kind != List:
    raise newException(Exception, "[append] $1 is not a list" % [list.kind.repr])

  list.list.add(a)
  vm.dstack.add(list)

proc vmClearList(vm: Vm) =
  var
    list = vm.dstack.pop()
  if list.kind != List:
    raise newException(Exception, "[clear] $1 is not a list" % [reprCell(list)])

  list.list = @[]

## Arithmatic words

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

## Runtime words

proc vmExecute(vm: VM) =
  var a = vm.dstack.pop()
  if a.kind != ExList:
    raise newException(Exception, "[exec] $1 is not a executable list" % [a.kind.repr])
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

## Unit generator words

proc vmUgSaw(vm: VM) =
  var
    freq = vm.dstack.pop()
    saw = Saw(freq: freq.number)
    cell = Cell(kind: UGen, ug: saw.UG)
  vm.dstack.add(cell)

proc vmUgSin(vm: VM) =
  var
    freq = vm.dstack.pop()
    sin = Sin(freq: freq.number)
    cell = Cell(kind: UGen, ug: sin.UG)
  vm.dstack.add(cell)

proc vmUgRnd(vm: VM) =
  var
    freq = vm.dstack.pop()
    rnd = Rnd(freq: freq.number)
    cell = Cell(kind: UGen, ug: rnd.UG)
  vm.dstack.add(cell)

proc vmUgMix(vm: VM) =
  var
    amp = vm.dstack.pop()
    sources = vm.dstack.pop()
    ugs: seq[UG] = @[]

  if amp.kind != Number:
    raise newException(Exception, "[mix] amp `$1` is not a number" % [amp.kind.repr])
  if sources.kind != List:
    raise newException(Exception, "[mix] sources `$1` is not a list" % [sources.kind.repr])
  for src in sources.list:
    if src.kind == UGen:
      ugs.add(src.ug)
    elif src.kind == Envelope:
      ugs.add(src.env)
    else:
      raise newException(Exception, "[mix] all elements of sources are not UGen")

  var
    mix = Mix(sources: ugs, amp: amp.number)
    cell = Cell(kind: UGen, ug: mix.UG)
  vm.dstack.add(cell)

proc vmUgMul(vm: VM) =
  var
    sources = vm.dstack.pop()
    allUG = true
    ugs: seq[UG] = @[]

  if sources.kind != List:
    raise newException(Exception, "[mul] sources `$1` is not a list" % [sources.kind.repr])
  for src in sources.list:
    if src.kind == UGen:
      ugs.add(src.ug)
    elif src.kind == Envelope:
      ugs.add(src.env)
    else:
      raise newException(Exception, "[mul] all elements of sources are not UGen")

  var
    mul = Mul(sources: ugs)
    cell = Cell(kind: UGen, ug: mul.UG)
  vm.dstack.add(cell)

proc vmSetUg(vm: VM) =
  var
    ug = vm.dstack.pop()
  vm.ug = ug.ug

## Event (sequencer) words

proc vmMakeEnv(vm: VM) =
  var
    r = vm.dstack.pop()
    s = vm.dstack.pop()
    d = vm.dstack.pop()
    a = vm.dstack.pop()

  for v in [a, d, s, r]:
    if v.kind != Number:
      raise newException(Exception, "[adsr] all a, d, s, r are not number")

  var
    env = Env(adsr: None, eplaced: 0, a: a.number, d: d.number, s: s.number, r: r.number)
  vm.dstack.add(Cell(kind: Envelope, env: env.Env))

proc vmEvRSeq(vm: VM) = # rhythm machine (without pitch)
  var
    len = vm.dstack.pop()
    env = vm.dstack.pop()
    osc = vm.dstack.pop()

  if osc.kind != UGen:
    raise newException(Exception, "[rseq] osc `$1` is not a ugen" % [osc.kind.repr])

  if env.kind != Envelope:
    raise newException(Exception, "[rseq] env `$1` is not an envelope" % [env.kind.repr])

  if len.kind != List:
    raise newException(Exception, "[rseq] len `$1` is not a list" % [len.kind.repr])

  var
    pat = notesToPos(120, len.list.map(proc (c: Cell): tuple[n: int, f: float] = (c.number.int(), 0.0)))
    sq = Seq(
      osc: osc.ug.Osc,
      env: env.env.Env,
      pat: pat)
    cell = Cell(kind: Event, ev: sq.EV)

  vm.dstack.add(cell)

proc noteFromCell(c: Cell): tuple[n: int, f: float] =
  var
    s = c.list[0].name
    freq = keyToFreq(s[1..<s.len], c.list[1].number.int)
    note = c.list[2].number.int
  (note, freq)

proc vmEvSeq(vm: VM) =
  var
    notes = vm.dstack.pop()
    env = vm.dstack.pop()
    osc = vm.dstack.pop()

  if osc.kind != UGen:
    raise newException(Exception, "[seq] osc `$1` is not a ugen" % [reprCell(osc)])

  if env.kind != Envelope:
    raise newException(Exception, "[seq] env `$1` is not an envelope" % [reprCell(env)])

  if notes.kind != List:
    raise newException(Exception, "[seq] notes `$1` is not a list" % [reprCell(notes)])

  for n in notes.list:
    if n.kind != Note:
      raise newException(Exception, "[seq] `$1` in notes is not a note" % [reprCell(n)])

  var
    pat = notesToPos(120, notes.list.map(noteFromCell))
    sq = Seq(
      osc: osc.ug.Osc,
      env: env.env.Env,
      pat: pat)
    cell = Cell(kind: Event, ev: sq.EV)

  vm.dstack.add(cell)

proc vmSetEv(vm: VM) =
  var
    ev = vm.dstack.pop()
    evseq: seq[EV]

  if ev.kind != List:
    raise newException(Exception, "[ev] `$1` is not a list" % [reprCell(ev)])

  for e in ev.list:
    if e.kind != Event:
      raise newException(Exception, "[ev] `$1` is not an event" % [reprCell(e)])
    else:
      evseq.add(e.ev)

  vm.ev = evseq

proc vmMakeNote(vm: VM) =
  var
    len = vm.dstack.pop()
    oct = vm.dstack.pop()
    key = vm.dstack.pop()
    list = vm.dstack.pop()
    note = Cell(kind: Note, list: @[key, oct, len])
  if key.kind != Name:
    raise newException(Exception, "[n] key `$1` is not a name" % [reprCell(key)])
  if oct.kind != Number:
    raise newException(Exception, "[n] osc `$1` is not a number" % [reprCell(oct)])
  if len.kind != Number:
    raise newException(Exception, "[n] len `$1` is not a number" % [reprCell(len)])
  if list.kind != List:
    raise newException(Exception, "[n] list `$1` is not a list" % [reprCell(list)])
  list.list.add(note)
  vm.dstack.add(list)

## procs for VM

proc makeVM*(): VM =
  var
    dict = Dict(prev: nil, name: "<tf/nil>", data: nil)
    vm = VM(program: @[], ip: 0, dict: dict, dstack: @[], isREPL: true)

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
      if cell.name.startsWith(':'):
        vm.dstack.add(cell)
      elif word == nil:
        raise newException(Exception, "unknown word: `$1`" % [cell.name])
      elif word.kind != Builtin:
        raise newException(Exception, "it's not a builtin: `$1`" % [cell.name])
      else:
        word.builtin(vm)

    else:
      vm.dstack.add(cell)

    vm.ip += 1

## parser

type
  Token = ref object
    kind: Kind
    str: string
    list: seq[Cell]

proc top(stack: seq[Token]): Token =
  if stack.len > 0:
    stack[stack.len-1]
  else:
    raise newException(Exception, "parsing stack is empty")


proc parseProgram*(stream: Stream): seq[Cell] =
  var
    program: seq[Cell] = @[]
    stack: seq[Token] = @[Token(kind: Initial)]

  proc append(cell: Cell) =
    if stack.top().kind in [List, ExList]:
      stack.top().list.add(cell)
    else:
      program.add(cell)

  proc dispatch() =
    if stream.peekChar() in " \n":
      discard stream.readChar()

    elif stream.peekChar() == '%':
      while stream.peekChar() != '\n':
        discard stream.readChar()
      discard stream.readChar()

    elif stream.peekChar.isDigit() or stream.peekChar() == '-':
      var token = Token(kind: Number, str: "")
      token.str.add(stream.readChar())
      stack.add(token)

    elif stream.peekChar() == '(':
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
      if stream.atEnd():
        raise newException(Exception, "unexpected EOF while parsing $1" % [stack.top().kind.repr])

      elif stream.peekChar() in " \n":
        discard stream.readChar()

      elif stream.peekChar() == ')':
        discard stream.readChar()
        var
          token = stack.pop()
          cell = Cell(kind: List, list: token.list)
        append(cell)

      else:
        dispatch()

    elif stack.top().kind == ExList:
      if stream.atEnd():
        raise newException(Exception, "unexpected EOF while parsing $1" % [stack.top().kind.repr])

      elif stream.peekChar() in " \n":
        discard stream.readChar()

      elif stream.peekChar() == '}':
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
        var
          token = stack.pop()
          cell: Cell
        if token.str == "-":
          cell = Cell(kind: Name, name: token.str)
        else:
          cell = Cell(kind: Number, number: parseFloat(token.str))
        append(cell)

      elif stream.peekChar() in " \n":
        discard stream.readChar()
        var
          token = stack.pop()
          cell: Cell
        if token.str == "-":
          cell = Cell(kind: Name, name: token.str)
        else:
          cell = Cell(kind: Number, number: parseFloat(token.str))
        append(cell)

      elif stream.peekChar().isDigit():
        stack.top().str.add(stream.readChar())

      elif '.' notin stack.top().str and stream.peekChar() == '.':
        stack.top().str.add(stream.readChar())

      else:
        stack.top().str.add(stream.readChar())

  while true:
    parse()
    if stream.atEnd():
      if stack.len == 1:
        break
      else:
        echo stack.repr()
        echo program.repr()
        echo stack.len()
        raise newException(Exception, "unexpected EOF")

  program

## for runtime environment

proc resetVM*(vm: VM) =
  vm.ip = 0
  vm.dstack = @[]
  vm.cstack = @[]

proc initVM*(vm: VM) =
  vm.addWord("swap", Cell(kind: Builtin, builtin: vmSwap))
  vm.addWord("dup", Cell(kind: Builtin, builtin: vmDuplicate))
  vm.addWord("over", Cell(kind: Builtin, builtin: vmOver))
  vm.addWord("rot", Cell(kind: Builtin, builtin: vmRotate))
  vm.addWord("drop", Cell(kind: Builtin, builtin: vmDrop))
  vm.addWord("empty?", Cell(kind: Builtin, builtin: vmIsStackEmpty))

  vm.addWord("()", Cell(kind: Builtin, builtin: vmMakeList))
  vm.addWord("append", Cell(kind: Builtin, builtin: vmAddList))
  vm.addWord("clear", Cell(kind: Builtin, builtin: vmClearList))

  vm.addWord("exec", Cell(kind: Builtin, builtin: vmExecute))
  vm.addWord("ifelse", Cell(kind: Builtin, builtin: vmIfElse))

  vm.addWord("+", Cell(kind: Builtin, builtin: vmAdd))
  vm.addWord("-", Cell(kind: Builtin, builtin: vmSub))
  vm.addWord("*", Cell(kind: Builtin, builtin: vmMul))
  vm.addWord("/", Cell(kind: Builtin, builtin: vmDiv))
  vm.addWord("%", Cell(kind: Builtin, builtin: vmMod))

  vm.addWord(".", Cell(kind: Builtin, builtin: vmPrint))
  vm.addWord(".s", Cell(kind: Builtin, builtin: vmPrintStack))

  vm.addWord("saw", Cell(kind: Builtin, builtin: vmUgSaw))
  vm.addWord("sin", Cell(kind: Builtin, builtin: vmUgSin))
  vm.addWord("rnd", Cell(kind: Builtin, builtin: vmUgRnd))
  vm.addWord("mix", Cell(kind: Builtin, builtin: vmUgMix))
  vm.addWord("mul", Cell(kind: Builtin, builtin: vmUgMul))
  vm.addWord("adsr", Cell(kind: Builtin, builtin: vmMakeEnv))

  vm.addWord("ug",  Cell(kind: Builtin, builtin: vmSetUg))

  vm.addWord("n", Cell(kind: Builtin, builtin: vmMakeNote))
  vm.addWord("rseq",  Cell(kind: Builtin, builtin: vmEvRSeq))
  vm.addWord("seq",  Cell(kind: Builtin, builtin: vmEvSeq))
  vm.addWord("ev", Cell(kind: Builtin, builtin: vmSetEv))
