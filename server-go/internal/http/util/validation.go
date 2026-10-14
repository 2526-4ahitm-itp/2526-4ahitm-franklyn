package util

import (
	"bytes"
	"context"
	"fmt"
	"net/http"
)

// ValidationError holds every validation problem of one request body. Handle
// maps it to a 400 response containing the problems.
type ValidationError struct {
	Problems []Problem
}

func (ve ValidationError) Error() string {
	var buf bytes.Buffer

	buf.WriteString("validation failed with the following problems:")

	for _, v := range ve.Problems {
		fmt.Fprintf(&buf, "\n - `%s`: \"%s\"", v.Field, v.Reason)
	}

	return buf.String()
}

// Problem is a single field that failed validation and the reason why.
type Problem struct {
	Field  string `json:"field"`
	Reason string `json:"reason"`
}

// Problems collects the problems found while validating one value.
type Problems []Problem

// Require records a problem for field unless cond holds. cond is the condition
// that must be true for the value to be valid.
func (p *Problems) Require(cond bool, field string, reason string) {
	if !cond {
		*p = append(*p, Problem{
			Field:  field,
			Reason: reason,
		})
	}
}

// Validator is implemented by request bodies that validate themselves.
// Returning no problems means the value is valid.
type Validator interface {
	Valid(ctx context.Context) Problems
}

// DecodeValid decodes the JSON request body into T and validates it. It
// returns a ValidationError if T reports any problem, so handlers can pass the
// error straight back to Handle.
//
//	type CreateFooBody struct {
//		Name string `json:"name"`
//	}
//
//	func (b CreateFooBody) Valid(ctx context.Context) util.Problems {
//		p := util.Problems{}
//		p.Require(len(b.Name) > 2, "name", "must be longer than 2 characters")
//		return p
//	}
//
//	body, err := util.DecodeValid[CreateFooBody](r)
func DecodeValid[T Validator](r *http.Request) (T, error) {
	var v T
	v, err := Decode[T](r)

	if err != nil {
		return v, err
	}
	if problems := v.Valid(r.Context()); len(problems) > 0 {
		return v, ValidationError{problems}
	}
	return v, nil
}
