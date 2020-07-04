--№1, взято из лекций 
SELECT DBMS_METADATA.GET_DDL('USER', USERNAME) || '/' DDL FROM DBA_USERS where username = 'HR'
UNION ALL
SELECT DBMS_METADATA.GET_GRANTED_DDL('TABLESPACE_QUOTA', USERNAME) || '/' DDL 
FROM DBA_USERS where username in (select username from dba_ts_quotas where username = 'HR')
UNION ALL
SELECT DBMS_METADATA.GET_GRANTED_DDL('ROLE_GRANT', USERNAME) || '/' DDL 
FROM DBA_USERS where username in (select grantee from dba_role_privs where grantee = 'HR')
UNION ALL
SELECT DBMS_METADATA.GET_GRANTED_DDL('SYSTEM_GRANT', USERNAME) || '/' DDL
FROM DBA_USERS where username in (select grantee from dba_sys_privs where grantee = 'HR' )
UNION ALL
SELECT DBMS_METADATA.GET_GRANTED_DDL('OBJECT_GRANT', USERNAME) || '/' DDL
FROM DBA_USERS where username in (select grantee from dba_tab_privs where grantee = 'HR');

--№2, запускать по очереди, select необязателен, чисто для демонстрации, как и rollback
SET TRANSACTION read write; --Необязательно, поскольку стоит по умолчанию
select * from countries;
DELETE FROM countries WHERE country_id='AR';
select * from countries;

SET TRANSACTION read only;
select * from countries;
DELETE FROM countries WHERE country_id='AR'; --№Должно выдать ошибку. Без ошибки что-то не так
select * from countries;

--№3, запросы выдают одинаковый результат, однако первый сортирует всё сразу, а не хранит кучу данных до having
select department_id, max(salary) from employees where salary>10000 group by department_id;
select department_id, max(salary) from employees group by department_id having max(salary)>10000;

--№4 
select department_id, max(salary), avg(salary) from employees group by department_id
union all
select 0, max(salary), avg(salary) from employees;

--№4 
select DISTINCT department_id, 
max(salary) over(PARTITION BY department_id) as max_sal_dep,
avg(salary) over(PARTITION BY department_id) as avg_sal_dep,
max(salary) over() as max_sal_comp,
avg(salary) over() as avg_sal_comp
from employees;

--№5
drop table my_table1;
create table my_table1(my_id1 number(3));
drop table my_table2;
create table my_table2(my_id2 number(3));

drop sequence my_sqn;
create sequence my_sqn 
start WITH 1
INCREMENT by 1
MINVALUE 1
MAXVALUE 4
NOCYCLE;

create or replace trigger my_trigger_one
before insert on my_table1 for EACH ROW
declare
    i number(3):=0;
begin
    select my_sqn.nextval into i from dual;
    if i=4 then
        dbms_output.put_line('The end of work my_trigger1');
    else begin
        insert into my_table2 values(2);
    end;
    END IF;
end;
/

create or replace trigger my_trigger_two
before insert on my_table2 for EACH ROW
declare
    i number(3);
begin
    select my_sqn.nextval into i from dual;
    if i=4 then
        dbms_output.put_line('The end of work my_trigger2');
    else
        insert into my_table1 values(1);
    end if;
end;
/

insert into my_table1 values(1);
select * from my_table1;
select * from my_table2;
delete from my_table1;
delete from my_table2;
select my_sqn.currval from dual;

--№6, при уменьшении можно предварительно скопировать данные в другую таблицу (create table new_table as countries, скажем)
alter table countries modify country_name varchar(60);
alter table countries modify country_name varchar(40);
alter table countries drop column country_name;

--№7
set SERVEROUTPUT on;
create or replace type emp_names as object(
    first_name varchar(50),
    last_name varchar(50),
    map member function area return number);
/

create or replace type body emp_names as
    map member function area return number is
    begin
        return length(first_name) + length(last_name);
    end area;
end;
/

DECLARE
    emp1 emp_names;
    emp2 emp_names;
    big_obj Integer;
begin
    emp1 := new emp_names('Alex', 'Smith');
    emp2 := new emp_names('Woldemar', 'Rostenkovski');
    if emp1>emp2 then
        dbms_output.put_line(emp1.first_name||' '||emp1.last_name);
    else
        dbms_output.put_line(emp2.first_name||' '||emp2.last_name);    
    end if;
end;
/

--№8, скорее всего важен лишь запрос курсора, но написано ещё и его использование
set SERVEROUTPUT on;
declare
  v_num constant number(8):=4;
  cursor my_cursor is
    select * from (select * from countries order by country_id desc) where rownum<=v_num
    union all
    select * from countries where rownum <= v_num;
  v_id countries.country_id%type;  
  v_name countries.country_name%type;
  v_r_id countries.region_id%type;
BEGIN
open my_cursor; 
LOOP
  fetch my_cursor into v_id, v_name, v_r_id;
  exit when my_cursor%notfound;
  DBMS_OUTPUT.PUT_LINE(v_id || ', ' || v_name || ', ' || v_r_id);
end loop;
close my_cursor;
end;

--№8, вариант со вводом с клавиатуры
set SERVEROUTPUT on;
declare
  v_number number(10);
  cursor my_cursor (v_num in integer) is
    select * from (select * from countries order by country_id desc) where rownum<=v_num
    union all
    select * from countries where rownum <= v_num;
  v_id countries.country_id%type;  
  v_name countries.country_name%type;
  v_r_id countries.region_id%type;
BEGIN
v_number:='&Number_of_records';
open my_cursor(v_number); 
LOOP
  fetch my_cursor into v_id, v_name, v_r_id;
  exit when my_cursor%notfound;
  DBMS_OUTPUT.PUT_LINE(v_id || ', ' || v_name || ', ' || v_r_id);
end loop;
close my_cursor;
end;

--№9
set SERVEROUTPUT on;
drop table my_table_one;
create table my_table_one(my_id number(10), my_name varchar(50), my_sal number(10));

drop package body my_package_one;
drop package my_package_one;
create or replace package my_package_one is
    procedure my_ins(ins_id in number, ins_name in varchar, ins_sal in number);
    procedure my_del(del_id in number);
end my_package_one;
/

create or replace package body my_package_one is
    procedure my_ins(ins_id in number, ins_name in varchar, ins_sal in number) is
    begin
        insert into my_table_one values(ins_id, ins_name, ins_sal);
        dbms_output.put_line('Your data was inserted');
    end my_ins;
    procedure my_del(del_id in number) is
    begin
        delete from my_table_one where my_id = del_id;
        dbms_output.put_line('Your data was deleted');
    end my_del;
begin
    dbms_output.put_line('Package was downloaded');
end my_package_one;
/

exec my_package_one.my_ins(1, 'Alex', 980);
select * from my_table_one;

--№10
drop table my_countries;
drop table my_regiones;

create table my_regiones(region_id_ number primary key,
region_name_ varchar(50));
create table my_countries(country_id_ char(2) primary key,
country_name_ varchar2(60), region_id_ number references my_regiones(region_id_));

insert into my_regiones values(1, 'Europe');
insert into my_regiones values(2, 'Americas');
insert into my_regiones values(3, 'Asia');

insert into my_countries values('AR', 'Argentina', 2);
insert into my_countries values('AU', 'Australia', 3);
insert into my_countries values('BE', 'Belgium', 1);
insert into my_countries values('BR', 'Brazil', 2);
insert into my_countries values('CA', 'Canada', 2);
insert into my_countries values('CH', 'Switzerland', 1);
insert into my_countries values('CN', 'China', 3);

drop view country_regions_view;
create view country_regions_view AS
    select c.country_id_, c.country_name_, c.region_id_, r.region_name_ 
    from my_countries c, my_regiones r 
    where c.region_id_=r.region_id_;
--=============NO======================
select * from country_regions_view;
insert into country_regions_view(country_id_, country_name_, region_id_) VALUES (15, 'Russia', 4); -- нельзя т.к нет отдела с номером 5
insert into country_regions_view(country_name_, region_id_) VALUES ('Russia', 3);-- нельзя т.к не назначается значение при вставке
--==================Yes========================================================
select * from country_regions_view;
insert into country_regions_view(country_id_, country_name_, region_id_) VALUES (15, 'Russia', 1);
select * from country_regions_view;

--№11
drop table my_emp_one;
create table my_emp_one(my_emp_id number(10) NOT NULL PRIMARY KEY, 
                    my_emp_name varchar2(100) UNIQUE, 
                    my_emp_sal number(8, 2) check (my_emp_sal between 0 and 1000));
comment on table my_emp_one is 'My employees';
comment on column my_emp_one.my_emp_id is 'My employees` id. It`s not null and primary key';
comment on column my_emp_one.my_emp_name is 'My employees` names. This row is unique';
comment on column my_emp_one.my_emp_sal is 'My employees` salaries';

select * from user_tables where table_name='MY_EMP_ONE';
select dbms_metadata.get_ddl('TABLE', 'MY_EMP_ONE', 'HR') from dual;
select * from user_tab_comments c where c.table_name='MY_EMP_ONE';
select * from user_col_comments c where c.table_name='MY_EMP_ONE';

--№13
set SERVEROUTPUT on;
declare
    exc1 Exception;
    my_number number;
begin
    my_number := &my_number;
    if my_number<0 then
        raise exc1;
    else
        dbms_output.put_line('Input number : ' || my_number);    
    end if;
    
    EXCEPTION
    when exc1 then
        dbms_output.put_line('my_number < 0, that`s not good');
END;
/

--№14
select * from user_tablespaces;
select dbms_metadata.get_ddl('TABLESPACE', 'USERS') from dual; --вместо USERS любое название из предыдущего запроса
create tablespace example_tbs datafile 'example_tbs.dbf' size 1m; --название файла придётся обновлять:(

--№15
set SERVEROUTPUT on;
declare
    last_name_emp employees.last_name%type;
begin
    last_name_emp:='&Last_name';
    for cur in (select last_name from employees connect by employee_id = PRIOR manager_id start with last_name=last_name_emp)
    loop
        dbms_output.put_line(cur.last_name);
    end loop;
    
    --exception when no_data_found then dbms_output.put_line('Exception, we don`t find employees');
end;
/

--№16
set SERVEROUTPUT on;
declare
	cursor my_cursor is
	select country_name from countries where region_id=1;
	
	cntry_name countries.country_name%type;
	
	procedure is_cursor_open as
	begin
    	if my_cursor%isopen then
        	dbms_output.put_line('Cursor is open!');
    	else
        	dbms_output.put_line('Cursor isn`t open!');
    	end if;
	end;
	
	
	procedure is_cursor_found as --fetch
	begin
    	if my_cursor%found then
            dbms_output.put_line('Cursor found!');
    	else        	
        	dbms_output.put_line('Cursor isn`t found!');
    	end if;
    	
    	exception
        	when INVALID_CURSOR then
        	dbms_output.put_line('Exception, the cursor is invalid!');
        	
        	when others then
            	raise;
	end;
	
begin
	is_cursor_open;
	open my_cursor;
	is_cursor_open;
	
	is_cursor_found;
	fetch my_cursor into cntry_name;
	is_cursor_open;
	is_cursor_found;
	
	if my_cursor%found then
    	dbms_output.put_line('Fetched : ' || cntry_name);
	end if;
	
	close my_cursor;
	is_cursor_open;
	is_cursor_found;
end;
/

--№17
create or replace procedure count_rec(num_of_rec out number) as
begin
    select count(*) into num_of_rec from countries where region_id=1;
    DBMS_OUTPUT.PUT_LINE(num_of_rec);
end;
/

var x number;
exec :x := 0;
exec count_rec(:x);
print :x;

--№18
select manager_id, count(*) from employees group by manager_id having count(*)>2;

with
query1 as (select e1.first_name as manager_name, e2.first_name as emp_name 
        from employees e1 join employees e2 on (e1.employee_id = e2.manager_id)
        order by manager_name),
query2 as (select manager_name, count(*) as col_ from query1 group by manager_name order by col_ desc)
select query2.* from query2 where col_ > 2; 

--№19
drop sequence my_seq_id;
create sequence my_seq_id
start WITH 100
increment by 10
minvalue 100
NOMAXVALUE
NOCYCLE;

drop table my_table;
create table my_table(my_id number primary key not null, my_name varchar2(50), my_sal number(8, 2));

create or replace trigger my_trigger_id before insert or update on my_table for each row
begin
    :new.my_id := my_seq_id.nextval;
end;
/

select * from my_table;
insert into my_table(my_name, my_sal) values('Alex', 1900);
select * from my_table;
insert into my_table(my_name, my_sal) values('Smith', 1789);
select * from my_table;

--№20
select username, user_id, account_status, default_tablespace, created, external_name from user_users; --звёздочка тоже заработает
select view_name, text_length, text, oid_text_length, oid_text, view_type from user_views;
select * from user_sequences;
select owner, constraint_name, constraint_type, status from user_constraints;

--№21
create view my_view as
select employee_id, first_name, last_name, salary from employees where last_name like 'V%';
select * from my_view;
comment on table my_view is 'This is my view for table employees. It`s work!';
comment on column my_view.employee_id is 'This is column id of employee in table employees and it`s finally work!';
select * from user_tab_comments c where c.table_name='MY_VIEW';
select * from user_col_comments c where c.table_name='MY_VIEW';
select * from user_views where view_name='MY_VIEW';

--№22
drop table my_table;
create table my_table(my_id number(10), my_name varchar2(100), my_sal number(8, 2));

create or replace trigger my_table
before insert or update or delete on my_table for each row
begin
    dbms_output.put_line('Inserted');
    update my_table mt set mt.my_sal = mt.my_sal + 1 where mt.my_id>0; --в процессе вставки строки происходят изменения этой строки
end;
/

insert into my_table values(1, 'Smith', 999);
insert into my_table values(2, 'Alex', 999);
select * from my_table;

--№23, по сути это копия 11
drop table my_emp_one;
create table my_emp_one(my_emp_id number(10) NOT NULL PRIMARY KEY, 
                    my_emp_name varchar2(100) UNIQUE, 
                    my_emp_sal number(8, 2) check (my_emp_sal between 0 and 1000));
comment on table my_emp_one is 'My employees';
comment on column my_emp_one.my_emp_id is 'My employees` id. It`s not null and primary key';
comment on column my_emp_one.my_emp_name is 'My employees` names. This row is unique';
comment on column my_emp_one.my_emp_sal is 'My employees` salaries';

select * from user_tables where table_name='MY_EMP_ONE';
select dbms_metadata.get_ddl('TABLE', 'MY_EMP_ONE', 'HR') from dual;
select * from user_tab_comments c where c.table_name='MY_EMP_ONE';
select * from user_col_comments c where c.table_name='MY_EMP_ONE';









