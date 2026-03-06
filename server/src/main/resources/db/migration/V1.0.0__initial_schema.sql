
create sequence fr_teacher_seq start with 1;

create sequence fr_test_seq start with 1;

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

alter table if exists fr_test 
   add constraint fr_fk_test_teacher 
   foreign key (teacher_id) 
   references fr_teacher;
