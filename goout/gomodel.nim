#? stdtmpl | standard
#
#import tables, os, strutils
#import sqlgen
#
#import ../types, ../utils
#proc writeGoModel*(info: GrpcServiceInfo, pb: Proto): string =
#result = ""
#var servname = info.name.toSnakeCase
#var servpath = (info.basepath / info.name.toSnakeCase).replace('\\', '/')
#var vmpath = servpath & "/viewmodel"
#var pbpath = servpath & "/usecase"
package model

import (
        "context"
        "log"
        "time"

        $servname "$servpath"
        vm "$vmpath"
        pb "$pbpath"

        proto "github.com/golang/protobuf/proto"
        any "github.com/golang/protobuf/ptypes/any"
        google_protobuf "github.com/golang/protobuf/ptypes/timestamp"
)

#for msg in pb.messages.values:
    #var msgname = utils.normalize(msg.name.toPascalCase)
func EncodeGRPC$msgname(_ context.Context, r interface{}) (interface{}, error) {
        req := r.(vm.$msgname)
        return &pb.$msgname {
    #for field in msg.fields.values:
    #    var fldname = field.name.toPascalCase
                $fldname: req.$fldname,
    #end for
        }, nil
}

func DecodeGRPC$msgname(_ context.Context, r interface{}) (interface{}, error) {
        req := r.(*pb.$msgname)
        return vm.$msgname {
    #for field in msg.fields.values:
    #    var fldname = field.name.toPascalCase
                $fldname: req.$fldname,
    #end for
        }, nil
}
#end for
