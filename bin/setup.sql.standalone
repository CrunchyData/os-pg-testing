
create user CRUNCHY_USER with password 'CRUNCHY_PSW';

create database CRUNCHY_DB;

grant all privileges on database CRUNCHY_DB to CRUNCHY_USER;

\c CRUNCHY_DB CRUNCHY_USER;

create schema CRUNCHY_USER;

create table CRUNCHY_USER.testtable (
	name varchar(30) primary key,
	value varchar(50) not null,
	updatedt timestamp not null
);



insert into CRUNCHY_USER.testtable (name, value, updatedt) values ('CPU', '256', now());
insert into CRUNCHY_USER.testtable (name, value, updatedt) values ('MEM', '512m', now());
