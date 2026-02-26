-- name: findAll :many
select * from fr_teacher;

-- name: insert :exec
insert into fr_teacher (id, name)
values ($1, $2);

-- name: findById :one
select * from fr_teacher
where id = $1;