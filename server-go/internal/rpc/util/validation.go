package util

import (
	"connectrpc.com/connect/v2"
	"connectrpc.com/connect/v2/connectproto"
	"google.golang.org/genproto/googleapis/rpc/errdetails"
)

// Problem is a single field that failed validation and the reason why.
type Problem struct {
	Field  string `json:"field"`
	Reason string `json:"reason"`
}

// Problems collects the problems found while validating one value.
type Problems []Problem

func (p *Problems) ToBadRequestViolations() (*connect.ErrorDetail, error) {
	violations := []*errdetails.BadRequest_FieldViolation{}

	for _, e := range *p {
		violations = append(violations, &errdetails.BadRequest_FieldViolation{
			Field:       e.Field,
			Description: e.Reason,
		})
	}

	return connectproto.NewErrorDetail(&errdetails.BadRequest{
		FieldViolations: violations,
	})
}

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
