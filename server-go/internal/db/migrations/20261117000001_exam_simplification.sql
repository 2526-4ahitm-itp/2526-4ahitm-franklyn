-- +goose Up

create type fr_exam_state_type as enum ('scheduled', 'open', 'live', 'ended');

alter table fr_exam
    drop column started_at,
    drop column ended_at,
    add column state fr_exam_state_type default 'scheduled' not null,
    add column preopen_time_minutes integer not null;

-- +goose Down

alter table fr_exam
    add column started_at   timestamp(6) using started_at   at time zone 'UTC',
    add column ended_at     timestamp(6) using ended_at     at time zone 'UTC',
    drop column state,
    drop column preopen_time_minutes;

drop type fr_exam_state_type;
