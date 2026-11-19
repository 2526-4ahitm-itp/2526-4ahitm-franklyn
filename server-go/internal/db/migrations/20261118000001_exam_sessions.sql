-- +goose Up

alter table fr_exam_sessions rename to legacy_fr_exam_sessions;

create table fr_exam_sessions (
    student_id uuid not null,
    exam_id uuid not null,
    
    joined_at timestamptz(6) not null default now(),
    last_seen timestamptz(6) not null default now(),

    constraint fr_exam_session_fk_student 
        foreign key(student_id) references fr_user(id),
    constraint fr_exam_session_fk_exam 
        foreign key(exam_id) references fr_exam(id),
    constraint fr_exam_sessions_ok 
        primary key (student_id, exam_id)
);

-- +goose Down

drop table fr_exam_sessions;
alter table legacy_fr_exam_sessions rename to fr_exam_sessions;
