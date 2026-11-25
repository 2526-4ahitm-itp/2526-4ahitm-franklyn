package service

import (
	"crypto/tls"
	"errors"
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

func (auth loginAuth) Start(*smtp.ServerInfo) (string, []byte, error) {
	return "LOGIN", nil, nil
}

func (auth loginAuth) Next(fromServer []byte, more bool) ([]byte, error) {
	if !more {
		return nil, nil
	}
	switch strings.ToLower(strings.TrimSpace(string(fromServer))) {
	case "username:":
		return []byte(auth.username), nil
	case "password:":
		return []byte(auth.password), nil
	}
	return nil, fmt.Errorf("unexpected LOGIN challenge %q", fromServer)
}

func SendMail(cfg *config.Config, subject, body string) error {
	client, err := connectSMTP(cfg)
	if err != nil {
		return err
	}

	message := buildMessage(cfg.SMTPFrom, cfg.AlertEmails, subject, body)
	if err := sendMessage(client, cfg.SMTPFrom, cfg.AlertEmails, message); err != nil {
		return errors.Join(err, client.Close())
	}
	return nil
}

func connectSMTP(cfg *config.Config) (*smtp.Client, error) {
	address := net.JoinHostPort(cfg.SMTPHost, strconv.Itoa(cfg.SMTPPort))
	tlsConfig := &tls.Config{ServerName: cfg.SMTPHost}

	conn, err := dialSMTP(cfg.SMTPSecurity, address, tlsConfig)
	if err != nil {
		return nil, fmt.Errorf("connect to smtp server %s: %w", address, err)
	}
	if err := conn.SetDeadline(time.Now().Add(smtpSessionTimeout)); err != nil {
		return nil, errors.Join(fmt.Errorf("set smtp deadline: %w", err), conn.Close())
	}

	client, err := smtp.NewClient(conn, cfg.SMTPHost)
	if err != nil {
		return nil, errors.Join(fmt.Errorf("start smtp session with %s: %w", address, err), conn.Close())
	}

	if cfg.SMTPSecurity == config.SMTPSecurityStartTLS {
		if err := client.StartTLS(tlsConfig); err != nil {
			return nil, errors.Join(fmt.Errorf("starttls with %s: %w", address, err), client.Close())
		}
	}
	if cfg.SMTPUsername != "" {
		auth := loginAuth{username: cfg.SMTPUsername, password: cfg.SMTPPassword}
		if err := client.Auth(auth); err != nil {
			return nil, errors.Join(fmt.Errorf("smtp login as %s: %w", cfg.SMTPUsername, err), client.Close())
		}
	}
	return client, nil
}

func dialSMTP(security config.SMTPSecurity, address string, tlsConfig *tls.Config) (net.Conn, error) {
	dialer := &net.Dialer{Timeout: smtpDialTimeout}
	if security == config.SMTPSecurityTLS {
		return tls.DialWithDialer(dialer, "tcp", address, tlsConfig)
	}
	return dialer.Dial("tcp", address)
}

func buildMessage(from string, recipients []string, subject, body string) string {
	headers := []string{
		"From: " + from,
		"To: " + strings.Join(recipients, ", "),
		"Subject: " + mime.QEncoding.Encode("utf-8", subject),
		"Date: " + time.Now().Format(time.RFC1123Z),
		"MIME-Version: 1.0",
		"Content-Type: text/plain; charset=utf-8",
	}
	return strings.Join(headers, "\r\n") + "\r\n\r\n" + body + "\r\n"
}

func sendMessage(client *smtp.Client, from string, recipients []string, message string) error {
	if err := client.Mail(from); err != nil {
		return fmt.Errorf("set sender %s: %w", from, err)
	}
	for _, recipient := range recipients {
		recipient = strings.TrimSpace(recipient)
		if err := client.Rcpt(recipient); err != nil {
			return fmt.Errorf("add recipient %s: %w", recipient, err)
		}
	}

	writer, err := client.Data()
	if err != nil {
		return fmt.Errorf("start mail data: %w", err)
	}
	if _, err := writer.Write([]byte(message)); err != nil {
		return errors.Join(fmt.Errorf("write mail data: %w", err), writer.Close())
	}
	if err := writer.Close(); err != nil {
		return fmt.Errorf("finish mail data: %w", err)
	}
	if err := client.Quit(); err != nil {
		return fmt.Errorf("quit smtp session: %w", err)
	}
	return nil
}
