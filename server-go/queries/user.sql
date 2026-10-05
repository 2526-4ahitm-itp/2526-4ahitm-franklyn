-- name: ProvisionUser :one
with u as (
  insert into fr_user (id, preferred_username, email, given_name, family_name, role)
  values ($1,$2,$3,$4,$5,$6)
  on conflict (id) do update set
    preferred_username = excluded.preferred_username,
    email = excluded.email,
    given_name = excluded.given_name,
    family_name = excluded.family_name
  returning *
), t as (
  insert into fr_teacher (id) select id from u where role = 'TEACHER' on conflict do nothing
), s as (
  insert into fr_student (id) select id from u where role = 'STUDENT' on conflict do nothing
)
select * from u;


-- name: InsertUser :one
insert into fr_user (id, preferred_username, email, given_name, family_name, role)
values ($1, $2, $3, $4, $5, $6)
returning *;

-- name: FindByID :one
select * from fr_user
where id = $1;

-- name: FindByIdAndType :one
select * from fr_user
where id = $1 and role = $2;

-- name: UpdateUser :one
update fr_user set
    preferred_username = $2,
    email = $3,
    given_name = $4,
    family_name = $5,
    language = $6,
    theme = $7
where id = $1
returning *;

-- name: GetStudent :one
select sqlc.embed(fr_user), sqlc.embed(fr_student)
from fr_student join fr_user using (id)
where fr_user.id = $1;

-- name: GetTeacher :one
select sqlc.embed(fr_user), sqlc.embed(fr_teacher)
from fr_teacher join fr_user using (id)
where fr_user.id = $1;
