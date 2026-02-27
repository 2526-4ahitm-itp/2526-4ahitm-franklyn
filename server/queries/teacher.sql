-- name: findAllTeachers :many
select * from fr_teacher;

-- name: insertTeacher :exec
insert into fr_teacher (id, name)
values ($1, $2);

-- name: findTeacherById :one
select * from fr_teacher
where id = $1;