-- =====================================================================
-- ОДНА ТАБЛИЦЯ "ЗАМОВЛЕННЯ" ДЛЯ POWER BI І ML
-- Один рядок = одне замовлення. Спочатку згортаємо багаторядкові
-- таблиці до одного рядка на замовлення (підзапити), потім JOIN.
-- =====================================================================

CREATE INDEX IF NOT EXISTS idx_orders_order_id ON olist_orders_dataset(order_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON olist_orders_dataset(customer_id);
CREATE INDEX IF NOT EXISTS idx_customers_customer_id ON olist_customers_dataset(customer_id);
CREATE INDEX IF NOT EXISTS idx_items_order_id ON olist_order_items_dataset(order_id);
CREATE INDEX IF NOT EXISTS idx_payments_order_id ON olist_order_payments_dataset(order_id);
CREATE INDEX IF NOT EXISTS idx_reviews_order_id ON olist_order_reviews_dataset(order_id);


DROP TABLE IF EXISTS orders_full;

CREATE TABLE orders_full AS
SELECT
    o.order_id,
    c.customer_unique_id,
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp::timestamp          AS purchased_at,
    o.order_delivered_customer_date::timestamp     AS delivered_at,
    o.order_estimated_delivery_date::timestamp     AS estimated_at,
    i.items_count,
    i.items_value,
    i.freight_value,
    p.payment_value,
    r.review_score
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
LEFT JOIN (
    SELECT order_id,
           COUNT(*)           AS items_count,
           SUM(price)         AS items_value,
           SUM(freight_value) AS freight_value
    FROM olist_order_items_dataset
    GROUP BY order_id
) i ON o.order_id = i.order_id
LEFT JOIN (
    SELECT order_id, SUM(payment_value) AS payment_value
    FROM olist_order_payments_dataset
    GROUP BY order_id
) p ON o.order_id = p.order_id
LEFT JOIN (
    SELECT order_id, AVG(review_score) AS review_score
    FROM olist_order_reviews_dataset
    GROUP BY order_id
) r ON o.order_id = r.order_id;

-- ОБОВ'ЯЗКОВА ПЕРЕВІРКА: два числа мають збігатися
SELECT COUNT(*) AS rows_total, COUNT(DISTINCT order_id) AS unique_orders
FROM orders_full;

-- Швидкий огляд результату
SELECT * FROM orders_full LIMIT 10;