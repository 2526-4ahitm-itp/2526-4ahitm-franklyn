-- name: findAllTests :many
select * from fr_test;

-- name: insertTest :one
insert into fr_test (id, teacher_id, title, test_account_prefix, end_time, start_time)
values (fr_test_seq.nextval(), $1, $2, $3, $4, $5) RETURNING *;

-- name: findTestById :one
select * from fr_test
where id = $1;

-- name: updateTest :one
update fr_test set title = $1, test_account_prefix = $2, end_time = $3, start_time = $4 WHERE id = $5
RETURNING *;

-- name: deleteTest :one
delete from fr_test WHERE id = $1 RETURNING *;