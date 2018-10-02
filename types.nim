import tables

type
  ExprKind* = enum
    SingleLine Bracket End

  Construct* = enum
    Service = "service"
    Message = "message"
    Enum = "enum"
    OneOf = "oneof"
    Rpc = "rpc"

  Expr* = ref object
    case kind*: ExprKind
    of SingleLine:
      line*: string
    of Bracket:
      `type`*: Construct
      name*: string
      lines*: seq[Expr]
    of End:
      nil

  FieldProto* = object
    name*: string
    kind*: string
    pos*: int
    repeated*: bool

  MessageProto* = object
    name*: string
    fields*: TableRef[string, FieldProto]

  ArityService* = object
    `type`*: string
    stream*: bool

  RpcProto* = object
    name*: string
    request*, response*: ArityService

  ServiceProto* = object
    name*: string
    rpcs*: TableRef[string, RpcProto]

  Proto* = object
    syntax*: string
    messages*: TableRef[string, MessageProto]
    services*: TableRef[string, ServiceProto]

  GrpcServiceInfo* = object
    name*: string
    basepath*: string
    gopath*: string
