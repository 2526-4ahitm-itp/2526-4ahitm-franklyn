
create sequence fr_teacher_seq start with 1 increment by 50;

create sequence fr_test_recording_seq start with 1 increment by 50;

create sequence fr_test_seq start with 1 increment by 50;

create table fr_teacher (
    id bigint not null,
    name varchar(255),
    primary key (id)
);

create table fr_test (
    id bigint not null,
    teacher_id bigint,
    title varchar(255) not null,
    test_account_prefix varchar(255),
    end_time timestamp(6),
    start_time timestamp(6),
    primary key (id)
);

create table fr_test_recording (
    end_time timestamp(6),
    id bigint not null,
    start_time timestamp(6),
    test_id bigint,
    pc_name varchar(255),
    student_name varchar(255),
    video_file varchar(255),
    primary key (id)
);

alter table if exists fr_test 
   add constraint fr_fk_test_teacher 
   foreign key (teacher_id) 
   references fr_teacher;

alter table if exists fr_test_recording 
   add constraint fr_fk_testrecording_test 
   foreign key (test_id) 
   references fr_test;

