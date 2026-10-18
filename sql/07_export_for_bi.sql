-- =====================================================================
-- 07. Вивантаження таблиць у CSV (для ноутбука і Power BI)
-- =====================================================================

COPY (SELECT * FROM orders_full)
TO 'C:/E-Commerce Olist/E-Commerce-Olist/data/processed/orders_full.csv'
WITH (FORMAT csv, HEADER true);

COPY (SELECT * FROM order_items_full)
TO 'C:/E-Commerce Olist/E-Commerce-Olist/data/processed/order_items_full.csv'
WITH (FORMAT csv, HEADER true);
