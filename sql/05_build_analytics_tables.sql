-- =====================================================================
-- 05. Таблиці для аналізу, Power BI і ноутбука
--   orders_full       : один рядок = одне замовлення
--   order_items_full  : один рядок = одна позиція замовлення
--
-- ПРАВИЛА ПРОЄКТУ (однакові в SQL, ноутбуці й Power BI):
--   1. Валідне замовлення (is_valid_order = 1): не canceled, не unavailable
--      і має хоча б одну позицію.
--   2. Виручка = SUM(price) тобто ціна товарів БЕЗ доставки.
--      payment_value не беремо як виручку: він містить доставку і
--      відсотки за розстрочку.
--   3. Оцінка замовлення = округлене середнє всіх його відгуків.
--   4. Доставка аналізується лише для delivered замовлень з датою доставки.
--   5. Затримка рахується по днях (дата без часу): delay_days > 0 = запізнення.
--      Оцінки часу порівнювати не можна: обіцяна дата має час 00:00.
-- =====================================================================

CREATE INDEX IF NOT EXISTS idx_orders_order_id     ON olist_orders_dataset(order_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id  ON olist_orders_dataset(customer_id);
CREATE INDEX IF NOT EXISTS idx_customers_cust_id   ON olist_customers_dataset(customer_id);
CREATE INDEX IF NOT EXISTS idx_items_order_id      ON olist_order_items_dataset(order_id);
CREATE INDEX IF NOT EXISTS idx_payments_order_id   ON olist_order_payments_dataset(order_id);
CREATE INDEX IF NOT EXISTS idx_reviews_order_id    ON olist_order_reviews_dataset(order_id);


-- ---------------------------------------------------------------------
-- 1. orders_full
-- Спочатку згортаємо багаторядкові таблиці до одного рядка на замовлення
-- (підзапити i, p, r), потім JOIN. Інакше замовлення задублюються.
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS order_items_full;
DROP TABLE IF EXISTS orders_full;

CREATE TABLE orders_full AS
SELECT
    t.*,
    DATE_TRUNC('month', t.purchased_at)::date AS purchase_month,
    CASE
        WHEN t.delay_days IS NULL THEN NULL
        WHEN t.delay_days > 0     THEN 1
        ELSE 0
    END AS is_late,
    CASE
        WHEN t.delay_days IS NULL THEN NULL
        WHEN t.delay_days <= 0    THEN '1. On time or early'
        WHEN t.delay_days <= 3    THEN '2. 1-3 days late'
        WHEN t.delay_days <= 7    THEN '3. 4-7 days late'
        ELSE                           '4. More than 7 days late'
    END AS delay_group
FROM (
    SELECT
        o.order_id,
        c.customer_unique_id,
        c.customer_state,
        o.order_status,
        o.order_purchase_timestamp          AS purchased_at,
        o.order_delivered_customer_date     AS delivered_at,
        o.order_estimated_delivery_date     AS estimated_at,
        i.items_count,
        i.items_value,
        i.freight_value,
        p.payment_value,
        r.review_score,
        CASE
            WHEN o.order_status IN ('canceled', 'unavailable') THEN 0
            WHEN i.items_count IS NULL                         THEN 0
            ELSE 1
        END AS is_valid_order,
        CASE
            WHEN o.order_status = 'delivered'
             AND o.order_delivered_customer_date IS NOT NULL
            THEN o.order_delivered_customer_date::date - o.order_purchase_timestamp::date
        END AS delivery_days,
        CASE
            WHEN o.order_status = 'delivered'
             AND o.order_delivered_customer_date IS NOT NULL
            THEN o.order_delivered_customer_date::date - o.order_estimated_delivery_date::date
        END AS delay_days
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
        SELECT order_id, ROUND(AVG(review_score))::int AS review_score
        FROM olist_order_reviews_dataset
        GROUP BY order_id
    ) r ON o.order_id = r.order_id
) t;

-- ОБОВ'ЯЗКОВА ПЕРЕВІРКА: два числа мають збігатися (99 441 = 99 441)
SELECT COUNT(*) AS rows_total, COUNT(DISTINCT order_id) AS unique_orders
FROM orders_full;

-- Скільки валідних замовлень і скільки доставлених з датою
SELECT SUM(is_valid_order)                        AS valid_orders,
       COUNT(delivery_days)                       AS delivered_with_date,
       ROUND(100.0 * AVG(is_late), 1)             AS late_pct
FROM orders_full;

-- Чому payment_value не дорівнює виручці: порівнюємо з товари + доставка
SELECT COUNT(*) AS orders_checked,
       SUM(CASE WHEN ABS(payment_value - (items_value + freight_value)) > 1
                THEN 1 ELSE 0 END) AS orders_with_diff
FROM orders_full
WHERE is_valid_order = 1 AND payment_value IS NOT NULL;
-- Висновок: невелика частка замовлень має розбіжність, це відсотки
-- за розстрочку і ваучери. Тому виручка = items_value.


-- ---------------------------------------------------------------------
-- 2. order_items_full: для аналізу категорій і продавців
-- LEFT JOIN з товарами та перекладом, щоб не губити товари без категорії.
-- ---------------------------------------------------------------------
CREATE TABLE order_items_full AS
SELECT
    i.order_id,
    i.order_item_id,
    i.product_id,
    i.seller_id,
    s.seller_state,
    COALESCE(t.product_category_name_english, 'unknown') AS category,
    i.price,
    i.freight_value,
    o.customer_state,
    o.order_status,
    o.purchased_at,
    o.purchase_month,
    o.is_valid_order,
    o.review_score,
    o.delay_days,
    o.is_late
FROM olist_order_items_dataset i
JOIN orders_full o                 ON i.order_id = o.order_id
LEFT JOIN olist_products_dataset p ON i.product_id = p.product_id
LEFT JOIN product_category_name_translation t
       ON p.product_category_name = t.product_category_name
LEFT JOIN olist_sellers_dataset s  ON i.seller_id = s.seller_id;

-- ОБОВ'ЯЗКОВА ПЕРЕВІРКА: рядків стільки ж, скільки в order_items (112 650),
-- і кожна пара (order_id, order_item_id) унікальна
SELECT COUNT(*) AS rows_total,
       COUNT(DISTINCT order_id || '-' || order_item_id) AS unique_items
FROM order_items_full;

-- Скільки позицій потрапило в 'unknown'
SELECT category, COUNT(*) AS items
FROM order_items_full
WHERE category = 'unknown'
GROUP BY category;

-- Швидкий огляд
SELECT * FROM orders_full       LIMIT 10;
SELECT * FROM order_items_full  LIMIT 10;
