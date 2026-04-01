alter table fr_notice 
alter column content type varchar(4096),
alter column content set not null,
alter column type set not null;