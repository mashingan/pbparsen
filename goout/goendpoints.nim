#? stdtmpl | standard
#
#import tables, os, strutils
#import sqlgen
#
#import ../types, ../utils
#proc writeGoEndpoints*(info: GrpcServiceInfo, pb: Proto): string =
#result = ""
/*
#var cpright = $copyright()
$cpright
*/

package endpoints

#var servname = info.name.toPascalCase
#var servpath = info.name & "_service"
#var vmpath = (info.basepath / servpath / "view_model").unixSep
#var svcpath = (info.basepath / "service").unixSep
import (
        "context"

        vm "$vmpath"
        service "$svcpath"

        endpoint "github.com/go-kit/kit/endpoint"
)

#var servend = servname & "Endpoints"
type $servend struct {
#for s in pb.services.values:
    #for rpc in s.rpcs.values:
    #var rpcend = rpc.name.toPascalCase & "Endpoint"
        $rpcend endpoint.Endpoint
    #end for
#end for
}

#for s in pb.services.values:
    #for rpc in s.rpcs.values:
    #var rpcend = rpc.name.toPascalCase & "Endpoint"
    #var servsvc = "service." & servname & "Service"
    #var rpccall = "s." & rpc.name & "(ctx, req)"
func Make$rpcend(s $servsvc) endpoint.Endpoint {
        return func(ctx context.Context, request interface{}) (interface{}, error) {
              req := request.($rpc.request.mapKind)
              r, err := $rpccall
              if err != nil {
                      return nil, err
              }
              return r, nil
        }
}

func (e $rpcend) $rpc.name(ctx context.Context, argin *$rpc.request.mapKind) (*$rpc.response.mapKind, error) {
        res, err := e.$rpcend(ctx, argin)
        if err != nil {
                return nil, err
        }
        r := res.($rpc.response.mapKind)
        return &r, nil
}
    #end for
#end for
