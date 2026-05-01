create table fr_issue_report (
    id uuid,
    reporter_id uuid not null,
    content varchar(4096) not null,
    created_at timestamp(6) not null,

    primary key (id),
    foreign key (reporter_id) references fr_user (id)
);
