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
type $svc.name interface {
        #for rpc in svc.rpcs.values:
        $rpc.goRpc
        #end for
#end for
}
