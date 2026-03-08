use luminar;
select * from orderwind;
select c.id,c.name,c.age,c.location,c.salary,o.oid,o.dat,o.id,o.amount from customwind c right outer join orderwind o on (c.id=o.id);
select * from moviesnew where name like 'a%';
select * from moviesnew where name like '%k';
select * from moviesnew where name like '_a%';
select * from moviesnew where name like '%a%';
select * from customwind where age between 25 and 50;
select c.id,c.name,c.age,c.location,c.salary,o.oid,o.dat,o.id,o.amount from customwind c join orderwind o on (c.id=o.id);
create  view tra1 as select * from transwind where dat like '02%';
select * from tra1;
select category, count(*) as abc from transwind group by category order by abc desc;
select c.name,c.age,o.order from customwind c join orderwind o on (c.id=o.id);
select c. *,o.dat,o.amount;

select * from base;