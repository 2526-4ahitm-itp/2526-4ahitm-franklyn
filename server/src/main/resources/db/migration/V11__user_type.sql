create type fr_user_type as enum ('TEACHER', 'STUDENT');

alter table fr_user
    add column role fr_user_type;

update fr_user
set role = 'TEACHER'
where exists (
    select 1
    from fr_teacher
    where fr_teacher.id = fr_user.id
);

update fr_user
set role = 'STUDENT'
where role is null
  and exists (
    select 1
    from fr_student
    where fr_student.id = fr_user.id
  );

update fr_user
set role = 'STUDENT'
where role is null;

alter table fr_user
    alter column role set not null;
