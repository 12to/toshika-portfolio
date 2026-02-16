SELECT * FROM mysql1.credit_card_transcations;
/*write a query to print top 5 cities with highest spends  and their percentage contribution of total credit card spends*/
with cte1 as (select city, sum(amount) as Total_spend from credit_card_transcations group by city)
,total_spent as (select sum(amount) as Total_amount from credit_card_transcations)
select cte1.*, 
round(total_spend*1.0/total_amount * 100,2) as Percentage_contribution from 
cte1 inner join total_spent on 1=1
order by total_spend desc 
limit 5;
/*--2- write a query to print highest spend month and amount spent in that month for each card type*/
WITH monthly_spend AS ( SELECT card_type,
        YEAR(STR_TO_DATE(transaction_date,'%d-%b-%y')) AS yr, MONTH(STR_TO_DATE(transaction_date,'%d-%b-%y')) AS mn,
        SUM(amount) AS total_spend
    FROM credit_card_transcations
    GROUP BY card_type, yr, mn
)SELECT card_type, yr, mn, total_spend
FROM ( SELECT *,ROW_NUMBER() OVER (PARTITION BY card_type ORDER BY total_spend DESC) rn FROM monthly_spend) x WHERE rn = 1;
/*-3- write a query to print the transaction details(all columns from the table) for each card type when 
it reaches a cumulative of  1,000,000 total spends(We should have 4 rows in the o/p one for each card type)*/
with cte as (
select *,sum(amount) over(partition by card_type order by transaction_date,transaction_id) as total_spend
from credit_card_transcations order by card_type,total_spend desc
) select * from (select *, rank() over(partition by card_type order by total_spend) as rn  
from cte where total_spend >= 1000000) a where rn=1 ;
/*-4- write a query to find city which had lowest percentage spend for gold card type*/
SELECT city,
       SUM(CASE WHEN card_type = 'Gold' THEN amount ELSE 0 END) /
       SUM(amount) AS gold_ratio
FROM credit_card_transcations
GROUP BY city
HAVING SUM(CASE WHEN card_type='Gold' THEN amount ELSE 0 END) > 0
ORDER BY gold_ratio
LIMIT 1;
WITH cte AS (
    SELECT city, exp_type, SUM(amount) AS total_amount
    FROM credit_card_transcations
    GROUP BY city, exp_type
) SELECT city,
    MAX(CASE WHEN rn_asc = 1 THEN exp_type END) AS lowest_exp_type,
    MAX(CASE WHEN rn_desc = 1 THEN exp_type END) AS highest_exp_type
FROM ( SELECT *,
           ROW_NUMBER() OVER (PARTITION BY city ORDER BY total_amount ASC) rn_asc,
           ROW_NUMBER() OVER (PARTITION BY city ORDER BY total_amount DESC) rn_desc
    FROM cte ) t GROUP BY city;
/*6- write a query to find percentage contribution of spends by females for each expense type */
SELECT exp_type,
SUM(CASE WHEN gender='F' THEN amount ELSE 0 END)*1.0/SUM(amount) 
AS percentage_female_contribution
FROM credit_card_transcations
GROUP BY exp_type
ORDER BY percentage_female_contribution DESC;
/* Q7 — Highest MoM growth in Jan-2014 */
WITH cte AS (
    SELECT 
        card_type,
        exp_type,
        YEAR(STR_TO_DATE(transaction_date,'%d-%b-%y')) yt,
        MONTH(STR_TO_DATE(transaction_date,'%d-%b-%y')) mt,
        SUM(amount) total_spend
    FROM credit_card_transcations
    GROUP BY card_type, exp_type, yt, mt
)
SELECT *,
       total_spend - prev_month_spend AS mom_growth
FROM (
    SELECT *,
           LAG(total_spend) OVER (
               PARTITION BY card_type, exp_type
               ORDER BY yt, mt
           ) prev_month_spend
    FROM cte
) A
WHERE prev_month_spend IS NOT NULL
  AND yt = 2014 AND mt = 1
ORDER BY mom_growth DESC
LIMIT 1;
/*8 — Weekend city with highest spend/transaction ratio */
SELECT city,
       SUM(amount)/COUNT(*) AS ratio
FROM credit_card_transcations
WHERE DAYOFWEEK(STR_TO_DATE(transaction_date,'%d-%b-%y')) IN (1,7)
GROUP BY city
ORDER BY ratio DESC
LIMIT 1;
/* 9 — City reaching 500th transaction fastest */
WITH cte AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY city
               ORDER BY STR_TO_DATE(transaction_date,'%d-%b-%y'), transaction_id
           ) rn
    FROM credit_card_transcations
)
SELECT city,
       DATEDIFF(
           MAX(STR_TO_DATE(transaction_date,'%d-%b-%y')),
           MIN(STR_TO_DATE(transaction_date,'%d-%b-%y'))
       ) AS days_taken
FROM cte
WHERE rn IN (1,500)
GROUP BY city
HAVING COUNT(*) = 2
ORDER BY days_taken
LIMIT 1;