/*считает общее количество покупателей из таблицы customers*/
SELECT count(customer_id) AS customers_count
FROM customers


/*Запрос считает количество сделок и выручку каждого продавца,выберает 10 продавцов, у которых выручка наибольшая, и сортирует данные по убыванию выручки*/
select
    emp.first_name || ' ' || emp.last_name as name,
    count(sal.sales_id) as operations,
    floor(sum(sal.quantity * pr.price)) as income
from sales as sal
left join products as pr
    on sal.product_id = pr.product_id
left join employees as emp
    on sal.sales_person_id = emp.employee_id
group by first_name, last_name
order by income desc
limit 10


/*Запрос показывает чья средняя выручка из продавцов ниже средней выручки всех продавцов*/
   
with average_dep_income as (
    select avg(sal.quantity * pr.price) as average_dep_income
    --ищем среднюю выручку за сделку всех продавцов
    from sales as sal
    left join products as pr
        on sal.product_id = pr.product_id
)

select
    emp.first_name || ' ' || emp.last_name as name,
    floor(avg(sal.quantity * pr.price)) as average_income 
    --средняя выручка каждого продавца
from sales as sal
left join products as pr
    on sal.product_id = pr.product_id
left join employees as emp
    on sal.sales_person_id = emp.employee_id
cross join average_dep_income
group by first_name, last_name, average_dep_income
having avg(sal.quantity * pr.price) <average_dep_income
order by average_income


   /*выручка каждого продавца по дням недели*/
with group_weekday as (
    select
        emp.first_name || ' ' || emp.last_name as name,
        --приводим дату в формат названия дня недели
        to_char(sal.sale_date, 'day') as weekday,
        --приводим дату в формат порядкового номера дня недели
        to_char(sal.sale_date, 'id') as number_weekday,
        sum(sal.quantity * pr.price) as income
    from sales as sal
    left join products as pr
        on sal.product_id = pr.product_id
    left join employees as emp
        on sal.sales_person_id = emp.employee_id
    group by emp.first_name, emp.last_name, sale_date
    order by to_char(sal.sale_date, 'ID'), name
)

select
    name,
    weekday,
    floor(sum(income)) as income
from group_weekday
group by name, weekday, number_weekday
order by number_weekday, name


/*Количество покупателей по возрастным группам*/
with category_age as (
    select
        customer_id,  --Создаём возрастные группы         
        case
            when age between '16' and '25' then '16-25'
            when age between '26' and '40' then '26-40'
            when age > '40' then '40+'
        end as age_category
    from customers
)

select
    age_category,
    --считаем количество по каждой созданной возрастной группе
    count(customer_id) as count

from category_age
group by age_category
order by age_category



/*Количество покупателей и выручки,которую они прнинесли по месяцам*/
with income as (
    select
        sal.customer_id--преобразуем дату в нужный фомат
        , TO_CHAR(sale_date, 'yyyy-mm') as date
        , (sal.quantity * pr.price) as income--считаем выручку за кажую покупку
    from sales as sal
    left join products as pr
        on sal.product_id = pr.product_id
)

select
    date
    --количество уникальных покупателей
    , COUNT(distinct customer_id) as total_customers
    , FLOOR(SUM(income)) as income--сумируем выручку
from income
group by date



/*Находим покупателей,которые совершили первую покупку в период акции(акционные товары отпускали со стоимостью равной 0)*/
with first_buy_promotion as (
    select distinct
        sal.customer_id,
        --находим первую дату покупки когда товар стоил 0
        first_value(sale_date)
            over (partition by sal.customer_id order by sale_date)
        as sale_date
    from sales as sal
    left join products as pr
        on sal.product_id = pr.product_id
    where price = '0'--условие на цену товара
),

first_buy as (
    select distinct
        sal.customer_id,
        cus.first_name || ' ' || cus.last_name as customer,
        --находим первую покупку покупателя
        first_value(sale_date)
            over (
                partition by sal.customer_id, sal.sales_person_id
                order by sale_date
            )
        as sale_date,
        emp.first_name || ' ' || emp.last_name as seller
    from sales as sal
    left join customers as cus
        on sal.customer_id = cus.customer_id
    left join employees as emp
        on sal.sales_person_id = emp.employee_id
)

select
    buy.customer,
    buy.sale_date,
    buy.seller
from first_buy as buy
inner join first_buy_promotion as buy_pr
    on
        buy.customer_id = buy_pr.customer_id
        and buy.sale_date = buy_pr.sale_date--сравниваем даты покупок
order by buy.customer_id
