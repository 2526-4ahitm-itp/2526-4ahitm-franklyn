-- name: findAllTeachers :many
select * from fr_teacher;

-- name: insertTeacher :exec
insert into fr_teacher (id, name)
values (fr_teacher_seq.nextval(), $1);

-- name: findTeacherById :one
select * from fr_teacher
where id = $1;