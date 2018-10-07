proc writeGoEntity(fname: string, info: GrpcServiceInfo): seq[SqlTable] =
  let sqltables = fname.parseSql.parse.getTables
  let entitypath = info.basepath / "dummy_service" / "entity"
  if not entitypath.existsDir:
    createDir entitypath

  var entityfile: File
  let entityfname = entitypath / "entity.go"
  if entityfname.fileExists:
    entityfile = entityfname.open fmReadWrite
  else:
    entityfile = entityfname.open fmWrite

  entityfile.writeGoEntity(sqltables,
    needtime = sqltables.needtime, version = "0.1.0")
  close entityfile
  result = sqltables

proc writeGoRepository(sqltbls: seq[SqlTable], svcname, thepath,
    version: string) =
  var repopath = thepath / "repository"
  if not repopath.dirExists:
    createDir repopath
  for sqltable in sqltbls:
    var f = open(repopath / (sqltable.name & ".go"), fmWrite)
    f.write gorepository(sqltable, svcname, thepath, version = version)
    close f

proc svcpath(info: GrpcServiceInfo): string =
  result = info.basepath / (info.name & "_service")

template writingPrologue(info: GrpcServiceInfo, inner: bool, path: string, ident: untyped) =
  let
    svcpath {.inject.} = if inner: info.svcpath
                         else: info.basepath / info.name
    `ident` {.inject.} = svcpath / path
  if not `ident`.dirExists:
    createDir `ident`

proc writeUsecaseWith(pb: Proto, info: GrpcServiceInfo) =
  writingPrologue(info, true, "usecase", usecasepath)

  let f = open(usecasepath / "usecase.go", fmWrite)
  f.writeUsecase(svcpath / "vm", pb)
  close f

proc writeViewmodelWith(pb: Proto, info: GrpcServiceInfo) =
  info.writingPrologue(true, "vm", vmpath)
  for msg in pb.messages.values:
    let f = open(vmpath / (msg.name & ".go"), fmWrite)
    f.writeViewModel msg
    close f

proc writeServiceWith(pb: Proto, info: GrpcServiceInfo) =
  info.writingPrologue(false, "service", servicepath)
  let f = open(servicepath / "service.go", fmWrite)
  f.write writeGoService(info, pb)
  close f

proc writeModelWith(pb: Proto, info: GrpcServiceInfo) =
  info.writingPrologue(false, "model", modelpath)
  let f = open(modelpath / "model.go", fmWrite)
  f.write writeGoModel(info, pb)
  close f

proc writeEndpointsWith(pb: Proto, info: GrpcServiceInfo) =
  info.writingPrologue(false, "endpoints", endpath)
  let f = open(endpath / "endpoint.go", fmWrite)
  close f

proc writeTransportWith(pb: Proto, info: GrpcServiceInfo) =
  info.writingPrologue(false, "transport", transportpath)
  let f = open(transportpath / "transport.go", fmWrite)
  close f
