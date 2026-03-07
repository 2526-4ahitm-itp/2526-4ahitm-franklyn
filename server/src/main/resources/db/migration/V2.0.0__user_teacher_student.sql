
-- reset schema
drop sequence fr_teacher_seq;
drop sequence fr_test_seq;
drop table fr_test;
drop table fr_teacher;


-- recreate schema

create table fr_user (
    id uuid,
    preferred_username varchar(255) not null,
    email varchar(255) not null,
    given_name varchar(255),
    family_name varchar(255),

    primary key (id)
);


create table fr_teacher (
    id uuid,

    primary key (id),
    foreign key (id) references fr_user (id)
);


create table fr_student (
    id uuid,

    primary key (id),
    foreign key (id) references fr_user (id)
);


create table fr_test (
    id uuid,
    teacher_id uuid,
    title varchar(255) not null,
    end_time timestamp(6),
    start_time timestamp(6),

    primary key (id),
    foreign key (teacher_id) references fr_teacher (id)
);
