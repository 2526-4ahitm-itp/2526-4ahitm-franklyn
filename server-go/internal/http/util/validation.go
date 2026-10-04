package util

import (
	"bytes"
	"context"
	"fmt"
	"net/http"
)

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

type Problem struct {
	Field  string `json:"field"`
	Reason string `json:"reason"`
}

type Problems []Problem

func (p *Problems) Require(cond bool, field string, reason string) {
	if !cond {
		*p = append(*p, Problem{
			Field:  field,
			Reason: reason,
		})
	}
}

type Validator interface {
	Valid(ctx context.Context) Problems
}

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
