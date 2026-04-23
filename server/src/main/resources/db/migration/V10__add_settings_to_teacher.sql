create type fr_settings_theme as enum ('light', 'dark', 'system');

alter table fr_teacher
add column theme fr_settings_theme default 'system',
add column language varchar(10) default 'de';