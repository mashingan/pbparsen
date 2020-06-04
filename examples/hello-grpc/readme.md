# Hello Grpc
This example gives a simplest example of code generation of `Hello Grpc` service.  
In order to run this example, we are using `go module` to solve its dependencies.  
Copy the `hello.proto` and `config.cfg` to the other folder to run it
in another folder but we can also run in this folder.  

In this example, we will generate the codes here.  
After we've built the `pbparsen`

```
$ ../../pbparsen config.cfg
$ cd src/hello_grpc/
$ go mod init hello_grpc
$ go vet server_driver.go
```

This will install and fix all dependencies. Here we can check whether the
all is OK.  
Make sure that we have `protoc` installed and availabe in path. Please refer to `protoc`
installation in [gRPC Golang tutorial](https://grpc.io/docs/languages/go/quickstart/).

If there's no problem. We can run it using our implemented `client.go`

```
$ go run server_driver.go &
$ cp ../../client.go .
$ go run client.go
Unexpected error rpc error: code = Unknown desc = No implemented
Unexpected error rpc error: code = Unknown desc = No implemented
```

It will return the error message that our service is running but the handlers
are still not implemented.  
The `client.go` here is just an example of how to access the service  
and can be implemented differently than the provided example `client.go`.  
We can implement it by ourselve but let's copy the implemented handlers.

```
$ kill %1
$ cp ../../hello_grpc_usecase_impl.go hello_grpc_service/usecase/
$ go vet server_driver.go
```

This will display error of `redeclared` in several functions.
It because we need to delete the initial generated code which the functions
still haven't implemented the handlers.

```
$ rm hello_grpc_service/usecase/hello_grpcusecase_impl.go
$ go vet server_driver.go
```

This time it will return fine. Next let's run it.

```
$ go run server_driver.go &
$ go run client.go
The message got: Hello nice world
The message got: Hello nice mashingan
```

The last two lines are the example of our running service with its handler.
Each of service is represented by this code

```
        // line 38
	resEcho, err := client.HelloWorld(ctx, &pb.EmptyMessage{})

        // line 45
	resEcho, err = client.EchoHello(ctx, &pb.String{Msg: "mashingan"})
```

Both those handlers are represented in `hello.proto` with

```
service Hello {
    rpc HelloWorld(EmptyMessage) returns (String);
    rpc EchoHello (String) returns (String);
}
```

with handlers implementation in `hello_grpc/hello_grpc_service/usecase/hello_grpc_usecase_impl.go`.  

With this, the boilerplate is generated accordance to the protobuf definition.
