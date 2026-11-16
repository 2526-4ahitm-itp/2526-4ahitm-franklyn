-- name: FindExamByTeacherIdAndId :one
select * from fr_exam
where teacher_id = $2 and id = $1;

-- name: CreateExam :one
insert into fr_exam (id, teacher_id, title, pin, start_time, end_time)
values (uuidv7(), $1, $2, $3, $4, $5)
returning *;

-- name: FindExamByTeacherId :many
select * from fr_exam
where teacher_id = $1;

-- name: UpdateExam :one
update fr_exam set
    title = $2,
    start_time = $3,
    end_time = $4,
    started_at = $5,
    ended_at = $6
where id = $1
returning *;
