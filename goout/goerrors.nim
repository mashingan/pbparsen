#? stdtmpl | standard
#
#import ../types
#
#proc writeGoVars*(info: GrpcServiceInfo): string =
#result = ""
package $info.name

import "errors"

var (
        ErrInternalServer = errors.New("Internal server error")
        ErrNotFound = errors.New("Not found")
        ErrConflict = errors.New("Already exists")
)

var (
        InternalServerError = "Internal server error"
        StatusUnknown = "Uknown"
        SuccessCodeType = "OK"
        BaseTypeUrl = "paxel.co/"
        SaveSuccess = "Save success"
        GetSuccess = "Get success"
        UpdateSuccess = "Update success"
        DeleteSuccess = "Delete success"
)
