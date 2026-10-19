create table fr_notice_content (
    notice_id uuid not null references fr_notice (id) on delete cascade,
    language varchar(10) not null,
    content varchar(4096) not null,

    primary key (notice_id, language)
);

-- existing notices were written without a language; fr_user.language defaults to 'de'
insert into fr_notice_content (notice_id, language, content)
select id, 'de', content from fr_notice;

alter table fr_notice drop column content;
