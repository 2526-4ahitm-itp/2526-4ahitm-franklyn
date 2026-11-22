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

type loginAuth struct{ username, password string }

func (a loginAuth) Start(*smtp.ServerInfo) (string, []byte, error) { return "LOGIN", nil, nil }

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

func SendMail(cfg *config.Config, subject, body string) error {
	if cfg.SMTPHost == "" {
		return nil
	}
	tlsCfg := &tls.Config{ServerName: cfg.SMTPHost}
	dialer := &net.Dialer{Timeout: 30 * time.Second}
	dial := dialer.Dial
	if cfg.SMTPSecurity == "tls" {
		dial = func(n, a string) (net.Conn, error) { return tls.DialWithDialer(dialer, n, a, tlsCfg) }
	}
	conn, err := dial("tcp", net.JoinHostPort(cfg.SMTPHost, strconv.Itoa(cfg.SMTPPort)))
	if err != nil {
		return err
	}
	_ = conn.SetDeadline(time.Now().Add(time.Minute))
	c, err := smtp.NewClient(conn, cfg.SMTPHost)
	if err != nil {
		_ = conn.Close()
		return err
	}
	defer func() { _ = c.Close() }()

	if cfg.SMTPSecurity == "starttls" {
		err = c.StartTLS(tlsCfg)
	}
	if err == nil && cfg.SMTPUsername != "" {
		err = c.Auth(loginAuth{cfg.SMTPUsername, cfg.SMTPPassword})
	}
	if err == nil {
		err = c.Mail(cfg.SMTPFrom)
	}
	for _, to := range cfg.AlertEmails {
		if err == nil {
			err = c.Rcpt(strings.TrimSpace(to))
		}
	}
	if err != nil {
		return err
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
