alter table fr_exam_sessions
    drop constraint fr_exam_sessions_student_id_fkey,
    add constraint fr_exam_sessions_user_id_fkey foreign key (student_id) references fr_user (id);
