#? stdtmpl | standard
#
#import tables, os, strutils
#import times
#import sqlgen
#
#import ../types, ../utils
#proc writeGoTransport*(info: GrpcServiceInfo, pb: Proto): string =
#result = ""
##TODO: complete gotransport definition
#{.fatal: "incomplete implementation".}
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
        $servname "$servpath"
        endpoints "$endpath"
        model "$modelpath"

        grpctransport "github.com/go-kit/kit/transport/grpc"
        "google.golang.org/grpc/codes"
        "google.golang.org/grpc/status"
)

#var servgrpcserv = info.name.toPascalCase & "GRPCServer"
type $servgrpcserv struct {
    #for service in pb.services.values:
    #    for rpc in service.rpcs.values:
        #var rpcname = rpc.name.toPascalCase & "GRPC"
        $rpcname grpctransport.Handler
        #end for
    #end for
}

#var servend = "endpoints." & info.name.toPascalCase & "Endpoints"
#var services = newseq[ServiceProto]()
#for svc in pb.services.values:
#  services.add svc
#end for
#var pbserv = "pb." & services[0].name & "Server"
func New$servgrpcserv(_ context.Context, endpoint $servend) $pbserv {
        return &servgrpcserv {
        #for rpc in services:
        #var rpcname = rpc.name.toPascalCase & "GRPC"
                $rpcname: grpctransport.NewServer(
                        
                )
        #end for
        }
}
