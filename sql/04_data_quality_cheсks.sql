-- 1. Статуси замовлень
SELECT order_status, COUNT(*) AS orders
FROM olist_orders_dataset
GROUP BY order_status
ORDER BY orders DESC;
-- Висновок: 97% замовлень (96 478 з 99 441) доставлені, скасованих лише 625 (0,6%).
-- Для аналізу доставки беремо тільки статус delivered.


-- 2. Період даних
SELECT MIN(order_purchase_timestamp::timestamp) AS first_order,
       MAX(order_purchase_timestamp::timestamp) AS last_order
FROM olist_orders_dataset;

-- 3. Дублікати order_id в таблиці orders (має бути 0)
SELECT COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_orders
FROM olist_orders_dataset;

-- 4. Пропуски в датах замовлень
SELECT COUNT(*)                                   AS total_orders,
       COUNT(order_approved_at)                   AS with_approved_date,
       COUNT(order_delivered_customer_date)       AS with_delivery_date,
       COUNT(*) - COUNT(order_delivered_customer_date) AS without_delivery_date
FROM olist_orders_dataset;
-- Висновок: у 2 965 замовлень немає дати доставки. Це переважно shipped, canceled,
-- unavailable та інші незавершені статуси, тобто не помилка даних.

-- 5. customer_id проти customer_unique_id
SELECT COUNT(DISTINCT customer_id)        AS customer_ids,
       COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM olist_customers_dataset;

-- 6. Скільки відгуків припадає на одне замовлення
SELECT reviews_per_order, COUNT(*) AS orders
FROM (
    SELECT order_id, COUNT(*) AS reviews_per_order
    FROM olist_order_reviews_dataset
    GROUP BY order_id
) t
GROUP BY reviews_per_order
ORDER BY reviews_per_order;

-- 7. Замовлення без жодної позиції (товарів)
SELECT COUNT(*) AS orders_without_items
FROM olist_orders_dataset o
LEFT JOIN olist_order_items_dataset i ON o.order_id = i.order_id
WHERE i.order_id IS NULL;

-- 8. Товари без категорії
SELECT COUNT(*) AS products_without_category
FROM olist_products_dataset
WHERE product_category_name IS NULL;

-- 9. Мінімум, максимум і середнє значення ціни та доставки
SELECT ROUND(MIN(price)::numeric, 2)         AS min_price,
       ROUND(MAX(price)::numeric, 2)         AS max_price,
       ROUND(AVG(price)::numeric, 2)         AS avg_price,
       ROUND(AVG(freight_value)::numeric, 2) AS avg_freight
FROM olist_order_items_dataset;
