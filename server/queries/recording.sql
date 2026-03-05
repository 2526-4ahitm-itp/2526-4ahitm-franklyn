-- name: findAllRecordings :many
select * from fr_test_recording;

-- name: insertRecording :exec
insert into fr_test_recording (end_time, id, start_time, test_id, pc_name, student_name, video_file)
values ($1, fr_test_recording_seq.nextval(), $2, $3, $4, $5, $6);

-- name: findRecordingById :one
select * from fr_test_recording
where id = $1;