#year wise sales analysis with number of customers

use sales_analytics;
select year( order_date) as oder_year, sum(sales_amount) as total_sales,count(distinct customer_key) as total_customer
 from sales_clnd group by year(order_date) order by year(order_date) ;

# calc the total sales per month
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    SUM(sales_amount) AS total_sales
FROM sales_clnd
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;

# running total of sales over time

select month,total_sales,
sum(total_sales) over ( order by month) as runningsales
 from(
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    SUM(sales_amount) AS total_sales
FROM sales_clnd
GROUP BY DATE_FORMAT(order_date, '%Y-%m'))t;

# total sales generated based on gender
select c.gender,
SUM(s.sales_amount) AS total_sales
FROM sales_clnd s
JOIN custmrclnd  c
ON s.customer_key = c.customer_key
GROUP BY c.gender order by total_sales desc;
# merging custromer name
CREATE VIEW customernames as
SELECT CONCAT(first_name, ' ', last_name) AS customer_name,customer_key
FROM custmrclnd;

# WHICH CUSTOMERS SPENT MORE THAN AVG SALES AMUNT
SELECT c.customer_name,sum(s.sales_amount) as total_sales,avg(s.sales_amount) as avg_sales
from sales_clnd s join customernames c on s.customer_key=c.customer_key group by c.customer_name
having total_sales > avg_sales order by total_sales desc;

# analyze the yearly perfomance of a product by comparing their  average sales perfomance

create view  current__sales as
select year(s.order_date)as order_year,p.product_name as product_name,sum(s.sales_amount) as total_sales
from sales_clnd s join productclnd p on s.product_key=p.product_key
group by year(s.order_date),p.product_name;

select order_year,product_name,total_sales,avg(total_sales ) over ( partition by product_name) as avg_sales,
total_sales- AVG(total_sales) OVER (PARTITION BY product_name) AS diff_avg,
CASE WHEN total_sales- AVG(total_sales) OVER (PARTITION BY product_name)> 0 THEN 'Above Avg'
WHEN total_sales- AVG(total_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg' ELSE 'Avg'
END avg_change FROM current__sales ORDER BY product_name,order_year;


# analyse current sales of a product by previous yr sales
select order_year,product_name,total_sales,
LAG(total_sales) over ( partition by product_name order by order_year) as py_sales ,
total_sales-LAG(total_sales) over ( partition by product_name order by order_year) as diff_py,
CASE when total_sales-LAG(total_sales) over ( partition by product_name order by order_year) >0 then 'Increase'
     when total_sales-LAG(total_sales) over ( partition by product_name order by order_year)<0 then 'Decrease'
     else 'No change'
END py_change
FROM current__sales ORDER BY product_name,order_year;

# which catogory contribute the most overall sales
create view category_sales as
select p.category,SUM(s.sales_amount) as total_sales
FROM sales_clnd s LEFT JOIN productclnd p
ON p.product_key = s.product_key GROUP BY p.category;

SELECT category,total_sales,
       SUM(total_sales) OVER() AS overall_sales,
       CONCAT(ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales) OVER()) * 100, 2), '%') 
       AS percentage_of_total FROM category_sales ORDER BY total_sales DESC;


# categorise customers based on total spending into VIP,REGULAR,NEW.
create view customer as
SELECT c.customer_key,
SUM(S.sales_amount) AS total_spending,
MIN(order_date) AS first_order,
MAX(order_date) AS last_order,
DATEDIFF( MIN(order_date), MAX(order_date)) AS lifespan
FROM sales_clnd s JOIN custmrclnd c ON s.customer_key = c.customer_key
GROUP BY c.customer_key;

SELECT  customer_key, total_spending, lifespan,
CASE WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
ELSE 'New'
END customer_segment FROM customer;


######################
create view  sales_report_customer as
with base as(
select s.order_number,s.product_key,s.order_date,s.sales_amount,s.quantity,c.customer_key,c.customer_number,
c.first_name,c.last_name,concat(c.first_name, ' ',c.last_name) as customer_name,c.birthdate ,
timestampdiff(YEAR,c.birthdate,now())  AS age
 from sales_clnd s 
join custmrclnd c on c.customer_key=s.customer_key
),


 aggregation as(
SELECT 
customer_key,
customer_number,
customer_name,
age,
COUNT(DISTINCT order_number) AS total_orders,
SUM(sales_amount) AS total_sales,
SUM(quantity) AS total_quant,
COUNT(DISTINCT product_key) AS total_products,
MAX(order_date) AS last_order_date,
timestampdiff(month,min(order_date),max(order_date)) as lifespan
FROM base
GROUP BY 
customer_key,
customer_number,
customer_name,
age)


select customer_key,
customer_number,
customer_name,
age,
case
    when lifespan >=12 and total_sales >5000 then 'VIP'
    when lifespan >=12 and total_sales <=5000 then 'Regular'
    else 'NEW' end as customer_category,
    last_order_date,
    timestampdiff(month,last_order_date,now()) as recency,
total_orders,
total_sales/total_orders as  avg_ordervalue,
total_sales, total_quant,
case when lifespan=0 then total_sales
else total_sales/lifespan end as avg_monthspend,
 total_products, 
 lifespan
from aggregation;
#avg order value= total sale / tot numb of order
#average monthly spend= total sales/numb of months

create view product_analysis_report as
with base1 as(
select s.order_number,s.order_date,s.customer_key,s.sales_amount,s.quantity,
p.product_key,p.product_name,p.category,p.subcategory,p.cost
FROM sales_clnd s JOIN productclnd p
ON s.product_key = p.product_key)
,


product_aggregation AS (
SELECT product_key,product_name,category,subcategory,cost,
TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
MAX(order_date) AS last_sale_date,

COUNT(DISTINCT order_number) AS total_orders,
COUNT(DISTINCT customer_key) AS total_customers,

SUM(sales_amount) AS total_sales,
SUM(quantity) AS total_quantity,

ROUND(SUM(sales_amount) / NULLIF(SUM(quantity),0),1) AS avg_selling_price

FROM base1 GROUP BY product_key,product_name,category,subcategory,cost)


######
 SELECT product_key,product_name,category,subcategory,cost,last_sale_date,
timestampdiff(MONTH, last_sale_date, now()) AS recency_in_months,

CASE
WHEN total_sales > 50000 THEN 'High-Performer'
WHEN total_sales >= 10000 THEN 'Mid-Range'
ELSE 'Low-Performer'
END AS product_segment,
lifespan,
total_orders,
total_sales,total_quantity,total_customers,avg_selling_price,

#Average Order Revenue (AOR)

CASE
WHEN total_orders = 0 THEN 0
ELSE total_sales / total_orders
END AS avg_order_revenue,

#Average Monthly Revenue
CASE

WHEN lifespan = 0 THEN total_sales

ELSE total_sales / lifespan

END AS avg_monthly_revenue FROM product_aggregation;










