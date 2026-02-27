-- name: findAllTests :many
select * from fr_test;

-- name: insertTest :exec
insert into fr_test (id, teacher_id, title, test_account_prefix, end_time, start_time)
values ($1, $2, $3, $4, $5, $6);

-- name: findTestById :one
select * from fr_test
where id = $1;