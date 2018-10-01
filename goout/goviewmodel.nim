#? stdtmpl(emit="f.write") | standard
#
#import tables
#
#import ../types, ../utils
#
#proc writeViewModel*(f: File, msg: MessageProto) =
package viewmodel

#if msg.needtime:
import (
        "time"
)
#end if

type $msg.name.normalize struct {
#for field in msg.fields.values:
        $field.goProtoField
#end for
}
