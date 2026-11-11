WITH customers AS (
    SELECT * FROM {{ source('raw_ecommerce', 'customers') }}
),

orders AS (
    SELECT * FROM {{ ref('fct_orders') }}
    WHERE order_status NOT IN ('canceled', 'unavailable')
),

customer_metrics AS (
    SELECT
        c.customer_unique_id,
        MAX(c.customer_city) AS city,
        MAX(c.customer_state) AS state,
        MIN(o.purchased_at) AS first_order_at,
        MAX(o.purchased_at) AS last_order_at,
        COUNT(DISTINCT o.order_id) AS total_orders,
        COALESCE(SUM(o.total_order_amount), 0) AS lifetime_value,
        AVG(o.delivery_days) AS avg_delivery_days
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)

SELECT
    customer_unique_id,
    city,
    state,
    first_order_at,
    last_order_at,
    total_orders,
    ROUND(lifetime_value::NUMERIC, 2) AS ltv,
    ROUND(avg_delivery_days::NUMERIC, 1) AS avg_delivery_days,
    CASE
        WHEN total_orders >= 3 AND lifetime_value >= 500 THEN 'VIP'
        WHEN total_orders >= 2 THEN 'Repeat'
        WHEN total_orders = 1 THEN 'One-Time'
        ELSE 'Lead'
    END AS customer_segment
FROM customer_metrics
