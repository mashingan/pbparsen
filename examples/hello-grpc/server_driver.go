/*
Generated with pbparsen (c) Rahmatullah
@ 16-10-2018T11:35:57+07:00
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

	"google.golang.org/grpc"

	logging "github.com/go-kit/kit/log"
	level "github.com/go-kit/kit/log/level"

	cfg "github.com/mashingan/hello_grpc/config"
	endpoint "github.com/mashingan/hello_grpc/endpoints"
	pb "github.com/mashingan/hello_grpc/hello_grpc_service/pb/hello_grpc"
	usecase "github.com/mashingan/hello_grpc/hello_grpc_service/usecase"
	service "github.com/mashingan/hello_grpc/service"
	transport "github.com/mashingan/hello_grpc/transport"
)

var config cfg.Config

func init() {
	config = cfg.NewViperConfig()
	if config.GetBool("debug") {
		fmt.Println("Service RUN on DEBUG mode")
	}
	log.SetFlags(log.LstdFlags | log.Lshortfile)
}

func main() {

	val := url.Values{}
	val.Add("parseTime", "1")
	val.Add("loc", "Asia/Jakarta")

	logfile, err := os.OpenFile(config.GetString("logfile"), os.O_RDWR|os.O_CREATE|os.O_APPEND, 0666)
	if err != nil {
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

	// implement your own usecase
	errchan := make(chan error)
	ucvar := usecase.NewHelloUsecase()

	var serviceHello service.HelloService
	// change the `usecaseVar` to use usecase variable
	serviceHello = service.NewHelloServiceImpl(ucvar, logger)
	endpointsHello := endpoint.HelloEndpoints{
		EchoHelloEndpoint:  endpoint.MakeEchoHelloEndpoint(serviceHello),
		HelloWorldEndpoint: endpoint.MakeHelloWorldEndpoint(serviceHello),
	}
	go func() {
		listener, err := net.Listen("tcp", *gRPCAddr)
		if err != nil {
			level.Error(logger).Log(
				"function", "main() go func()",
				"Error", err,
			)
			errchan <- err
			return
		}
		handlerHello := transport.NewHelloGRPCServer(ctx, endpointsHello)
		grpcServeHello := grpc.NewServer()
		pb.RegisterHelloServer(grpcServeHello, handlerHello)
		errchan <- grpcServeHello.Serve(listener)
	}()

	for i := 0; i < 2; i++ {
		go func() {
			c := make(chan os.Signal, 1)
			signal.Notify(c, syscall.SIGINT, syscall.SIGTERM)
			errchan <- fmt.Errorf("%s", <-c)
		}()
	}
	fmt.Println(<-errchan)
}
