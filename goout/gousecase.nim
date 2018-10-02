#? stdtmpl(emit="f.write") | standard
#
#import tables
#
#import ../types, ../utils
#
#proc writeUseCase*(f: File, path: string, pb: Proto) =
package usecase

import (
        vm "$path"
)

#for svc in pb.services.values:
#var usecasename = svc.name & "Usecase"
type $usecasename interface {
        #for rpc in svc.rpcs.values:
        $rpc.goRpc
        #end for
#end for
}
