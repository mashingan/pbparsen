package main

import (
	"context"
	"flag"
	"fmt"

	_ "github.com/golang/protobuf/proto"
	_ "github.com/golang/protobuf/ptypes"
	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"

	pb "register/register_service/pb/register"
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
	client := pb.NewRegisterClient(conn)

	md := metadata.Pairs("token", *accessToken)
	ctx := context.Background()
	ctx = metadata.NewOutgoingContext(ctx, md)

	//var header, trailer metadata.MD

	/*
		user := pb.User{
			Name:  "mashingan",
			Email: []string{"ma@shing.an"},
		}
			resp, err := client.Register(ctx, &user)
			if err != nil {
				fmt.Printf("cannot register %s", err.Error())
			} else {
				fmt.Printf("Response: %s\n", resp.Msg)
			}
	*/
	user := pb.User{
		Name:   "rdruffy",
		Emails: []string{"rdruffy@rdr.corp"},
	}
	resp, err := client.Register(ctx, &user)
	if err != nil {
		fmt.Printf("cannot register %s\n", err.Error())
	} else {
		fmt.Printf("Response: %s\n", resp.Msg)
	}

	email, err := client.GetEmailByName(ctx, &pb.Name{Name: "rdruffy"})
	if err != nil {
		fmt.Printf("Unexpected error %s\n", err.Error())
	} else {
		fmt.Printf("The message got: %v\n", email.Emails)
	}

	resp, err = client.DeleteUser(ctx, &pb.User{Name: "rdruffy"})
	if err != nil {
		fmt.Printf("Error delete rdruffy: %s\n", err.Error())
	} else {
		fmt.Printf("The response message: %s\n", resp.Msg)
	}
}
