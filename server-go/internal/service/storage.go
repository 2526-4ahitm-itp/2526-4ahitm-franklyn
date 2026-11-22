package service

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"syscall"
	"time"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/config"
)

var storageLevels = [...]struct {
	name string
	tag  string
	log  slog.Level
}{{"ok", "OK", slog.LevelInfo}, {"low", "WARNING", slog.LevelWarn}, {"critically low", "CRITICAL", slog.LevelError}}

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
		host, _ := os.Hostname()
		freeGB := float64(st.Bavail) * float64(st.Bsize) / 1e9
		totalGB := float64(st.Blocks) * float64(st.Bsize) / 1e9
		l := storageLevels[level]
		logger.Log(ctx, l.log, fmt.Sprintf("Storage is %s: %.1f%% free (%.1f GB of %.1f GB) in %s",
			l.name, freePercent, freeGB, totalGB, cfg.StorageDir))
		subject := fmt.Sprintf("[FRANKLYN] %s: Storage %s on %s", l.tag, l.name, host)
		body := fmt.Sprintf("Storage on your Franklyn instance is %s.\n\nHost: %s\nDirectory: %s\nUsed: %.0f%% (%.1f GB of %.1f GB)\nFree: %.1f GB",
			l.name, host, cfg.StorageDir, 100-freePercent, totalGB-freeGB, totalGB, freeGB)
		if err := SendMail(cfg, subject, body); err != nil {
			logger.Error("Sending storage alert mail failed", "error", err)
		}
	}
}
