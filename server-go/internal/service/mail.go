package service

import (
	"crypto/tls"
	"fmt"
	"mime"
	"net"
	"net/smtp"
	"strconv"
	"strings"
	"time"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/config"
)

const (
	smtpDialTimeout    = 30 * time.Second
	smtpSessionTimeout = time.Minute
)

type loginAuth struct {
	username string
	password string
}

func (a loginAuth) Start(*smtp.ServerInfo) (string, []byte, error) {
	return "LOGIN", nil, nil
}

func (a loginAuth) Next(fromServer []byte, more bool) ([]byte, error) {
	if !more {
		return nil, nil
	}
	switch strings.ToLower(strings.TrimSpace(string(fromServer))) {
	case "username:":
		return []byte(a.username), nil
	case "password:":
		return []byte(a.password), nil
	}
	return nil, fmt.Errorf("unexpected LOGIN challenge %q", fromServer)
}

func dialSMTP(cfg *config.Config, tlsCfg *tls.Config) (net.Conn, error) {
	dialer := &net.Dialer{Timeout: smtpDialTimeout}
	addr := net.JoinHostPort(cfg.SMTPHost, strconv.Itoa(cfg.SMTPPort))
	if cfg.SMTPSecurity == config.SMTPSecurityTLS {
		return tls.DialWithDialer(dialer, "tcp", addr, tlsCfg)
	}
	return dialer.Dial("tcp", addr)
}

func SendMail(cfg *config.Config, subject, body string) error {
	if cfg.SMTPHost == "" {
		return nil
	}
	tlsCfg := &tls.Config{ServerName: cfg.SMTPHost}
	conn, err := dialSMTP(cfg, tlsCfg)
	if err != nil {
		return err
	}
	if err := conn.SetDeadline(time.Now().Add(smtpSessionTimeout)); err != nil {
		_ = conn.Close()
		return err
	}
	c, err := smtp.NewClient(conn, cfg.SMTPHost)
	if err != nil {
		_ = conn.Close()
		return err
	}
	defer func() { _ = c.Close() }()

	if cfg.SMTPSecurity == config.SMTPSecurityStartTLS {
		if err := c.StartTLS(tlsCfg); err != nil {
			return err
		}
	}
	if cfg.SMTPUsername != "" {
		if err := c.Auth(loginAuth{username: cfg.SMTPUsername, password: cfg.SMTPPassword}); err != nil {
			return err
		}
	}
	if err := c.Mail(cfg.SMTPFrom); err != nil {
		return err
	}
	for _, to := range cfg.AlertEmails {
		if err := c.Rcpt(strings.TrimSpace(to)); err != nil {
			return err
		}
	}

	w, err := c.Data()
	if err != nil {
		return err
	}
	if _, err := fmt.Fprintf(w,
		"From: %s\r\nTo: %s\r\nSubject: %s\r\nDate: %s\r\nMIME-Version: 1.0\r\nContent-Type: text/plain; charset=utf-8\r\n\r\n%s\r\n",
		cfg.SMTPFrom, strings.Join(cfg.AlertEmails, ", "),
		mime.QEncoding.Encode("utf-8", subject), time.Now().Format(time.RFC1123Z), body,
	); err != nil {
		return err
	}
	if err := w.Close(); err != nil {
		return err
	}
	return c.Quit()
}
