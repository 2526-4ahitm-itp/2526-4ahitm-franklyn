-- +goose Up

alter table fr_notice
    alter column start_time type timestamptz(6) using start_time at time zone 'UTC',
    alter column end_time   type timestamptz(6) using end_time   at time zone 'UTC';

alter table fr_exam
    alter column start_time type timestamptz(6) using start_time at time zone 'UTC',
    alter column end_time   type timestamptz(6) using end_time   at time zone 'UTC',
    alter column started_at type timestamptz(6) using started_at at time zone 'UTC',
    alter column ended_at   type timestamptz(6) using ended_at   at time zone 'UTC';

-- +goose Down

alter table fr_notice
    alter column start_time type timestamp(6) using start_time at time zone 'UTC',
    alter column end_time   type timestamp(6) using end_time   at time zone 'UTC';

alter table fr_exam
    alter column start_time type timestamp(6) using start_time at time zone 'UTC',
    alter column end_time   type timestamp(6) using end_time   at time zone 'UTC',
    alter column started_at type timestamp(6) using started_at at time zone 'UTC',
    alter column ended_at   type timestamp(6) using ended_at   at time zone 'UTC';
