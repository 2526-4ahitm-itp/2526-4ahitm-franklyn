-- name: findAllTests :many
select * from fr_test;

-- name: insertTest :exec
insert into fr_test (id, teacher_id, title, test_account_prefix, end_time, start_time)
values ($1, $2, $3, $4, $5, $6);

-- name: findTestById :one
select * from fr_test
where id = $1;

update fr_test set title = $3, test_account_prefix = $4, end_time = $5, start_time = $6 WHERE id = $1;

delete from fr_test WHERE id = $1;