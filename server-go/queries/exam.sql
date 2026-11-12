-- name: FindExamById :one
select * from fr_exam
where id = $1;

-- name: CreateExam :one
insert into fr_exam (id, teacher_id, title, pin, start_time, end_time)
values (uuidv7(), $1, $2, $3, $4, $5)
returning *;

