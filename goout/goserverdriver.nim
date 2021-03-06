#? stdtmpl | standard
#
#import tables, os, strutils
#import sqlgen
#
#import ../types, ../utils
#
#proc writeGoServerDriver*(info: GrpcServiceInfo, pb: Proto, tbls: openarray[SqlTable]): string =
#result = ""
#var svcpath = info.svcpath
#var repopath = (svcpath / "repository").unixSep
#var ucpath = (svcpath / "usecase").unixSep
#var endpath = (info.basepath / "endpoints").unixSep
#var servicepath = (info.basepath / "service").unixSep
#var transportpath = (info.basepath / "transport").unixSep
#var pbpath = (svcpath / "pb" / info.name.toSnakeCase).unixSep
#var cfgpath = (info.basepath / "config").unixSep
#var hasraven: bool
#if info.raven == "":
#    hasraven = false
#else:
#    hasraven = true
#end if
#var notsqlite = info.db.sqltype != "sqlite"
#var hastable = tbls.len != 0
/*
#var cpright = $copyright()
$cpright
*/
package main

import (
        "context"
        "flag"
        "fmt"
        "log"
        "net"
        "net/url"
        "os"
        "os/signal"
        "syscall"

#if hasraven:
        "github.com/getsentry/raven.go"
#end if

        "google.golang.org/grpc"

        logging "github.com/go-kit/kit/log"
        level "github.com/go-kit/kit/log/level"

#if hastable:
        "github.com/jinzhu/gorm"
        #var dialect = "postgres"
        #if info.db.sqltype != "":
                #dialect = info.db.sqltype
        #end if
        #var dialectbuild = "github.com/jinzhu/gorm/dialects/" & dialect
        _ "$dialectbuild"

        repository "$repopath"
#end if
        usecase "$ucpath"
        endpoint "$endpath"
        service "$servicepath"
        transport "$transportpath"
        pb "$pbpath"
        cfg "$cfgpath"
)

var config cfg.Config
func init() {
        config = cfg.NewViperConfig()
        if config.GetBool("debug") {
                fmt.Println("Service RUN on DEBUG mode")
        }
        log.SetFlags(log.LstdFlags | log.Lshortfile)
#if hasraven:
        ravent.SetDSN(config.GetString("sentry"))
#end if
}

#if notsqlite:
func getDbAs(c cfg.Config, what string) string {
        return c.GetString("database." + what)
}

func getServConfig(c cfg.Config) (string, string, string, string, string) {
        return getDbAs(c, "host"), getDbAs(c, "port"), getDbAs(c, "user"),
                getDbAs(c, "pass"), getDbAs(c, "name")
}
#end if

func main() {
#if notsqlite and hastable:
        dbHost, dbPort, dbUser, dbPass, dbName := getServConfig(config)
#end if

        val := url.Values{}
        val.Add("parseTime", "1")
        val.Add("loc", "Asia/Jakarta")

#if hastable:
        #var connbuilder = '"' & info.db.name & '"'
        #var driversql = info.db.sqltype
        #if notsqlite:
                #connbuilder = "fmt.Sprintf(\"host=%s port=%s user=%s dbname=%s password=%s\", dbHost, dbPort, dbUser, dbName, dbPass)"
        #end if
        #if not notsqlite:
                #driversql &= '3'
        #end if
        db, err := gorm.Open("$driversql", $connbuilder)
        defer db.Close()

        if err != nil {
                log.Fatal(err.Error())
        }

        #if hasraven:
        raven.CaptureErrorAndWait(errors.New("custom error"), nil)
        #end if
        if err != nil && config.GetBool("debug") {
        #if hasraven:
                raven.CaptureErrorAndWait(err, nil)
        #end if
                fmt.Println(err)
        }
#end if

        logfile, err := os.OpenFile(config.GetString("logfile"), os.O_RDWR | os.O_CREATE | os.O_APPEND, 0666)
        if err != nil {
#if hasraven:
                raven.CaptureErrorAndWait(err, nil)
#end if
                panic(err)
        }
        defer logfile.Close()

        var logger logging.Logger
        {
                w := logging.NewSyncWriter(logfile)
                logger = logging.NewLogfmtLogger(w)
                logger = level.NewFilter(logger, level.AllowDebug())
                logger = logging.With(logger, "ts", logging.DefaultTimestampUTC)
                logger = logging.With(logger, "caller", logging.DefaultCaller)
        }

        gRPCAddr := flag.String("grpc", config.GetString("server.address"), "gRPC listen address")

        flag.Parse()
        ctx := context.Background()

#var repovars = newseq[string]()
#for tbl in tbls:
#var newrepo = "repository.New" & tbl.name.toPascalCase & "Repository(db, logger)"
#var tblnames = newseq[string]()
#var reponame = "repo" & tbl.name.toPascalCase
        #tblnames.add tbl.name
        $reponame := $newrepo
        #repovars.add reponame
#end for
        // implement your own usecase
##var newrepos = info.name.toPascalCase & "Usecase"
#var newrepoarities = repovars.join(", ")
        errchan := make(chan error)
#for svc in pb.services.values:
#var svcname = svc.name.toPascalCase & "Service"
#var newrepos = svc.name.toPascalCase & "Usecase"
#var svcvar = "service" & svc.name.toPascalCase
        ucvar := usecase.New$newrepos($newrepoarities)

        var $svcvar service.$svcname
#var svcimpl = "service.New" & svcname & "Impl"
        // change the `usecaseVar` to use usecase variable
        $svcvar = $svcimpl(ucvar, logger)
#var svcendpoint = svc.name.toPascalCase & "Endpoints"
        endpoints$svc.name.toPascalCase := endpoint.$svcendpoint{
    #for rpc in svc.rpcs.values:
    #var rpcendpoint = rpc.name.toPascalCase & "Endpoint"
                $rpcendpoint: endpoint.Make$rpcendpoint($svcvar),
    #end for
        }
        go func() {
                listener, err := net.Listen("tcp", *gRPCAddr)
                if err != nil {
                        level.Error(logger).Log(
                                "function", "main() go func()",
                                "Error", err,
                        )
#if hasraven:
                        raven.CaptureErrorAndWait(err, nil)
#end if
                        errchan <- err
                        return
                }
#var svcgrpcserv = svc.name.toPascalCase & "GRPCServer"
                handler$svc.name.toPascalCase := transport.New$svcgrpcserv(ctx, endpoints$svc.name.toPascalCase)
                grpcServe$svc.name.toPascalCase := grpc.NewServer()
#var svchandler = svc.name.toPascalCase & "Server"
                pb.Register$svchandler(grpcServe$svc.name.toPascalCase, handler$svc.name.toPascalCase)
#var grpcserv = svc.name.toPascalCase & ".Serve(listener)"
                errchan <- grpcServe$grpcserv
        }()
#end for
        
        for i := 0; i < 2; i++ {
                go func() {
                        c := make(chan os.Signal, 1)
                        signal.Notify(c, syscall.SIGINT, syscall.SIGTERM)
                        errchan <- fmt.Errorf("%s", <-c)
                }()
        }
        fmt.Println(<-errchan)
}
