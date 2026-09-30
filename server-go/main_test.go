package main

import (
	"context"
	"os"
	"testing"
)

func TestMain(t *testing.T) {
	ctx := context.Background()
	ctx, cancel := context.WithCancel(ctx)
	t.Cleanup(cancel)
	go run(ctx, os.Stdout, os.Args)

	<-ctx.Done()
}
