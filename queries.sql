/*считает общее количество покупателей из таблицы customers*/
SELECT 
   count(customer_id) AS customers_count 
FROM customers


/*Запрос считает количество сделок и выручку каждого продавца,выберает 10 продавцов, у которых выручка наибольшая, и сортирует данные по убыванию выручки*/
select 
    emp.first_name||' '|| emp.last_name as name
   ,count(sal.sales_id) as operations
   ,round(sum(sal.quantity*pr.price)) as incom
   from sales as sal
     left join products pr
        on sal.product_id=pr.product_id
     left join employees emp   
        on sal.sales_person_id=emp.employee_id
   group by first_name,last_name
   order by incom desc
    limit 10


/*Запрос показывает чья средняя выручка из продавцов ниже средней выручки всех продавцов*/
   
with average_income_vseh  as
(
 select 
   avg(sal.quantity*pr.price) as average_income_vseh --ищем среднюю выручку за сделку всех продавцов
  from sales sal
    left join products pr
      on sal.product_id=pr.product_id
    left join employees emp 
      on sal.sales_person_id=emp.employee_id
)
 select
   emp.first_name||' '||emp.last_name as name
   ,round(avg(sal.quantity*pr.price)) as average_income  --средняя выручка каждого продавца
  from sales sal
    left join products pr
      on sal.product_id=pr.product_id
    left join employees emp 
      on sal.sales_person_id=emp.employee_id
    CROSS JOIN average_income_vseh 
    group by first_name,last_name,average_income_vseh
    having avg(sal.quantity*pr.price) < average_income_vseh 
    order by average_income


   /*выручка каждого продавца по дням недели*/
with group_weekday as 
(
select
   emp.first_name||' '||emp.last_name as name
   ,to_char(sal.sale_date, 'day') as weekday   --приводим дату в формат названия дня недели
   ,to_char(sal.sale_date, 'id') as number_weekday  --приводим дату в формат порядкового номера дня недели
   ,sum(sal.quantity*pr.price) as incom
  from sales sal
    left join products pr
      on sal.product_id=pr.product_id
    left join employees emp 
      on sal.sales_person_id=emp.employee_id
  group by emp.first_name,emp.last_name,sale_date
  order by to_char(sal.sale_date, 'ID'),name
  )
  select 
     name
     ,weekday
     ,round(sum(incom)) as incom 
   from group_weekday
   group by name,weekday,numer_weekday
   order by number_weekday,name

