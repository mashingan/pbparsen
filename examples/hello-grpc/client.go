package main

import (
	"context"
	"flag"
	"fmt"

	_ "github.com/golang/protobuf/proto"
	_ "github.com/golang/protobuf/ptypes"
	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"

	pb "github.com/mashingan/hello_grpc/hello_grpc_service/pb/hello_grpc"
)

func main() {
	conn, err := grpc.Dial("localhost:8094", grpc.WithInsecure())

	fs := flag.NewFlagSet("", flag.ExitOnError)

	accessToken := fs.String(
		"grpc.token",
		"eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1Mzg0NjIzOTMsImp0aSI6ImM1a2RobGRpZTB2and5Mm5vNzg1c2hxdG9rM3Y2dGZrIn0.F8H1Sdr--tehLKOxSpZSBqu1ZgzMZsQOd11sQMqeET9MGnshkbtVF-HcDZ9y5CGLvzmA6KmV9U8TJ28NiCJCJg",
		"JWT used to gRPC calls")
	if err != nil {
		fmt.Println("Unexpected error", err)
	}

	defer conn.Close()
	client := pb.NewHelloClient(conn)

	md := metadata.Pairs("token", *accessToken)
	ctx := context.Background()
	ctx = metadata.NewOutgoingContext(ctx, md)

	//var header, trailer metadata.MD

	resEcho, err := client.HelloWorld(ctx, &pb.EmptyMessage{})
	if err != nil {
		fmt.Printf("Unexpected error %v\n", err)
	} else {
		fmt.Printf("The message got: %s\n", resEcho.Msg)
	}

	resEcho, err = client.EchoHello(ctx, &pb.String{Msg: "mashingan"})
	if err != nil {
		fmt.Printf("Unexpected error %v\n", err)
	} else {
		fmt.Printf("The message got: %s\n", resEcho.Msg)
	}
}
