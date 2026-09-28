-- +goose Up
alter table fr_test add pin numeric;

-- +goose Down
-- ponytail: forward-only, no rollback
