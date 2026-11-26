-- +goose Up

update fr_settings set
    theme = DEFAULT,
    language = DEFAULT
where theme is null or language is null;

alter table fr_settings
    alter column theme set not null,
    alter column theme drop default,
    alter column language set not null,
    alter column language drop default;


-- +goose Down
