delete from fr_exam_sessions
where ctid not in (
    select distinct on (student_id) ctid
    from fr_exam_sessions
    order by student_id, ctid desc
);

alter table fr_exam_sessions
    drop constraint fr_exam_sessions_pkey,
    add primary key (student_id);
