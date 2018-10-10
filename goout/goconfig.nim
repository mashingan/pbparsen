#? stdtmpl | standard
#
#import ../types, ../utils
#import goviper
#
#proc writeGoConfig*(info: GrpcServiceInfo): string =
#result = ""
#var hasraven = false
#if info.raven != "":
    #hasraven = true
#end if
/*
#var cpright = $copyright()
$cpright
*/
package config

import (
        "strings"

#if hasraven:
        "github.com/getsentry/raven-go"
#end if
        "github.com/spf13/viper"
)

type Config interface {
        GetString(key string) string
        GetInt(key string) int
        GetBool(key string) bool
        Init()
}

type viperConfig struct {}

func (v *viperConfig) Init() {
        viper.SetEnvPrefix("go-clean")
        viper.AutomaticEnv()

        replacer := strings.NewReplacer(".", "_")
        viper.SetEnvKeyReplacer(replacer)
        viper.SetConfigType("json")
        viper.SetConfigFile("config.json")
        err := viper.ReadInConfig()

        if err != nil {
#if hasraven:
                raven.CaptureErrorAndWait(err, nil)
#end if
                panic(err)
        }
}
#for what in ["string", "int", "bool"]:
$what.writeGoViper
#end for

func NewViperConfig() Config {
        v := &viperConfig{}
        v.Init()
        return v
}
