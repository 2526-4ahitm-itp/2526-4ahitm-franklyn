-- +goose Up
drop table fr_teacher cascade;
drop table fr_student cascade;

alter table fr_exam
    add constraint fr_exam_teacher_id_fkey foreign key (teacher_id) references fr_user (id);

create table fr_settings (
    user_id uuid not null,
    theme fr_settings_theme default 'system',
    language varchar(10) default 'de',

    primary key (user_id),
    foreign key (user_id) references fr_user (id) on delete cascade
);

insert into fr_settings (user_id, theme, language)
select id, coalesce(theme, 'system'), coalesce(language, 'de')
from fr_user;

alter table fr_user
    drop column theme,
    drop column language;

-- +goose Down
