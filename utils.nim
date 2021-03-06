import strutils, tables, strformat, sequtils, times, os, parsecfg

when NimMinor >= 19:
  import sugar
else:
  import future

import types
from sqlgen import toPascalCase

const
  primitiveTypes* = [
    "int32", "int64", "uint64", "uint32", "string", "sint32", "sint64",
    "fixed32", "fixed64", "bool", "char", "double", "float", "sfixed32",
    "sfixed64", "bytes"
  ]
  gomap* = [
    ("double", "float64"),
    ("float", "float32"),
    ("int32", "int32"),
    ("int64", "int64"),
    ("uint32", "uint32"),
    ("uint64", "uint64"),
    ("sint32", "int32"),
    ("sint64", "int64"),
    ("fixed32", "uint32"),
    ("fixed64", "fixed64"),
    ("sfixed32", "int32"),
    ("sfixed64", "int64"),
    ("bool", "bool"),
    ("string", "string"),
    ("bytes", "bytes")].toTable


proc toSnakeCase*(str: string): string =
  result = "" & str[0].toLowerAscii
  let uppercase = { 'A' .. 'Z' }
  for c in str[1..^1]:
    if c in uppercase:
      result &= '_' & c.toLowerAscii
    else:
      result &= c

proc `$`*(x: Expr): string =
  if x.isNil:
    return ""
  result = ""
  case x.kind
  of SingleLine:
    result = x.line
  of Bracket:
    result = [$x.`type`, x.name, "{"].join(" ") & '\n'
    result &= x.lines.join("\n").indent 2
    result &= "\n}"
  else:
    discard

proc `$`*(field: FieldProto): string =
  result = fmt"{field.kind} {field.name} = {$field.pos};"
  if field.repeated:
    result &= "repeated "

proc `$`*(msg: MessageProto): string =
  #result = fmt"message {msg.name} {\n"
  result = "message $# {\n" % [msg.name]
  var fields = newseq[FieldProto]()
  for field in msg.fields.values:
    fields.add field
  result &= indent(fields.join("\n"), 2) & "\n}"

proc `$`*(rpc: RpcProto): string =
  let
    reqstream = if rpc.request.stream: "stream " else: ""
    resstream = if rpc.response.stream: "stream " else: ""
  result = fmt"rpc {rpc.name}({reqstream}{rpc.request.`type`}) returns ({resstream}{rpc.response.`type`});"

proc `$`*(svc: ServiceProto): string =
  #result = fmt"service {svc.name} {\n"
  result = "service $# {\n" % [svc.name]
  var rpcs = newseq[RpcProto]()
  for rpc in svc.rpcs.values:
    rpcs.add rpc
  result &= indent(rpcs.join("\n"), 2) & "\n}"

proc `$`*(pb: Proto): string =
  #result = fmt"syntax = {pb.syntax}\n"
  result = "syntax = $#\n" % [pb.syntax]
  var svcs = newseq[ServiceProto]()
  for svc in pb.services.values: svcs.add svc
  var msgs = newseq[MessageProto]()
  for msg in pb.messages.values: msgs.add msg
  #result &= indent(svcs.join("\n"), 2) & "\n" &
    #indent(msgs.join("\n"), 2)
  result &= svcs.join("\n") & "\n" & msgs.join("\n")

proc isEnd*(x: Expr): bool = x.kind == End

converter toConstruct*(x: string): Construct = parseEnum[Construct](x)

template normalize*(str: string): string =
  str.replace('.', '_')

template mappingKind*(str: string, default = ""): string =
  if str in gomap: gomap[str]
  elif str.endsWith "Timestamp": "time.Time"
  elif str.endsWith "Any": "interface{}"
  elif default != "": default
  else: utils.normalize(str)

proc mapKind*(field: FieldProto): string =
  field.kind.mappingKind(field.kind.normalize)

proc mapKind*(ar: ArityService): string =
  ar.`type`.mappingKind("vm." & ar.`type`)

proc goRpc*(rpc: RpcProto): string =
  let
    reqarity = "x " & rpc.request.mapKind
    resarity = rpc.response.mapKind & ", error"

  result = fmt"""{rpc.name}({$reqarity}) (*{$resarity})"""

proc needtime*(msg: MessageProto): bool =
  for field in msg.fields.values:
    if field.kind.endsWith "Timestamp":
      return true

proc goProtoField*(field: FieldProto): string =
  let rept = if field.repeated: "[]" else: ""
  result = fmt"""{field.name.toPascalCase.normalize} {rept}{field.mapKind}"""

proc filename*(msg: MessageProto): string =
  result = msg.name.split('.').map(toSnakeCase).join("_")

proc serviceRpc*(rpc: RpcProto): string =
  let
    req = rpc.request
    res = rpc.response
  result = fmt"(ctx context.Context, in {req.mapKind})(*{res.mapKind}, error)"
template unixSep*(str: string): untyped = str.replace('\\', '/')

proc copyright*(): string =
  let currtime = format(now(), "dd-MM-yyyy'T'HH:mm:sszzz")
  result = fmt"""Generated with pbparsen (c) Rahmatullah
@ {currtime}"""

proc getConfigFilename(): string =
  result = ""
  echo fmt"Current directory {getCurrentDir()}"
  if paramCount() > 0:
    result = paramStr 1
  else:
    echo "no file argument provided, looking for first found .cfg file!"
    let currdir = getCurrentDir()
    for path in walkFiles("*.cfg"):
      echo fmt"using {path} config"
      result = path
      break

  if result == "":
    quit "Please provide config or any file with .cfg extension"

template `->`(cfg: Config, keyval: tuple[key, val: string]): untyped =
  cfg.getSectionValue(keyval[0], keyval[1])

template `=>`(cfg: Config, val: string): untyped =
  cfg -> ("sql", val)

proc getConfigCmd*(): (GrpcServiceInfo, string, string) =
  var
    fname = getConfigFilename()
    config = loadConfig fname
    gopath = config -> ("project", "gopath")

  if gopath == "":
    let goenv = getEnv("GOPATH")
    if goenv != "": gopath = goenv
    else: gopath = getHomeDir() / "go"
  let
    dbinfo = DbInfo(
      name: config => "name",
      sqltype: config => "type",
      host: config => "host",
      user: config => "user",
      pass: config => "pass",
      port: config => "port"
    )
    info = GrpcServiceInfo(
      name: config -> ("project", "name"),
      basepath: config -> ("project", "basepath"),
      gopath: gopath / "src",
      raven: config -> ("raven", "path"),
      db: dbinfo)
  result = (info, config -> ("sql", "filename"),
    config -> ("protobuf", "filename"))

proc funcLogError*(where: string, what = "err"): string =
  """level.Error(r.logger).Log("function", "$#", "Error", $#)""" %
    [where, what]

proc svcpath*(info: GrpcServiceInfo): string =
  result = info.basepath / (info.name & "_service")
