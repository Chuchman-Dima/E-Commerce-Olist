-- =====================================================================
-- 03. Ознайомлення з таблицями
-- =====================================================================

-- 1. Кількість рядків у кожній таблиці
SELECT 'customers' AS tbl, COUNT(*) AS row_count FROM olist_customers_dataset
UNION ALL SELECT 'geolocation',          COUNT(*) FROM olist_geolocation_dataset
UNION ALL SELECT 'order_items',          COUNT(*) FROM olist_order_items_dataset
UNION ALL SELECT 'payments',             COUNT(*) FROM olist_order_payments_dataset
UNION ALL SELECT 'reviews',              COUNT(*) FROM olist_order_reviews_dataset
UNION ALL SELECT 'orders',               COUNT(*) FROM olist_orders_dataset
UNION ALL SELECT 'products',             COUNT(*) FROM olist_products_dataset
UNION ALL SELECT 'sellers',              COUNT(*) FROM olist_sellers_dataset
UNION ALL SELECT 'category_translation', COUNT(*) FROM product_category_name_translation;
-- Очікувані значення:
-- geolocation 1000163 | order_items 112650 | payments 103886 | reviews 99224
-- orders 99441 | customers 99441 | products 32951 | sellers 3095
-- category_translation 71  (якщо тут 213, таблицю завантажили тричі:
-- виконайте 02_load_data.sql ще раз, там є TRUNCATE)


-- 2. Перші рядки кожної таблиці (що означає один рядок?)
SELECT * FROM olist_orders_dataset              LIMIT 5;  -- одне замовлення
SELECT * FROM olist_customers_dataset           LIMIT 5;  -- один customer_id (на кожне замовлення свій)
SELECT * FROM olist_order_items_dataset         LIMIT 5;  -- одна позиція в замовленні
SELECT * FROM olist_order_payments_dataset      LIMIT 5;  -- один платіж
SELECT * FROM olist_order_reviews_dataset       LIMIT 5;  -- один відгук
SELECT * FROM olist_products_dataset            LIMIT 5;  -- один товар
SELECT * FROM olist_sellers_dataset             LIMIT 5;  -- один продавець
SELECT * FROM olist_geolocation_dataset         LIMIT 5;  -- координата поштового індексу (в аналізі не використовуємо)
SELECT * FROM product_category_name_translation LIMIT 5;  -- переклад категорії


-- 3. Типи колонок (дати мають бути timestamp, гроші numeric)
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
ORDER BY table_name, ordinal_position;
