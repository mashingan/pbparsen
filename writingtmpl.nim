proc writeGoEntity(fname: string, info: GrpcServiceInfo): seq[SqlTable] =
  let sqltables = fname.parseSql.parse.getTables
  let entitypath = (info.basepath / "dummy_service" / "entity").unixSep
  let fullbasepath = info.gopath / entitypath
  if not fullbasepath.existsDir:
    createDir fullbasepath

  let entityfname = fullbasepath / "entity.go"
  var entityfile = entityfname.open fmWrite

  entityfile.writeGoEntity(sqltables,
    needtime = sqltables.needtime, version = "0.1.0")
  echo fmt"written to {entityfname}"
  close entityfile
  result = sqltables

proc writeGoRepository(info: GrpcServiceInfo, sqltbls: seq[SqlTable],
    version: string) =
  #var repopath = (info.gopath / info.basepath / "repository").unixSep
  var repopath = (info.gopath / info.svcpath / "repository").unixSep
  if not repopath.dirExists:
    createDir repopath
  for sqltable in sqltbls:
    let fname = (repopath / (sqltable.name & ".go")).unixSep
    var f = open(fname, fmWrite)
    f.write gorepository(sqltable, info.name, info.svcpath.unixSep,
      version = version)
    echo fmt"written to {fname}"
    close f

proc fullbasepath(info: GrpcServiceInfo): string =
  result = info.gopath / info.basepath

template writingPrologue(info: GrpcServiceInfo, inner: bool, path: string, ident: untyped) =
  let
    svcpath {.inject.} = if inner: info.svcpath
                         else: info.basepath
    `ident` {.inject.} = svcpath / path
    fullpath {.inject.} = info.gopath / `ident`
  if not fullpath.dirExists:
    createDir fullpath

proc writeUsecaseWith(pb: Proto, info: GrpcServiceInfo) =
  writingPrologue(info, true, "usecase", usecasepath)

  let fname = (fullpath / "usecase.go").unixSep
  let f = open(fname, fmWrite)
  f.writeUsecase((svcpath / "vm").unixSep, pb)
  echo fmt"written to {fname}"
  close f

proc writeViewmodelWith(pb: Proto, info: GrpcServiceInfo) =
  info.writingPrologue(true, "view_model", vmpath)
  for msg in pb.messages.values:
    let fname = (fullpath / (msg.name.toSnakeCase & ".go")).unixSep
    let f = open(fname, fmWrite)
    f.writeViewModel msg
    echo fmt"written to {fname}"
    close f

template writingEpilogue(fname: string, op: untyped): untyped =
  let f = open(fname, fmWrite)
  #f.write `op`(info, pb)
  f.write `op`
  echo "written to ", fname
  close f

proc writeServiceWith(pb: Proto, info: GrpcServiceInfo) =
  info.writingPrologue(false, "service", servicepath)
  let fname = (fullpath / "service.go").unixSep
  #fname.writingEpilogue writeGoService
  fname.writingEpilogue writeGoService(info, pb)

proc writeModelWith(pb: Proto, info: GrpcServiceInfo) =
  info.writingPrologue(false, "model", modelpath)
  let fname = (fullpath / "model.go").unixSep
  #fname.writingEpilogue writeGoModel
  fname.writingEpilogue writeGoModel(info, pb)

proc writeEndpointsWith(pb: Proto, info: GrpcServiceInfo) =
  info.writingPrologue(false, "endpoints", endpath)
  let fname = (fullpath / "endpoint.go").unixSep
  #fname.writingEpilogue writeGoEndpoints
  fname.writingEpilogue writeGoEndpoints(info, pb)

proc writeTransportWith(pb: Proto, info: GrpcServiceInfo) =
  info.writingPrologue(false, "transport", transportpath)
  let fname = (fullpath / "transport.go").unixSep
  #fname.writingEpilogue writeGoTransport
  fname.writingEpilogue writeGoTransport(info, pb)

proc writeVarsWith(info: GrpcServiceInfo) =
  info.writingPrologue(true, "", varspath)
  let fname = fullpath / "vars.go"
  #[
  if not fullpath.dirExists:
    createDir fullpath
  let
    fname = fullpath / "vars.go"
    f = open(fname, fmWrite)
  f.write info.writeGoVars
  echo fmt"written to {fname}"
  close f
  ]#
  fname.writingEpilogue writeGoVars(info)

proc writeServerDriver(info: GrpcServiceInfo, pb: Proto, tbls: openarray[SqlTable]) =
  info.writingPrologue(false, "", mainpath)
  let fname = fullpath / "server_driver.go"
  #[
  var f = open(fname, fmWrite)
  f.write info.writeGoServerDriver(pb, tbls)
  echo fmt"written to {fname}"
  close f
  ]#
  fname.writingEpilogue writeGoServerDriver(info, pb, tbls)

proc writeConfig(info: GrpcServiceInfo) =
  #[
  let fullpath = info.gopath / info.basepath / "config"
  if not fullpath.dirExists:
    createDir fullpath
  let fname = fullpath / "config.go"
  var f = open(fname, fmWrite)
  f.write info.writeGoConfig
  echo fmt"written to {fname}"
  close f
  ]#
  info.writingPrologue(false, "config", cfgpath)
  let fname = fullpath / "config.go"
  fname.writingEpilogue writeGoConfig(info)
