import strutils, streams, strformat, tables, sequtils
import os

import sugar

import types, utils
export types, utils

import goout/[gousecase, goviewmodel, goservice, gomodel]

proc isComment(s: Stream): (bool, bool) =
  try:
    let comment = s.peekStr 2
    if comment == "/*":
      result = (true, true)
      discard s.readStr 2
    elif comment == "//":
      result = (true, false)
      discard s.readStr 2
  except IOError:
    result = (false, false)

proc purgeComment(s: Stream, multiline: bool) =
  while not s.atEnd:
    let c = s.readChar
    if c == '\n' and not multiline:
      return
    if c == '*' and s.peekChar == '/':
      discard s.readChar
      return

proc purgeComment(s: Stream) =
  while not s.atEnd:
    let (iscomment, multiline) = s.isComment
    if iscomment: s.purgeComment multiline
    return

proc getExpr(s: Stream): Expr =
  var buff = ""
  while not s.atEnd:
    s.purgeComment
    let c = s.readChar
    if c in Newlines: buff &= ' '
    case c
    of ';':
      buff &= c
      return Expr(kind: SingleLine, line: buff.strip)
    of '}':
      return Expr(kind: End)
    of '{':
      let
        tokens = buff.splitWhitespace
        `type` = tokens[0].toConstruct
        name = tokens[1]
      var data = newseq[Expr]()
      var expr = s.getExpr
      while not expr.isEnd:
        data.add expr
        expr = s.getExpr
      return Expr(kind: Bracket, `type`:`type`, name:name, lines: data)
    else:
      buff &= c

proc skipWhitespaces(s: Stream) =
  while not s.atEnd:
    let c = s.peekChar
    if c notin Whitespace:
      return
    discard s.readChar

template readingParse(s: Stream, ch: char, inclusive = false): untyped =
  var buff = ""
  while not s.atEnd:
    case s.peekChar == ch
    of true:
      when inclusive: buff &= s.readChar
      break
    else:
      buff &= s.readChar
  buff

proc readUntil(s: Stream, ch: char): string =
  s.readingParse ch

proc readTo(s: Stream, ch: char): string =
  s.readingParse(ch, true)

proc readTo(s: Stream, str: string): string =
  result = ""
  while not s.atEnd:
    var buff = s.readUntil str[0]
    if s.peekStr(str.len) == str:
      result &= buff & s.readStr str.len
      break
    else:
      result &= buff

proc getArity(str: string): ArityService =
  let arity = str.splitWhitespace
  if "stream" in arity and arity.len > 1:
    result = ArityService(`type`: arity[1], stream: true)
  else:
    result = ArityService(`type`: arity[0])

proc parseRpc(strexpr: string): RpcProto =
  var s = newStringStream strexpr
  while not s.atEnd:
    let rpc = s.readStr 3
    if rpc != "rpc": return RpcProto()
    s.skipWhitespaces
    result.name = s.readUntil('(').strip
    let reqinfo = s.readTo(')').strip(chars = Whitespace + {'(', ')'})
    result.request = reqinfo.getArity

    discard s.readTo('(')
    let resinfo = s.readTo(')').strip(chars = Whitespace + {'(', ')'})
    result.response = resinfo.getArity
    break


proc parseService(expr: Expr): seq[ServiceProto] =
  var svc = ServiceProto(
    name: expr.name,
    rpcs: newTable[string, RpcProto]()
  )
  for expr in expr.lines:
    let rpc = expr.line.parseRpc
    svc.rpcs[rpc.name] = rpc
  #result[svc.name] = svc
  result.add svc

proc parseField(str: string): FieldProto =
  let
    keyval = str.split('=')
    info = keyval[0].strip().splitWhitespace().mapIt it.strip
    pos = keyval[1].strip(chars = Whitespace + {';'})
  result.pos = parseInt pos
  if "repeated" in info:
    result.repeated = true
    if info.len >= 3:
      result.kind = info[1]
      result.name = info[2]
  elif info.len >= 2:
    result.kind = info[0]
    result.name = info[1]

proc parseMessage(expr: Expr): seq[MessageProto] =
  var msg = MessageProto(
    name: expr.name,
    fields: newTable[string, FieldProto]()
  )
  for fld in expr.lines:
    case fld.kind
    of SingleLine:
      let field = fld.line.parseField
      msg.fields[field.name] = field
      result.add msg
    of Bracket:
      #[
      for msg in fld.parseMessage expr.name:
        result.add msg
        ]#
      var msgs = fld.parseMessage
      for msg in msgs.mitems:
        msg.name = [expr.name, msg.name].join(".")
        result.add msg
    else:
      discard


proc proto(exprs: varargs[Expr]): Proto =
  var services = newTable[string, ServiceProto]()
  var messages = newTable[string, MessageProto]()
  for expr in exprs:
    case expr.kind
    of SingleLine:
      if expr.line.startsWith "syntax":
        result.syntax = expr.line.split("=")[1]
        continue

    of Bracket:
      case expr.`type`
      of Service:
        let svcs = expr.parseService
        for svc in svcs:
          services[svc.name] = svc
      of Message:
        let msgs = expr.parseMessage
        for msg in msgs:
          messages[msg.name] = msg
      of Enum:
        # to be added later
        discard
      of Rpc:
        # to be added later
        discard
      of OneOf:
        # to be added later
        discard
      else:
        discard
    else:
      discard
  result.services = services
  result.messages = messages

proc proto(pb: var Proto, expr: Expr) =
  var prot = expr.proto
  if prot.syntax != "":
    pb.syntax = prot.syntax
  for name, svc in prot.services:
    pb.services[name] = svc
  for name, msg in prot.messages:
    pb.messages[name] = msg

proc `==`*(a, b: MessageProto): bool =
  a.name == b.name

proc normalizeFieldType(msg: var MessageProto,
    msgs: TableRef[string, MessageProto]) =
  for field in msg.fields.values:
    if field.kind in primitiveTypes:
      continue
    for othermsg in msgs.values:
      if msg == othermsg: continue
      if othermsg.name.endsWith(field.kind) and othermsg.name.find('.') != -1:
        let oldtype = field.kind
        var fld = msg.fields[field.name]
        fld.kind = othermsg.name
        msg.fields[field.name] = fld

proc initPb*(): Proto =
  Proto(
    services: newTable[string, ServiceProto](),
    messages: newTable[string, MessageProto]()
  )

proc normalizeFieldType*(pb: var Proto) =
  for _, msg in pb.messages.mpairs:
    msg.normalizeFieldType pb.messages

proc parsePb*(fname: string): Proto =
  result = initPb()
  var fs = newFileStream fname
  while not fs.atEnd:
    let expr = fs.getExpr
    if not expr.isNil:
      result.proto expr

  result.normalizeFieldType

when isMainModule:
  template unixSep(str: string): untyped =
    str.replace('\\', '/')

  proc main =
    if paramCount() < 1:
      quit "Please provide protobuf file"

    var pb = paramStr(1).parsePb
    echo pb

    let gopath = "GOPATH".getenv((getHomeDir() / "go").unixSep)
    let info = GrpcServiceInfo(
      name: "payment_service",
      basepath: "paxelit/payment",
      gopath: gopath)
    echo("===========")
    stdout.writeUseCase((gopath / info.basepath / info.name / "viewmodel")
      .unixSep, pb)
    for msg in pb.messages.values:
      echo msg.filename
      stdout.writeViewModel msg

    echo("===========")
    stdout.write writeGoService(info, pb)
    echo("=============")
    stdout.write writeGoModel(info, pb)
    echo gopath

  main()
