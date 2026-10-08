-- name: GetNotices :many
select * from fr_notice;

-- name: GetNoticeById :one
select * from fr_notice
where id = $1;

-- name: CreateNotice :one
insert into fr_notice (id, type, content, start_time, end_time)
values (uuidv7(), $1, $2, $3, $4)
returning *;

-- name: UpdateNotice :one
update fr_notice set
    content = $2,
    start_time = $3,
    end_time = $4
where id = $1
returning *;

-- name: DeleteNotice :exec
delete from fr_notice
where id = $1;
