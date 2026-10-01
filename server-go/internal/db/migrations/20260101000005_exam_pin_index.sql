-- +goose Up
alter table fr_test alter column pin type smallint;
create index idx_fr_test_pin on fr_test (pin);
-- +goose Down
-- ponytail: forward-only, no rollback
