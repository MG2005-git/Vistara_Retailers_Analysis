use vistara_db;

select * from vistara;
select distinct category from vistara;


-- Scale of the analysis 

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT invoice_id) AS total_transactions,
    COUNT(DISTINCT branch) AS total_branches,
    COUNT(DISTINCT city) AS total_cities,
    COUNT(DISTINCT category) AS total_categories,
    MIN(DATE(date)) AS start_date,
    MAX(DATE(date)) AS end_date,
    ROUND(SUM(total_price), 2) AS total_revenue
FROM vistara;


-- Financial losses and underperforming branches

WITH yearly_sales AS (
    SELECT
        branch,
        YEAR(date) AS sales_year,
        SUM(total_price) AS revenue
    FROM vistara
    GROUP BY branch, sales_year
),
sales_comparison AS (
    SELECT
        branch,
        sales_year,
        revenue,
        LAG(revenue) OVER (
            PARTITION BY branch ORDER BY sales_year
        ) AS previous_revenue
    FROM yearly_sales
)
SELECT
    branch,
    sales_year,
    ROUND(previous_revenue, 2) AS previous_revenue,
    ROUND(revenue, 2) AS current_revenue,
    ROUND(previous_revenue - revenue, 2) AS revenue_lost,
    ROUND(
        (previous_revenue - revenue) * 100.0 /
        NULLIF(previous_revenue, 0), 2
    ) AS decline_percentage
FROM sales_comparison
WHERE revenue < previous_revenue
ORDER BY revenue_lost DESC;


----- 2nd extended 

WITH yearly_sales AS (
    SELECT
        branch,
        YEAR(date) AS sales_year,
        SUM(total_price) AS revenue
    FROM vistara
    GROUP BY branch, sales_year
),
sales_comparison AS (
    SELECT
        branch,
        sales_year,
        revenue,
        LAG(revenue) OVER (
            PARTITION BY branch
            ORDER BY sales_year
        ) AS previous_revenue
    FROM yearly_sales
)
SELECT
    COUNT(*) AS declining_branch_years,
    COUNT(DISTINCT branch) AS affected_branches,
    ROUND(SUM(previous_revenue - revenue), 2)
        AS total_revenue_decline,
    ROUND(MAX(
        (previous_revenue - revenue) * 100.0 /
        NULLIF(previous_revenue, 0)
    ), 2) AS highest_decline_percentage,
    ROUND(AVG(
        (previous_revenue - revenue) * 100.0 /
        NULLIF(previous_revenue, 0)
    ), 2) AS average_decline_percentage
FROM sales_comparison
WHERE revenue < previous_revenue;


-- Potential profitability improvement

SELECT
    category,
    ROUND(SUM(total_price), 2) AS revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(
        SUM(profit) * 100.0 /
        NULLIF(SUM(total_price), 0), 2
    ) AS weighted_profit_margin,
    ROUND(SUM(total_price) * 0.01, 2)
        AS profit_opportunity_at_1pp_improvement
FROM vistara
GROUP BY category
ORDER BY total_profit DESC;


----------------------------------------------------------------------------------
-- 1. Overall Sales & Revenue Performance
----------------------------------------------------------------------------------
-- Q1. How has the company's total revenue changed year over year?

SELECT
    YEAR(date) AS sales_year,
    ROUND(SUM(total_price), 2) AS total_revenue
FROM vistara
GROUP BY YEAR(date)
ORDER BY sales_year;

----------------------------------------------------------------------------------
-- Which months generate the highest and lowest revenue?

SELECT
    MONTH(date) AS month_number,
    MONTHNAME(date) AS month_name,
    ROUND(SUM(total_price), 2) AS total_revenue
FROM vistara
GROUP BY MONTH(date), MONTHNAME(date)
ORDER BY total_revenue DESC;

----------------------------------------------------------------------------------
-- Q3. How does monthly revenue vary across different years?

SELECT
    YEAR(date) AS sales_year,
    MONTH(date) AS month_number,
    MONTHNAME(date) AS month_name,
    ROUND(SUM(total_price), 2) AS monthly_revenue
FROM vistara
GROUP BY
    YEAR(date),
    MONTH(date),
    MONTHNAME(date)
ORDER BY sales_year, month_number;

----------------------------------------------------------------------------------
-- Q4. What is the average transaction value (ATV) for each branch?

SELECT
    branch,
    COUNT(DISTINCT invoice_id) AS total_transactions,
    ROUND(SUM(total_price), 2) AS total_revenue,
    ROUND(
        SUM(total_price) /
        NULLIF(COUNT(DISTINCT invoice_id), 0), 2
    ) AS average_transaction_value
FROM vistara
GROUP BY branch
ORDER BY average_transaction_value DESC;

----------------------------------------------------------------------------------
-- Q5. Which branches have experienced the largest year-over-year decline in revenue?

WITH yearly_sales AS (
    SELECT
        branch,
        YEAR(date) AS sales_year,
        SUM(total_price) AS revenue
    FROM vistara
    GROUP BY branch, YEAR(date)
),
sales_comparison AS (
    SELECT
        branch,
        sales_year,
        revenue,
        LAG(revenue) OVER (
            PARTITION BY branch
            ORDER BY sales_year
        ) AS previous_revenue
    FROM yearly_sales
)
SELECT
    branch,
    sales_year,
    ROUND(previous_revenue, 2) AS previous_revenue,
    ROUND(revenue, 2) AS current_revenue,
    ROUND(previous_revenue - revenue, 2) AS revenue_decline,
    ROUND(
        (previous_revenue - revenue) * 100.0 /
        NULLIF(previous_revenue, 0), 2
    ) AS decline_percentage
FROM sales_comparison
WHERE revenue < previous_revenue
ORDER BY revenue_decline DESC;

----------------------------------------------------------------------------------
-- Q6. What is the overall year-over-year revenue growth rate?

WITH yearly_sales AS (
    SELECT
        YEAR(date) AS sales_year,
        SUM(total_price) AS revenue
    FROM vistara
    GROUP BY YEAR(date)
),
sales_growth AS (
    SELECT
        sales_year,
        revenue,
        LAG(revenue) OVER (
            ORDER BY sales_year
        ) AS previous_revenue
    FROM yearly_sales
)
SELECT
    sales_year,
    ROUND(previous_revenue, 2) AS previous_revenue,
    ROUND(revenue, 2) AS current_revenue,
    ROUND(
        (revenue - previous_revenue) * 100.0 /
        NULLIF(previous_revenue, 0), 2
    ) AS yoy_growth_percentage
FROM sales_growth
ORDER BY sales_year;

----------------------------------------------------------------------------------
-- 2. Branch & City Performance
----------------------------------------------------------------------------------
-- Q7. Which branches contribute the most and least to overall company revenue?

SELECT
    branch,
    ROUND(SUM(total_price), 2) AS branch_revenue,
    ROUND(
        SUM(total_price) * 100.0 /
        (SELECT SUM(total_price) FROM vistara), 2
    ) AS revenue_contribution_percentage
FROM vistara
GROUP BY branch
ORDER BY branch_revenue DESC;

----------------------------------------------------------------------------------
-- Q8. How does revenue contribution vary across different cities?

SELECT
    city,
    ROUND(SUM(total_price), 2) AS city_revenue,
    ROUND(
        SUM(total_price) * 100.0 /
        (SELECT SUM(total_price) FROM vistara), 2
    ) AS revenue_contribution_percentage
FROM vistara
GROUP BY city
ORDER BY city_revenue DESC;

----------------------------------------------------------------------------------
-- Q9. Which branches generate high revenue but have relatively low profit margins?

SELECT
    branch,
    ROUND(SUM(total_price), 2) AS revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(
        SUM(profit) * 100.0 /
        NULLIF(SUM(total_price), 0), 2
    ) AS weighted_profit_margin
FROM vistara
GROUP BY branch
ORDER BY revenue DESC;

----------------------------------------------------------------------------------
-- Q10. Which branches show consistent revenue growth or decline over the analysis period?

WITH yearly_sales AS (
    SELECT
        branch,
        YEAR(date) AS sales_year,
        SUM(total_price) AS revenue
    FROM vistara
    GROUP BY branch, YEAR(date)
),
sales_trend AS (
    SELECT
        branch,
        sales_year,
        revenue,
        LAG(revenue) OVER (
            PARTITION BY branch
            ORDER BY sales_year
        ) AS previous_revenue
    FROM yearly_sales
),
branch_summary AS (
    SELECT
        branch,
        COUNT(*) AS yearly_comparisons,
        SUM(
            CASE
                WHEN revenue > previous_revenue THEN 1
                ELSE 0
            END
        ) AS growth_years,
        SUM(
            CASE
                WHEN revenue < previous_revenue THEN 1
                ELSE 0
            END
        ) AS decline_years
    FROM sales_trend
    WHERE previous_revenue IS NOT NULL
    GROUP BY branch
)
SELECT
    branch,
    yearly_comparisons,
    growth_years,
    decline_years,
    CASE
        WHEN growth_years = yearly_comparisons
            THEN 'Consistent Growth'
        WHEN decline_years = yearly_comparisons
            THEN 'Consistent Decline'
        ELSE 'Mixed Performance'
    END AS performance_trend
FROM branch_summary
ORDER BY decline_years DESC, growth_years DESC;

----------------------------------------------------------------------------------
-- Q11. Which branches have the highest and lowest average transaction values?

SELECT
    branch,
    ROUND(
        SUM(total_price) /
        NULLIF(COUNT(DISTINCT invoice_id), 0), 2
    ) AS average_transaction_value
FROM vistara
GROUP BY branch
ORDER BY average_transaction_value DESC;

----------------------------------------------------------------------------------
-- 3. Product Category Performance & Profitability
----------------------------------------------------------------------------------
-- Q12. Which product categories generate the highest and lowest revenue?

SELECT
    category,
    ROUND(SUM(total_price), 2) AS total_revenue
FROM vistara
GROUP BY category
ORDER BY total_revenue DESC;

----------------------------------------------------------------------------------
-- Q13. Which categories generate high revenue but have relatively low profit margins?

SELECT
    category,
    ROUND(SUM(total_price), 2) AS revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(
        SUM(profit) * 100.0 /
        NULLIF(SUM(total_price), 0), 2
    ) AS weighted_profit_margin
FROM vistara
GROUP BY category
ORDER BY revenue DESC;

----------------------------------------------------------------------------------
-- Q14. Which product categories contribute the most and least to total profit?

SELECT
    category,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(
        SUM(profit) * 100.0 /
        NULLIF((SELECT SUM(profit) FROM vistara), 0), 2
    ) AS profit_contribution_percentage
FROM vistara
GROUP BY category
ORDER BY total_profit DESC;

----------------------------------------------------------------------------------
-- Q15. Which categories have the highest sales volume but contribute relatively less revenue?

SELECT
    category,
    SUM(quantity) AS total_quantity_sold,
    ROUND(SUM(total_price), 2) AS total_revenue,
    ROUND(
        SUM(total_price) /
        NULLIF(SUM(quantity), 0), 2
    ) AS revenue_per_unit
FROM vistara
GROUP BY category
ORDER BY total_quantity_sold DESC;

----------------------------------------------------------------------------------
-- Q16. Which product categories are driving revenue growth or decline between 2022 and 2023?

WITH category_sales AS (
    SELECT
        category,
        YEAR(date) AS sales_year,
        SUM(total_price) AS revenue
    FROM vistara
    WHERE YEAR(date) IN (2022, 2023)
    GROUP BY category, YEAR(date)
),
category_comparison AS (
    SELECT
        category,
        SUM(
            CASE WHEN sales_year = 2022
            THEN revenue ELSE 0 END
        ) AS revenue_2022,
        SUM(
            CASE WHEN sales_year = 2023
            THEN revenue ELSE 0 END
        ) AS revenue_2023
    FROM category_sales
    GROUP BY category
)
SELECT
    category,
    ROUND(revenue_2022, 2) AS revenue_2022,
    ROUND(revenue_2023, 2) AS revenue_2023,
    ROUND(revenue_2023 - revenue_2022, 2) AS revenue_change,
    ROUND(
        (revenue_2023 - revenue_2022) * 100.0 /
        NULLIF(revenue_2022, 0), 2
    ) AS growth_percentage,
    CASE
        WHEN revenue_2023 > revenue_2022 THEN 'Growth'
        WHEN revenue_2023 < revenue_2022 THEN 'Decline'
        ELSE 'No Change'
    END AS revenue_trend
FROM category_comparison
ORDER BY revenue_change DESC;

----------------------------------------------------------------------------------
-- Q17. Which product category receives the highest average customer rating in each branch?

WITH category_ratings AS (
    SELECT
        branch,
        category,
        ROUND(AVG(rating), 2) AS average_rating,
        RANK() OVER (
            PARTITION BY branch
            ORDER BY AVG(rating) DESC
        ) AS rating_rank
    FROM vistara
    GROUP BY branch, category
)
SELECT
    branch,
    category,
    average_rating
FROM category_ratings
WHERE rating_rank = 1
ORDER BY branch;

----------------------------------------------------------------------------------
-- Q18. What are the average, minimum and maximum customer ratings for each category across different cities?

SELECT
    city,
    category,
    ROUND(AVG(rating), 2) AS average_rating,
    MIN(rating) AS minimum_rating,
    MAX(rating) AS maximum_rating
FROM vistara
GROUP BY city, category
ORDER BY city, category;

----------------------------------------------------------------------------------
-- 4. Customer Behaviour & Payment Preferences
----------------------------------------------------------------------------------
-- Q19. How do customer payment preferences vary across different branches?

SELECT
    branch,
    payment_method,
    COUNT(DISTINCT invoice_id) AS total_transactions,
    ROUND(
        COUNT(DISTINCT invoice_id) * 100.0 /
        SUM(COUNT(DISTINCT invoice_id)) OVER (
            PARTITION BY branch
        ), 2
    ) AS payment_preference_percentage
FROM vistara
GROUP BY branch, payment_method
ORDER BY branch, total_transactions DESC;

----------------------------------------------------------------------------------
-- Q20. Which payment methods generate the highest number of transactions and total quantity sold?

SELECT
    payment_method,
    COUNT(DISTINCT invoice_id) AS total_transactions,
    SUM(quantity) AS total_quantity_sold,
    ROUND(SUM(total_price), 2) AS total_revenue
FROM vistara
GROUP BY payment_method
ORDER BY total_transactions DESC;

----------------------------------------------------------------------------------
-- Q21. What is the most commonly used payment method in each branch?

WITH payment_rankings AS (
    SELECT
        branch,
        payment_method,
        COUNT(DISTINCT invoice_id) AS total_transactions,
        RANK() OVER (
            PARTITION BY branch
            ORDER BY COUNT(DISTINCT invoice_id) DESC
        ) AS payment_rank
    FROM vistara
    GROUP BY branch, payment_method
)
SELECT
    branch,
    payment_method,
    total_transactions
FROM payment_rankings
WHERE payment_rank = 1
ORDER BY branch;

----------------------------------------------------------------------------------
-- Q22. Is there any relationship between customer ratings and category-level revenue?

SELECT
    category,
    ROUND(AVG(rating), 2) AS average_rating,
    ROUND(SUM(total_price), 2) AS total_revenue,
    COUNT(DISTINCT invoice_id) AS total_transactions
FROM vistara
GROUP BY category
ORDER BY average_rating DESC;

----------------------------------------------------------------------------------
-- Q23. Do higher-rated product categories also generate higher revenue?

WITH category_performance AS (
    SELECT
        category,
        AVG(rating) AS average_rating,
        SUM(total_price) AS total_revenue
    FROM vistara
    GROUP BY category
)
SELECT
    category,
    ROUND(average_rating, 2) AS average_rating,
    ROUND(total_revenue, 2) AS total_revenue,
    RANK() OVER (
        ORDER BY average_rating DESC
    ) AS rating_rank,
    RANK() OVER (
        ORDER BY total_revenue DESC
    ) AS revenue_rank
FROM category_performance
ORDER BY rating_rank;

----------------------------------------------------------------------------------
-- 5. Time-Based & Transaction Analysis
----------------------------------------------------------------------------------
-- Q24. Which hours of the day generate the highest revenue and transaction volume?

SELECT
    HOUR(time) AS transaction_hour,
    COUNT(DISTINCT invoice_id) AS total_transactions,
    SUM(quantity) AS total_quantity_sold,
    ROUND(SUM(total_price), 2) AS total_revenue
FROM vistara
GROUP BY HOUR(time)
ORDER BY total_revenue DESC;

----------------------------------------------------------------------------------
-- Q25. How does sales performance differ between weekdays and weekends?

SELECT
    CASE
        WHEN DAYOFWEEK(date) IN (1, 7)
            THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    COUNT(DISTINCT invoice_id) AS total_transactions,
    SUM(quantity) AS total_quantity_sold,
    ROUND(SUM(total_price), 2) AS total_revenue,
    ROUND(
        SUM(total_price) /
        NULLIF(COUNT(DISTINCT invoice_id), 0), 2
    ) AS average_transaction_value
FROM vistara
GROUP BY day_type
ORDER BY total_revenue DESC;

----------------------------------------------------------------------------------
-- Q26. Which day of the week has the highest transaction volume for each branch?

WITH daily_transactions AS (
    SELECT
        branch,
        DAYOFWEEK(date) AS day_number,
        DAYNAME(date) AS day_name,
        COUNT(DISTINCT invoice_id) AS total_transactions
    FROM vistara
    GROUP BY
        branch,
        DAYOFWEEK(date),
        DAYNAME(date)
),
day_rankings AS (
    SELECT
        branch,
        day_name,
        total_transactions,
        RANK() OVER (
            PARTITION BY branch
            ORDER BY total_transactions DESC
        ) AS transaction_rank
    FROM daily_transactions
)
SELECT
    branch,
    day_name,
    total_transactions
FROM day_rankings
WHERE transaction_rank = 1
ORDER BY branch;

----------------------------------------------------------------------------------
-- Q27. How many transactions and how much revenue are generated during each shift across different branches?

SELECT
    branch,
    CASE
        WHEN HOUR(time) BETWEEN 6 AND 11
            THEN 'Morning'
        WHEN HOUR(time) BETWEEN 12 AND 17
            THEN 'Afternoon'
        ELSE 'Evening'
    END AS sales_shift,
    COUNT(DISTINCT invoice_id) AS total_transactions,
    SUM(quantity) AS total_quantity_sold,
    ROUND(SUM(total_price), 2) AS total_revenue
FROM vistara
GROUP BY
    branch,
    sales_shift
ORDER BY branch, total_revenue DESC;

----------------------------------------------------------------------------------
-- Q28. Which time periods consistently generate the highest sales across branches?

WITH hourly_branch_sales AS (
    SELECT
        branch,
        HOUR(time) AS transaction_hour,
        SUM(total_price) AS hourly_revenue
    FROM vistara
    GROUP BY branch, HOUR(time)
),
hourly_rankings AS (
    SELECT
        branch,
        transaction_hour,
        hourly_revenue,
        RANK() OVER (
            PARTITION BY branch
            ORDER BY hourly_revenue DESC
        ) AS hour_rank
    FROM hourly_branch_sales
)
SELECT
    transaction_hour,
    COUNT(*) AS branches_where_hour_is_top_performer,
    ROUND(SUM(hourly_revenue), 2) AS total_revenue
FROM hourly_rankings
WHERE hour_rank = 1
GROUP BY transaction_hour
ORDER BY branches_where_hour_is_top_performer DESC,
         total_revenue DESC;

----------------------------------------------------------------------------------

