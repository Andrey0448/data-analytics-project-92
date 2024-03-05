/*считает общее количество покупателей*/
select count(customer_id) as customers_count
from customers;


/*Запрос считает количество сделок и выручку каждого продавца*/
select
    emp.first_name || ' ' || emp.last_name as seller,
    count(sal.sales_id) as operations,
    floor(sum(sal.quantity * pr.price)) as income
from sales as sal
left join products as pr
    on sal.product_id = pr.product_id
left join employees as emp
    on sal.sales_person_id = emp.employee_id
group by emp.first_name, emp.last_name
order by income desc
limit 10;


/*Чья средняя выручка из продавцов ниже средней выручки всех продавцов*/   
with average_dep_income as (
    select avg(sal.quantity * pr.price) as average_dep_income
    --ищем среднюю выручку за сделку всех продавцов
    from sales as sal
    left join products as pr
        on sal.product_id = pr.product_id
)

select
    emp.first_name || ' ' || emp.last_name as seller,
    floor(avg(sal.quantity * pr.price)) as average_income
    --средняя выручка каждого продавца
from sales as sal
left join products as pr
    on sal.product_id = pr.product_id
left join employees as emp
    on sal.sales_person_id = emp.employee_id
cross join average_dep_income as dep
group by emp.first_name, emp.last_name, dep.average_dep_income
having avg(sal.quantity * pr.price) < dep.average_dep_income
order by average_income;


/*выручка каждого продавца по дням недели*/
with group_weekday as (
    select
        emp.first_name || ' ' || emp.last_name as seller,
        --приводим дату в формат названия дня недели
        to_char(sal.sale_date, 'day') as day_of_week,
        --приводим дату в формат порядкового номера дня недели
        to_char(sal.sale_date, 'id') as number_weekday,
        sum(sal.quantity * pr.price) as income
    from sales as sal
    left join products as pr
        on sal.product_id = pr.product_id
    left join employees as emp
        on sal.sales_person_id = emp.employee_id
    group by emp.first_name, emp.last_name, sal.sale_date
    order by to_char(sal.sale_date, 'ID'), seller
)

select
    seller,
    day_of_week,
    floor(sum(income)) as income
from group_weekday
group by seller, day_of_week, number_weekday
order by number_weekday, seller;


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
    count(customer_id) as age_count

from category_age
group by age_category
order by age_category;


/*Количество покупателей и выручки, по месяцам*/
with income as (
    select
        sal.customer_id--преобразуем дату в нужный фомат
        , to_char(sal.sale_date, 'yyyy-mm') as selling_month-- noqa: LT04
        , (sal.quantity * pr.price) as income
    from sales as sal
    left join products as pr
        on sal.product_id = pr.product_id
)

select
    selling_month
    --количество уникальных покупателей
    , count(distinct customer_id) as total_customers
    , floor(sum(income)) as income--сумируем выручку
from income
group by selling_month;



/*покупатели,совершившие первую покупку в период акции*/
with first_buy_promotion as (
    select distinct
        sal.customer_id,
        --находим первую дату покупки когда товар стоил 0
        first_value(sal.sale_date)
            over (partition by sal.customer_id order by sal.sale_date)
        as sale_date
    from sales as sal
    left join products as pr
        on sal.product_id = pr.product_id
    where pr.price = '0'--условие на цену товара
),

first_buy as (
    select distinct
        sal.customer_id,
        cus.first_name || ' ' || cus.last_name as customer,
        --находим первую покупку покупателя
        first_value(sal.sale_date)
            over (
                partition by sal.customer_id, sal.sales_person_id
                order by sal.sale_date
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
order by buy.customer_id;
