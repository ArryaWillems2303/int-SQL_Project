-- Step 1: Calculate LTV per customer
WITH customer_ltv AS (
    SELECT
        customerkey,
        cleaned_name,
        SUM(total_net_revenue) AS total_ltv
    FROM cohort_analysis
    GROUP BY customerkey, cleaned_name
),

-- Step 2: Calculate LTV percentiles
customer_segments AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_ltv) AS ltv_25th_percentile,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_ltv) AS ltv_75th_percentile
    FROM customer_ltv
),

-- Step 3: Assign segment labels to each customer
segment_values AS (
    SELECT
        c.*,
        CASE
            WHEN c.total_ltv < cs.ltv_25th_percentile THEN '1 - Low-Value'
            WHEN c.total_ltv < cs.ltv_75th_percentile THEN '2 - Mid-Value'
            ELSE '3 - High-Value'
        END AS customer_segment
    FROM customer_ltv c, customer_segments cs
)

-- Step 4: Aggregate LTV by segment
SELECT
    customer_segment,
    SUM(total_ltv) AS total_ltv,
    COUNT(customerkey) AS customer_count,
    SUM(total_ltv) / COUNT(customerkey) AS avg_ltv
FROM segment_values
GROUP BY customer_segment
ORDER BY customer_segment;