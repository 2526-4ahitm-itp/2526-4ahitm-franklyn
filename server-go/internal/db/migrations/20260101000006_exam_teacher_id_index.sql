-- +goose Up
create index idx_fr_test_teacher_id on fr_test (teacher_id);
-- +goose Down
-- ponytail: forward-only, no rollback
