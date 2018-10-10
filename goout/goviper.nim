#? stdtmpl | standard
#
#from sqlgen import toPascalCase
#import ../utils
#
#proc writeGoViper*(what: string): string =
#let methname = "Get" & what.toPascalCase
#result = ""
func (v *viperConfig) $methname(key string) $what {
        return viper.$methname(key)
}
