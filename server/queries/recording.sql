-- name: findAll :many
select * from fr_test_recording;

-- name: insert :exec
insert into fr_test_recording (end_time, id, start_time, test_id, pc_name, student_name, video_file)
values ($1, $2, $3, $4, $5, $6, $7);

-- name: findById :one
select * from fr_test_recording
where id = $1;