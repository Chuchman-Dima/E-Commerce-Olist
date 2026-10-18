-- =====================================================================
-- 02. Завантаження CSV у таблиці
-- Файли лежать у data/raw/. Якщо проєкт в іншій папці, змініть шлях.
-- TRUNCATE на початку: скрипт можна запускати повторно без дублів.
-- =====================================================================

TRUNCATE TABLE
    olist_customers_dataset,
    olist_geolocation_dataset,
    olist_orders_dataset,
    olist_order_items_dataset,
    olist_order_payments_dataset,
    olist_order_reviews_dataset,
    olist_products_dataset,
    olist_sellers_dataset,
    product_category_name_translation;

COPY olist_customers_dataset
FROM 'C:/E-Commerce Olist/E-Commerce-Olist/data/raw/olist_customers_dataset.csv'
WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');

COPY olist_geolocation_dataset
FROM 'C:/E-Commerce Olist/E-Commerce-Olist/data/raw/olist_geolocation_dataset.csv'
WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');

COPY olist_orders_dataset
FROM 'C:/E-Commerce Olist/E-Commerce-Olist/data/raw/olist_orders_dataset.csv'
WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');

COPY olist_order_items_dataset
FROM 'C:/E-Commerce Olist/E-Commerce-Olist/data/raw/olist_order_items_dataset.csv'
WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');

COPY olist_order_payments_dataset
FROM 'C:/E-Commerce Olist/E-Commerce-Olist/data/raw/olist_order_payments_dataset.csv'
WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');

COPY olist_order_reviews_dataset
FROM 'C:/E-Commerce Olist/E-Commerce-Olist/data/raw/olist_order_reviews_dataset.csv'
WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');

COPY olist_products_dataset
FROM 'C:/E-Commerce Olist/E-Commerce-Olist/data/raw/olist_products_dataset.csv'
WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');

COPY olist_sellers_dataset
FROM 'C:/E-Commerce Olist/E-Commerce-Olist/data/raw/olist_sellers_dataset.csv'
WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');

COPY product_category_name_translation
FROM 'C:/E-Commerce Olist/E-Commerce-Olist/data/raw/product_category_name_translation.csv'
WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');
