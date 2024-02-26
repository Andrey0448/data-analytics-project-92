/*считает общее количество покупателей из таблицы customers*/
SELECT 
   count(customer_id) AS customers_count 
FROM customers


/*Запрос считает количество сделок и выручку каждого продавца,выберает 10 продавцов, у которых выручка наибольшая, и сортирует данные по убыванию выручки*/
select 
    emp.first_name||' '|| emp.last_name as name
   ,count(sal.sales_id) as operations
   ,FLOOR(sum(sal.quantity*pr.price)) as income
   from sales as sal
     left join products pr
        on sal.product_id=pr.product_id
     left join employees emp   
        on sal.sales_person_id=emp.employee_id
   group by first_name,last_name
   order by income desc
    limit 10


/*Запрос показывает чья средняя выручка из продавцов ниже средней выручки всех продавцов*/
   
with average_income_vseh  as
(
 select 
    avg(sal.quantity*pr.price) as average_income_vseh --ищем среднюю выручку за сделку всех продавцов
  from sales sal
    left join products pr
      on sal.product_id=pr.product_id
)
 select
   emp.first_name||' '||emp.last_name as name
   ,FLOOR(avg(sal.quantity*pr.price)) as average_income  --средняя выручка каждого продавца
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
   ,sum(sal.quantity*pr.price) as income
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
     ,FLOOR(sum(income)) as income
   from group_weekday
   group by name,weekday,number_weekday
   order by number_weekday,name


/*Количество покупателей по возрастным группам*/
with category_age as
(
  select
     CASE WHEN age BETWEEN '16' AND '25' THEN '16-25'
         WHEN age BETWEEN '26' AND '40' THEN '26-40'
         WHEN age>'40' THEN '40+'
     END AS age_category  --Создаём возрастные группы         
    ,customer_id 
   FROM customers
 )
   select 
      age_category
      ,count(customer_id) as count --считаем количество по каждой созданной возрастной группе
      
      from category_age
      group by age_category
      order by age_category


/*Количество покупателей и выручки,которую они прнинесли по месяцам*/
with incom as
(
  select
     TO_CHAR(sale_date,'yyyy-mm') as date--преобразуем дату в нужный фомат
     ,sal.customer_id
     ,(sal.quantity*pr.price) as income--считаем выручку за кажую покупку
  from sales as sal
    left join products pr
      on sal.product_id=pr.product_id
)
   select 
      date
     ,count(distinct customer_id) as total_customers --количество уникальных покупателей
     ,FLOOR(sum(incom)) as income--сумируем выручку
   from incom
   group by date


/*Находим покупателей,которые совершили первую покупку в период акции(акционные товары отпускали со стоимостью равной 0)*/
with first_buy_promotion as
  (select distinct
     sal.customer_id
    ,first_value(sale_date) over (partition by sal.customer_id order by sale_date) as sale_date--находим первую дату покупки когда товар стоил 0
  from sales sal
    left join products pr
      on sal.product_id=pr.product_id
      where price='0'--условие на цену товара)
     
 ,first_buy as
  (select distinct
     sal.customer_id
    ,cus.first_name||' '||cus.last_name as customer 
    ,first_value(sale_date) over (partition by sal.customer_id,sal.sales_person_id order by sale_date) as sale_date--находим первую покупку покупателя
    ,emp.first_name||' '||emp.last_name as seller
  from sales sal
    left join customers  cus
      on sal.customer_id=cus.customer_id
    left join employees emp
      on sal.sales_person_id=emp.employee_id)
      
   select
     buy.customer
    ,buy.sale_date
    ,buy.seller
   from first_buy buy
     inner join first_buy_promotion buy_pr
       on buy.customer_id=buy_pr.customer_id
       and buy.sale_date=buy_pr.sale_date--сравниваем даты покупок
   order by buy.customer_id
