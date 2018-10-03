#? stdtmpl | standard
#
#import tables, os, strutils
#import sqlgen
#
#import ../types, ../utils
#
#proc writeGoService*(info: GrpcServiceInfo, pb: Proto): string =
#result = ""
#var infoserv = info.name & "_service"
#var servname = info.name.toPascalCase
#var servpath = (info.basepath / infoserv).replace('\\', '/')
#var vmpath = servpath & "/viewmodel"
#var ucpath = servpath & "/usecase"
/*
#var cpright = $copyright()
$cpright
*/
package service

import (
        "context"
        "fmt"
        "time"

        $infoserv "$servpath"
        vm "$vmpath"
        usecase "$ucpath"

        raven "github.com/getsentry/raven-go"
        "google.golang.org/grpc/metadata"
        level "github.com/go-kit/kit/log/level"
        logging "github.com/go-kit/kit/log"
)

#var servimpl = servname & "ServiceImpl"
#var servuc = servname & "Usecase"
type $servimpl struct {
        usecase usecase.$servuc
        logger logging.Logger
}

func New$servimpl(uc usecase.$servuc, logger logging.Logger) $servimpl {
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
                raven.CaptureErrorAndWait(err, nil)
                return nil, err
        }
        if a == nil {
#    var errnotfound = infoserv & ".ErrNotFoundError"
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
