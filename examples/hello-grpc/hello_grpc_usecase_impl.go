package usecase

import (
	vm "hello_grpc/hello_grpc_service/view_model"
)

type HelloUsecaseImpl struct{}

func NewHelloUsecase() HelloUsecase {
	return &HelloUsecaseImpl{}
}

func (s *HelloUsecaseImpl) EchoHello(argin vm.String) (*vm.String, error) {
	return &vm.String{"Hello nice " + argin.Msg}, nil
}

func (s *HelloUsecaseImpl) HelloWorld(argin vm.EmptyMessage) (*vm.String, error) {
	return &vm.String{"Hello nice world"}, nil
}
