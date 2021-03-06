#? stdtmpl | standard
#
#import tables, os, strutils
#import sqlgen
#
#import ../types, ../utils
#
#proc writeGoService*(info: GrpcServiceInfo, pb: Proto): string =
#result = ""
#var infoserv = info.name
#var servname = info.name.toPascalCase
#var services = newseq[ServiceProto]()
#for svc in pb.services.values:
    #services.add svc
#end for
#servname = services[0].name.toPascalCase
#var ucname = services[0].name.toPascalCase & "Usecase"
#var servpath = info.svcpath.unixSep
#var vmpath = servpath & "/view_model"
#var ucpath = servpath & "/usecase"
/*
#var cpright = $copyright()
$cpright
*/
package service

import (
        "context"
        "time"

        $infoserv "$servpath"
        vm "$vmpath"
        usecase "$ucpath"

#if info.raven != "":
        raven "github.com/getsentry/raven-go"
#end if
        "google.golang.org/grpc/metadata"
        level "github.com/go-kit/kit/log/level"
        logging "github.com/go-kit/kit/log"
)

#var svcname = servname & "Service"
type $svcname interface {
#for svc in pb.services.values:
    #for rpc in svc.rpcs.values:
        $rpc.name.toPascalCase $rpc.serviceRpc
    #end for
#end for
}

#var servimpl = servname & "ServiceImpl"
#var servuc = servname & "Usecase"
type $servimpl struct {
        usecase usecase.$ucname
        logger logging.Logger
}

func New$servimpl(uc usecase.$ucname, logger logging.Logger) $servimpl {
        return $servimpl{uc, logger}
}

#for svc in pb.services.values:
#  for rpc in svc.rpcs.values:
#  var rpcname = rpc.name.toPascalCase
func (s $servimpl) $rpcname $rpc.serviceRpc {
        level.Info(s.logger).Log("function", "$servimpl $rpcname", "result", "Entry")
        md, _ := metadata.FromIncomingContext(ctx)
        token := md["token"]

        a, err := s.usecase.$rpcname(in)
        if err != nil {
                level.Error(s.logger).Log("function", "$servimpl $rpcname", "Error", err)
                #if info.raven != "":
                raven.CaptureErrorAndWait(err, nil)
                #end if
                return nil, err
        }
        if a == nil {
#    var errnotfound = infoserv & ".ErrNotFound"
                return nil, $errnotfound
        }
        defer func(begin time.Time) {
                level.Debug(s.logger).Log(
                        "token", token[0],
                        "function", "$servimpl $rpcname",
                        "result", a,
                        "took", time.Since(begin),
                )
        }(time.Now())
        level.Info(s.logger).Log("function", "$servimpl $rpcname", "result", "Exit")
        return a, nil
}
#  end for
#end for
