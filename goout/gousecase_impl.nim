#? stdtmpl(emit="f.write") | standard
#
#import tables, strutils, os, sequtils
#
#import sqlgen
#
#import ../types, ../utils
#
#proc writeUsecaseImpl*(f: File, info: GrpcServiceInfo, pb: Proto, tbls: seq[SqlTable]) =
/*
#var cpright = $copyright()
$cpright
*/

#var vmpath = (info.svcpath / "view_model").unixSep
#var repopath = (info.svcpath / "repository").unixSep
package usecase

import (
        vm "$vmpath"
        $info.name.toSnakeCase "$info.svcpath.unixSep"
        "$repopath"
)

#for svc in pb.services.values:
#var usecasename = svc.name & "Usecase"
#var ucimpl = usecasename & "Impl"
type $ucimpl struct {
        #for tbl in tbls:
        #var reporepo = "repository." & tbl.name.toPascalCase & "Repository"
        $tbl.name.toCamelCase $reporepo
        #end for
}

#var tblstr = newseq[string]()
#var tblnames = newseq[string]()
        #for tbl in tbls:
                #tblnames.add tbl.name
                #var reporepo = "repository." & tbl.name.toPascalCase & "Repository"
                #tblstr.add tbl.name.toCamelCase & " " & reporepo
        #end for
#var elm = tblnames.map(toCamelCase).join(", ")
#var arities = tblstr.join(", ")
func New$usecasename($arities) $usecasename {
        return &$ucimpl{$elm}
}

        #for rpc in svc.rpcs.values:
func (s *$ucimpl) $rpc.goRpc {
        #var errnotimpl = info.name.toSnakeCase & ".ErrNotImplemented"
        return nil, $errnotimpl
}
        #end for
#end for
