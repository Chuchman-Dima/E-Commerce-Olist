-- 3.1 KPI по місяцях: замовлення, виручка, середній чек
-- (перші місяці 2016 і кінець 2018 неповні, не робіть з них висновків)
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp::timestamp)::date AS month,
    COUNT(DISTINCT o.order_id)                                       AS orders,
    ROUND(SUM(i.price)::numeric, 0)                                  AS revenue,
    ROUND((SUM(i.price) / COUNT(DISTINCT o.order_id))::numeric, 2)   AS avg_order_value
FROM olist_orders_dataset o
JOIN olist_order_items_dataset i ON o.order_id = i.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY 1
ORDER BY 1;
-- Висновок: як змінювалась виручка? чи є сезонність (листопад)?

-- 3.2 Топ-10 категорій за виручкою
SELECT
    t.product_category_name_english AS category,
    COUNT(*)                        AS items_sold,
    ROUND(SUM(i.price)::numeric, 0) AS revenue
FROM olist_order_items_dataset i
JOIN olist_products_dataset p ON i.product_id = p.product_id
JOIN product_category_name_translation t
     ON p.product_category_name = t.product_category_name
GROUP BY 1
ORDER BY revenue DESC
LIMIT 10;
-- Висновок: яка частка виручки в топ-3 категорій?

-- 3.3 Замовлення за штатами клієнтів
SELECT c.customer_state,
       COUNT(*) AS orders
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY orders DESC;
-- Висновок: скільки відсотків замовлень з топ-3 штатів?

-- 3.4 Способи оплати
SELECT payment_type,
       COUNT(*)                            AS payments,
       ROUND(SUM(payment_value)::numeric, 0) AS total_value,
       ROUND(AVG(payment_installments)::numeric, 1) AS avg_installments
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY payments DESC;

-- 3.5 Розподіл оцінок відгуків
SELECT review_score,
       COUNT(*) AS reviews,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM olist_order_reviews_dataset), 1) AS pct
FROM olist_order_reviews_dataset
GROUP BY review_score
ORDER BY review_score;
-- Висновок: яка частка оцінок 1-2? Це ваша майбутня "погана оцінка".

-- 3.6 Середній час доставки (у днях) для доставлених замовлень
SELECT ROUND(AVG(order_delivered_customer_date::date
               - order_purchase_timestamp::date), 1) AS avg_delivery_days
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;

-- 3.7 Вчасно чи із запізненням -> середня оцінка
SELECT
    CASE
        WHEN o.order_delivered_customer_date::timestamp
           <= o.order_estimated_delivery_date::timestamp THEN 'On time'
        ELSE 'Late'
    END                           AS delivery_status,
    COUNT(*)                      AS orders,
    ROUND(AVG(r.review_score), 2) AS avg_score
FROM olist_orders_dataset o
JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY 1;
-- Висновок: на скільки різниться середня оцінка?

-- 3.8 Те саме за групами затримки
SELECT
    CASE
        WHEN delay <= 0 THEN '1. On time or early'
        WHEN delay <= 3 THEN '2. 1-3 days late'
        WHEN delay <= 7 THEN '3. 4-7 days late'
        ELSE                 '4. More than 7 days late'
    END                         AS delay_group,
    COUNT(*)                    AS orders,
    ROUND(AVG(review_score), 2) AS avg_score
FROM (
    SELECT
        r.review_score,
        o.order_delivered_customer_date::date
          - o.order_estimated_delivery_date::date AS delay
    FROM olist_orders_dataset o
    JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
) t
GROUP BY 1
ORDER BY 1;
-- Висновок: головний інсайт проєкту, запишіть цифри в README.

-- 3.9 Скільки клієнтів зробили 1, 2, 3... замовлення
SELECT orders_count,
       COUNT(*) AS customers
FROM (
    SELECT c.customer_unique_id,
           COUNT(o.order_id) AS orders_count
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
) t
GROUP BY orders_count
ORDER BY orders_count;

-- 3.10 Частка повторних покупців (у відсотках)
SELECT ROUND(100.0 * SUM(CASE WHEN orders_count > 1 THEN 1 ELSE 0 END)
             / COUNT(*), 2) AS repeat_customers_pct
FROM (
    SELECT c.customer_unique_id,
           COUNT(o.order_id) AS orders_count
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
) t;
-- Висновок: чи багато клієнтів повертаються? Що це означає для бізнесу?

-- 3.11 Топ-10 продавців за виручкою
SELECT i.seller_id,
       s.seller_state,
       COUNT(DISTINCT i.order_id)      AS orders,
       ROUND(SUM(i.price)::numeric, 0) AS revenue
FROM olist_order_items_dataset i
JOIN olist_sellers_dataset s ON i.seller_id = s.seller_id
GROUP BY i.seller_id, s.seller_state
ORDER BY revenue DESC
LIMIT 10;

-- 3.12 Середня вартість доставки за штатом клієнта
SELECT c.customer_state,
       ROUND(AVG(i.freight_value)::numeric, 2) AS avg_freight
FROM olist_order_items_dataset i
JOIN olist_orders_dataset o   ON i.order_id = o.order_id
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY avg_freight DESC;