package apperr

import "fmt"

type Code string

type AppErr struct {
	Code    Code
	Message string
	Err     error
}

func (e *AppErr) Error() string {
	if e.Err != nil {
		return fmt.Sprintf("%s: %s", e.Message, e.Err.Error())
	}
	return e.Message
}

func (e *AppErr) Unwrap() error { return e.Err }

func New(code Code, msg string, err error) *AppErr {
	return &AppErr{Code: code, Message: msg, Err: err}
}
