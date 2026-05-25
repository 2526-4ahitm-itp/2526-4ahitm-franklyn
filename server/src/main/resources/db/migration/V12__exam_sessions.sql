create table fr_exam_sessions (
    student_id uuid not null,
    sentinel_id uuid not null,
    exam_id uuid not null,
    video_file_path varchar(1024) default null,
    primary key (student_id, exam_id),
    foreign key (student_id) references fr_student (id),
    foreign key (exam_id) references fr_exam (id)
);
