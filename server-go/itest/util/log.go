package util

import (
	"os"
	"testing"

	"charm.land/lipgloss/v2"
	"charm.land/log/v2"
)

func Logger(t *testing.T) *log.Logger {
	l := log.NewWithOptions(os.Stderr, log.Options{
		Prefix:          "TEST",
		Level:           log.DebugLevel,
		ReportTimestamp: true,
		ReportCaller:    true,
	})

	styles := log.DefaultStyles()
	styles.Prefix = styles.Prefix.
		Bold(true).
		Foreground(lipgloss.Color("13")).
		Background(lipgloss.Color("236"))
	l.SetStyles(styles)

	// t.Cleanup(func() { l.Info("subtest done", "name", t.Name()) })
	return l
}
