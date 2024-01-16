select * from persons
where name = 'Simon Pegg';

select pg_terminate_backend('123');

begin;
update persons set  birthdate = '2000-01-02'
where name = 'Quentin Tarantino';

update persons set  birthdate = '2000-06-01'
where name = 'Simon Pegg';


rollback;