-- name: GetUserSettings :one
select * from fr_settings
where user_id = $1;

-- name: ProvisionSettings :one
insert into fr_settings (user_id, theme, language)
values ($1, $2, $3) on conflict (user_id) do update set
    theme = excluded.theme,
    language = excluded.language
returning user_id, theme, language;
