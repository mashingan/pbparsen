#? stdtmpl(emit="f.write") | standard
#
#import tables
#
#import ../types, ../utils
#
#proc writeViewModel*(f: File, msg: MessageProto) =
package viewmodel

type $msg.name.normalize struct {
#for field in msg.fields.values:
        $field.goProtoField
#end for
}
