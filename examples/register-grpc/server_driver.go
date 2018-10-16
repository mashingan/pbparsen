/*
Generated with pbparsen (c) Rahmatullah
@ 13-10-2018T16:08:35+07:00
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

	"github.com/jinzhu/gorm"
	_ "github.com/jinzhu/gorm/dialects/sqlite"

	cfg "github.com/mashingan/register/config"
	endpoint "github.com/mashingan/register/endpoints"
	entity "github.com/mashingan/register/register_service/entity"
	pb "github.com/mashingan/register/register_service/pb/register"
	repository "github.com/mashingan/register/register_service/repository"
	usecase "github.com/mashingan/register/register_service/usecase"
	service "github.com/mashingan/register/service"
	transport "github.com/mashingan/register/transport"
)

var config cfg.Config

func init() {
	config = cfg.NewViperConfig()
	if config.GetBool("debug") {
		fmt.Println("Service RUN on DEBUG mode")
	}
	log.SetFlags(log.LstdFlags | log.Lshortfile)
}

func migrate(db *gorm.DB) {
	db.AutoMigrate(&entity.Users{})
	db.AutoMigrate(&entity.Emails{})
}

func main() {

	val := url.Values{}
	val.Add("parseTime", "1")
	val.Add("loc", "Asia/Jakarta")

	db, err := gorm.Open("sqlite3", "register_grpc.db")
	migrate(db)
	defer db.Close()

	if err != nil {
		log.Fatal(err.Error())
	}

	if err != nil && config.GetBool("debug") {
		fmt.Println(err)
	}

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

	repoUsers := repository.NewUsersRepository(db, logger)
	repoEmails := repository.NewEmailsRepository(db, logger)
	// implement your own usecase
	ucvar := usecase.NewRegisterUsecase(repoUsers, repoEmails)

	errchan := make(chan error)
	var serviceRegister service.RegisterService
	// change the `usecaseVar` to use usecase variable
	serviceRegister = service.NewRegisterServiceImpl(ucvar, logger)
	endpointsRegister := endpoint.RegisterEndpoints{
		GetEmailByNameEndpoint: endpoint.MakeGetEmailByNameEndpoint(serviceRegister),
		DeleteUserEndpoint:     endpoint.MakeDeleteUserEndpoint(serviceRegister),
		GetUserByEmailEndpoint: endpoint.MakeGetUserByEmailEndpoint(serviceRegister),
		ModifyEmailEndpoint:    endpoint.MakeModifyEmailEndpoint(serviceRegister),
		RegisterEndpoint:       endpoint.MakeRegisterEndpoint(serviceRegister),
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
		handlerRegister := transport.NewRegisterGRPCServer(ctx, endpointsRegister)
		grpcServeRegister := grpc.NewServer()
		pb.RegisterRegisterServer(grpcServeRegister, handlerRegister)
		errchan <- grpcServeRegister.Serve(listener)
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
