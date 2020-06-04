package usecase

import (
	"fmt"
	"sync"

	register "register/register_service"
	"register/register_service/entity"
	"register/register_service/repository"
	vm "register/register_service/view_model"
	/*
		"github.com/jinzhu/gorm"
		_ "github.com/jinzhu/gorm/dialects/sqlite"
	*/)

/*
   GetEmailByName(x vm.Name) (*vm.Email, error)
   DeleteUser(x vm.User) (*vm.String, error)
   GetUserByEmail(x vm.Email) (*vm.User, error)
   ModifyEmail(x vm.Email) (*vm.String, error)
   Register(x vm.User) (*vm.String, error)
*/

type RegisterUsecaseImpl struct {
	users  repository.UsersRepository
	emails repository.EmailsRepository
}

func NewRegisterUsecase(usrep repository.UsersRepository, emrep repository.EmailsRepository) RegisterUsecase {
	return &RegisterUsecaseImpl{usrep, emrep}
}

func (s *RegisterUsecaseImpl) GetEmailByName(argin vm.Name) (*vm.Email, error) {
	fmt.Printf("GetEmailByName request: %v\n", argin)
	emails, err := s.emails.GetWith(map[string][]interface{}{
		"username = ?": {"and", argin.Name},
	})
	if err != nil {
		return nil, err
	}
	if len(emails) == 0 {
		return nil, register.ErrNotFound
	}
	//email := emails[0]
	emailsres := make([]string, 0)
	for _, em := range emails {
		emailsres = append(emailsres, em.Email)
	}
	result := vm.Email{emailsres}
	fmt.Printf("GetEmailByName result: %v\n", result)
	return &result, nil
}

func (s *RegisterUsecaseImpl) DeleteUser(argin vm.User) (*vm.String, error) {
	fmt.Printf("DeleteUser request: %v\n", argin)
	_, err := s.users.DeleteWith(map[string][]interface{}{
		"name = ?": {"and", argin.Name},
	})
	if err != nil {
		return nil, err
	}

	_, err = s.emails.DeleteWith(map[string][]interface{}{
		"name = ?": {"and", argin.Name},
	})
	if err != nil {
		return nil, err
	}
	return &vm.String{fmt.Sprintf("%s successfully deleted", argin.Name)}, nil
}

func (s *RegisterUsecaseImpl) GetUserByEmail(argin vm.Email) (*vm.User, error) {
	return nil, fmt.Errorf("%s", "Not implemented yet")
}

func (s *RegisterUsecaseImpl) ModifyEmail(argin vm.Email) (*vm.String, error) {
	return nil, fmt.Errorf("%s", "Not implemented yet")
}

func emailsToEntityEmail(username string, emails []string) []entity.Emails {
	result := make([]entity.Emails, 0)
	for _, email := range emails {
		result = append(result, entity.Emails{
			Username: username,
			Email:    email,
		})
	}
	return result
}

func (s *RegisterUsecaseImpl) Register(argin vm.User) (*vm.String, error) {
	fmt.Printf("Register request: %v\n", argin)
	if len(argin.Emails) == 0 {
		return nil, fmt.Errorf("%s", "Invalid request")
	}
	emails := emailsToEntityEmail(argin.Name, argin.Emails)
	req := entity.Users{
		Name:   argin.Name,
		Emails: emails,
	}

	resp, err := s.users.CreateUsers(&req)
	if err != nil {
		return nil, err
	}

	var wg sync.WaitGroup
	fmt.Println("Got emails: %v\n", emails)
	for _, email := range emails {
		wg.Add(1)
		go func(w *sync.WaitGroup, eml *entity.Emails) {
			defer w.Done()
			fmt.Printf("register email: %v\n", eml)
			_, _ = s.emails.CreateEmails(eml)

		}(&wg, &email)
	}
	wg.Wait()

	result := vm.String{"user for " + resp.Name + " successfully created"}
	fmt.Printf("Register result: %v\n", result)
	return &result, nil
}
