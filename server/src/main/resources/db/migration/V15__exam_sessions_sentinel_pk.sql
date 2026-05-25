alter table fr_exam_sessions
    drop constraint fr_exam_sessions_pkey,
    add primary key (sentinel_id),
    add constraint fr_exam_sessions_student_id_unique unique (student_id);
