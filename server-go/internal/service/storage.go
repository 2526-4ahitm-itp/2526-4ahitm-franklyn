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

const (
	storageCheckInterval   = time.Minute
	storageRecoveryPercent = 1.0
	bytesPerGB             = 1e9
)

type storageLevel int

const (
	storageOK storageLevel = iota
	storageLow
	storageCritical
)

type storageLevelInfo struct {
	name     string
	tag      string
	logLevel slog.Level
}

var storageLevels = map[storageLevel]storageLevelInfo{
	storageOK:       {name: "ok", tag: "OK", logLevel: slog.LevelInfo},
	storageLow:      {name: "low", tag: "WARNING", logLevel: slog.LevelWarn},
	storageCritical: {name: "critically low", tag: "CRITICAL", logLevel: slog.LevelError},
}

func levelForUsedPercent(cfg *config.Config, usedPercent float64) storageLevel {
	switch {
	case usedPercent >= cfg.StorageCriticalPercent:
		return storageCritical
	case usedPercent >= cfg.StorageWarnPercent:
		return storageLow
	default:
		return storageOK
	}
}

func WatchStorage(ctx context.Context, logger *slog.Logger, cfg *config.Config) {
	timer := time.NewTimer(0)
	defer timer.Stop()
	level := storageOK
	for {
		select {
		case <-ctx.Done():
			return
		case <-timer.C:
		}
		timer.Reset(storageCheckInterval)

		var st syscall.Statfs_t
		if err := syscall.Statfs(cfg.StorageDir, &st); err != nil {
			logger.Error("Checking free storage failed", "dir", cfg.StorageDir, "error", err)
			continue
		}
		if st.Blocks == 0 {
			logger.Error("Checking free storage failed", "dir", cfg.StorageDir, "error", "filesystem reports 0 blocks")
			continue
		}
		usedPercent := 100 - float64(st.Bavail)*100/float64(st.Blocks)
		next := levelForUsedPercent(cfg, usedPercent)
		if next < level {
			next = levelForUsedPercent(cfg, usedPercent+storageRecoveryPercent)
		}
		if next == level {
			continue
		}
		level = next

		host, err := os.Hostname()
		if err != nil {
			host = "unknown host"
		}
		freeGB := float64(st.Bavail) * float64(st.Bsize) / bytesPerGB
		totalGB := float64(st.Blocks) * float64(st.Bsize) / bytesPerGB
		info := storageLevels[level]
		logger.Log(ctx, info.logLevel, fmt.Sprintf("Storage is %s: %.1f%% used (%.1f GB free of %.1f GB) in %s",
			info.name, usedPercent, freeGB, totalGB, cfg.StorageDir))
		subject := fmt.Sprintf("[FRANKLYN] %s: Storage %s on %s", info.tag, info.name, host)
		body := fmt.Sprintf("Storage on your Franklyn instance is %s.\n\nHost: %s\nDirectory: %s\nUsed: %.0f%% (%.1f GB of %.1f GB)\nFree: %.1f GB",
			info.name, host, cfg.StorageDir, usedPercent, totalGB-freeGB, totalGB, freeGB)
		if cfg.SMTPHost == "" {
			continue
		}
		if err := SendMail(cfg, subject, body); err != nil {
			logger.Error("Sending storage alert mail failed", "error", err)
		}
	}
}
