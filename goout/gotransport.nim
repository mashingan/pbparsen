#? stdtmpl | standard
#
#import tables, os, strutils
#import times
#import sqlgen
#
#import ../types, ../utils
#proc writeGoTransport*(info: GrpcServiceInfo, pb: Proto): string =
#result = ""
/*
#var cpright = $copyright()
$cpright
*/

package transport

import (
        "context"
#var infoname = info.name.toSnakeCase
#var servname = infoname & "_service"
#var servpath = (info.basepath / servname).unixSep
#var pbpath = (servpath / "pb" / infoname).unixSep
#var endpath = (info.basepath / "endpoints").unixSep
#var modelpath = (info.basepath / "model").unixSep
        pb "$pbpath"
        //$infoname "$servpath"
        endpoints "$endpath"
        model "$modelpath"

        grpctransport "github.com/go-kit/kit/transport/grpc"
        "google.golang.org/grpc/codes"
        "google.golang.org/grpc/status"
)

#var services = newseq[ServiceProto]()
#for svc in pb.services.values:
#  services.add svc
#end for
#var servgrpcserv = services[0].name.toPascalCase & "GRPCServer"
type $servgrpcserv struct {
    #for service in services:
    #    for rpc in service.rpcs.values:
        #var rpcname = rpc.name.toPascalCase & "GRPC"
        $rpcname grpctransport.Handler
        #end for
    #end for
}

##var servend = "endpoints." & info.name.toPascalCase & "Endpoints"
#var servend = "endpoints." & services[0].name.toPascalCase & "Endpoints"
#var pbserv = "pb." & services[0].name.toPascalCase & "Server"
func New$servgrpcserv(_ context.Context, endpoint $servend) $pbserv {
        return &$servgrpcserv {
        #for svc in services:
            #for rpc in svc.rpcs.values:
            #var rpcname = rpc.name.toPascalCase
            #var rpcgrpc = rpcname & "GRPC"
            #var endpoint = "endpoint." & rpcname & "Endpoint"
            #var request = "model.DecodeGRPC" & rpc.request.`type`.mappingKind
            #var response = "model.EncodeGRPC" & rpc.response.`type`.mappingKind
                $rpcgrpc: grpctransport.NewServer(
                        $endpoint,
                        $request,
                        $response,
                ),
            #end for
        #end for
        }
}

#for svc in services:
    #for rpc in svc.rpcs.values:
    #var request = "pb." & rpc.request.`type`.mappingKind
    #var response = "pb." & rpc.response.`type`.mappingKind
    #var rpcname = rpc.name.toPascalCase
    #var rpcgrpc = rpc.name.toPascalCase & "GRPC"
    #var servgrpc = rpcgrpc & ".ServeGRPC(ctx, argin)"
func (s *$servgrpcserv) $rpcname(ctx context.Context, argin *$request) (*$response, error) {
        _, res, err := s.$servgrpc
        if err != nil {
                _ = status.New(codes.Unknown, err.Error())

                errRep := &$response{}
                return errRep, err
        }
        return res.(*$response), nil
}
    #end for
#end for
