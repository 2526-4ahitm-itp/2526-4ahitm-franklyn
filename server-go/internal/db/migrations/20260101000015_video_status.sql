-- +goose Up
alter table fr_exam_sessions
    add column video_status varchar(10) default null;

-- +goose Down
-- ponytail: forward-only, no rollback
