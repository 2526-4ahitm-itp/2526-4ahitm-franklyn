create type fr_notice_type as enum ('alert', 'timed', 'single');

create table fr_notices (
    id uuid,
    type fr_notice_type,
    content varchar(1024) not null,
    start_time timestamp(6),
    end_time timestamp(6),

    primary key (`id`)
)