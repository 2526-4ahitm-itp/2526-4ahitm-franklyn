-- name: findAll :many
select * from fr_test;

-- name: insert :exec
insert into fr_test (id, teacher_id, title, test_account_prefix, end_time, start_time)
values ($1, $2, $3, $4, $5, $6);

-- name: findById :one
select * from fr_test
where id = $1;