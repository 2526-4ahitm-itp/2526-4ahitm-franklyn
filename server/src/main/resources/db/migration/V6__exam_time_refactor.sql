alter table fr_test
    drop column start_time,
    drop column end_time;

alter table fr_test
    add column start_time timestamp(6),
    add column end_time timestamp(6),
    add column started_at timestamp(6),
    add column ended_at timestamp(6);

update fr_test
set
    start_time = '1999-01-08 00:00:00',
    end_time = '1999-01-08 01:00:00';

alter table fr_test
    alter column start_time set not null,
    alter column end_time set not null;
