create type fr_notice_type as enum ('alert', 'timed', 'single');

create table fr_notices (
    id uuid,
    type fr_notice_type,
    content varchar(1024) not null,

    primary key (`id`)
)