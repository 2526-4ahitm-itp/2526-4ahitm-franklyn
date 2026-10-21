-- V16: Simplify user model
-- Drop fr_teacher / fr_student subtype tables, repoint FKs to fr_user.
-- Extract theme + language into fr_settings (1:1 with fr_user).

-- 1) Drop subtype tables — CASCADE removes FKs that reference them
--    (fr_exam.teacher_id FK → fr_teacher is auto-dropped)
drop table fr_teacher cascade;
drop table fr_student cascade;

-- 2) Re-add fr_exam.teacher_id FK pointing at fr_user
alter table fr_exam
    add constraint fr_exam_teacher_id_fkey foreign key (teacher_id) references fr_user (id);

-- 3) Create fr_settings (1:1 with fr_user)
create table fr_settings (
    user_id uuid not null,
    theme fr_settings_theme default 'system',
    language varchar(10) default 'de',

    primary key (user_id),
    foreign key (user_id) references fr_user (id)
);

-- 4) Migrate existing settings data
insert into fr_settings (user_id, theme, language)
select id, coalesce(theme, 'system'), coalesce(language, 'de')
from fr_user;

-- 5) Drop settings columns from fr_user
alter table fr_user
    drop column theme,
    drop column language;
