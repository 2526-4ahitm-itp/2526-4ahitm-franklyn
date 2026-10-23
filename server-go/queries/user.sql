-- name: ProvisionUser :one
insert into fr_user (id, preferred_username, email, given_name, family_name, role)
values ($1, $2, $3, $4, $5, $6)
on conflict (id) do update set
  preferred_username = excluded.preferred_username,
  email = excluded.email,
  given_name = excluded.given_name,
  family_name = excluded.family_name
returning id, preferred_username, email, given_name, family_name, role;

-- name: FindUserByID :one
select * from fr_user
where id = $1;

-- name: FindUserByIdAndType :one
select * from fr_user
where id = $1 and role = $2;
