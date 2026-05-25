alter table fr_exam_sessions
    drop constraint fr_exam_sessions_pkey,
    add primary key (sentinel_id);
