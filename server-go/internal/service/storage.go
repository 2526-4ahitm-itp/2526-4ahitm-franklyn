package service

import (
	"context"
	"fmt"
	"log/slog"
	"syscall"
	"time"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/config"
)

var storageLevels = [...]struct {
	name string
	log  slog.Level
}{{"ok", slog.LevelInfo}, {"low", slog.LevelWarn}, {"critically low", slog.LevelError}}

func storageLevel(cfg *config.Config, freePercent float64) int {
	switch {
	case freePercent < cfg.StorageCriticalPercent:
		return 2
	case freePercent < cfg.StorageWarnPercent:
		return 1
	}
	return 0
}

func WatchStorage(ctx context.Context, logger *slog.Logger, cfg *config.Config) {
	timer := time.NewTimer(0)
	defer timer.Stop()
	for level := 0; ; {
		select {
		case <-ctx.Done():
			return
		case <-timer.C:
		}
		timer.Reset(time.Minute)

		var st syscall.Statfs_t
		if err := syscall.Statfs(cfg.StorageDir, &st); err != nil {
			logger.Error("Checking free storage failed", "dir", cfg.StorageDir, "error", err)
			continue
		}
		if st.Blocks == 0 {
			continue
		}
		freePercent := float64(st.Bavail) * 100 / float64(st.Blocks)
		next := storageLevel(cfg, freePercent)
		if next < level {
			next = storageLevel(cfg, freePercent-1)
		}
		if next == level {
			continue
		}
		level = next
		msg := fmt.Sprintf("Storage is %s: %.1f%% free (%.1f GB of %.1f GB) in %s",
			storageLevels[level].name, freePercent,
			float64(st.Bavail)*float64(st.Bsize)/1e9, float64(st.Blocks)*float64(st.Bsize)/1e9, cfg.StorageDir)
		logger.Log(ctx, storageLevels[level].log, msg)
		if err := SendMail(cfg, "Franklyn: "+msg, msg); err != nil {
			logger.Error("Sending storage alert mail failed", "error", err)
		}
	}
}
