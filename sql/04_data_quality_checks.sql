-- =====================================================================
-- 04. Перевірка якості даних
-- Числа у висновках взято з виводу запитів.
-- =====================================================================

-- 1. Статуси замовлень
SELECT order_status, COUNT(*) AS orders
FROM olist_orders_dataset
GROUP BY order_status
ORDER BY orders DESC;
-- Висновок: 96 478 з 99 441 замовлень (97%) доставлені, canceled 625 (0,6%),
-- unavailable 609. Решта (shipped, invoiced, processing, created, approved) не завершені.
-- Правило проєкту: валідне замовлення = не canceled, не unavailable і має хоча б 1 товар.
-- Аналіз доставки робимо тільки для доставлених замовлень з датою доставки.


-- 2. Період даних
SELECT MIN(order_purchase_timestamp) AS first_order,
       MAX(order_purchase_timestamp) AS last_order
FROM olist_orders_dataset;
-- Висновок: дані з 2016-09-04 по 2018-10-17. Вересень-грудень 2016 і вересень-жовтень 2018
-- неповні, тому для динаміки беремо 2017-01 ... 2018-08.


-- 3. Дублікати order_id в таблиці orders (має бути 0)
SELECT COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_orders
FROM olist_orders_dataset;
-- Висновок: 0, order_id унікальний.


-- 4. Пропуски в датах замовлень
SELECT COUNT(*)                                        AS total_orders,
       COUNT(order_approved_at)                        AS with_approved_date,
       COUNT(order_delivered_customer_date)            AS with_delivery_date,
       COUNT(*) - COUNT(order_delivered_customer_date) AS without_delivery_date
FROM olist_orders_dataset;
-- Висновок: у 2 965 замовлень немає дати доставки. Переважно це shipped, canceled,
-- unavailable та інші незавершені статуси, тобто не помилка даних.


-- 5. Доставлені замовлення без дати доставки (аномалія)
SELECT COUNT(*) AS delivered_without_date
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;
-- Висновок: 8 замовлень зі статусом delivered без дати. Це дрібна аномалія,
-- у аналізі доставки такі замовлення виключаємо.


-- 6. customer_id проти customer_unique_id
SELECT COUNT(DISTINCT customer_id)        AS customer_ids,
       COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM olist_customers_dataset;
-- Висновок: 99 441 customer_id, але лише 96 096 реальних клієнтів.
-- customer_id створюється на кожне замовлення, тому повторні покупки
-- рахуємо тільки за customer_unique_id.


-- 7. Скільки відгуків припадає на одне замовлення
SELECT reviews_per_order, COUNT(*) AS orders
FROM (
    SELECT order_id, COUNT(*) AS reviews_per_order
    FROM olist_order_reviews_dataset
    GROUP BY order_id
) t
GROUP BY reviews_per_order
ORDER BY reviews_per_order;
-- Висновок: більшість замовлень має 1 відгук, але є замовлення з 2-3 відгуками.
-- Щоб JOIN не дублював замовлення, у orders_full зводимо оцінку до одного
-- значення на замовлення (округлене середнє).
-- Також 768 замовлень не мають відгуку взагалі.


-- 8. Замовлення без жодної позиції (товарів)
SELECT o.order_status, COUNT(*) AS orders_without_items
FROM olist_orders_dataset o
LEFT JOIN olist_order_items_dataset i ON o.order_id = i.order_id
WHERE i.order_id IS NULL
GROUP BY o.order_status
ORDER BY orders_without_items DESC;
-- Висновок: 775 замовлень без товарів, переважно unavailable і canceled.
-- Їх виключаємо з аналізу виручки (is_valid_order = 0).


-- 9. Товари без категорії
SELECT COUNT(*) AS products_without_category
FROM olist_products_dataset
WHERE product_category_name IS NULL;
-- Висновок: 610 товарів без категорії. У аналізі підписуємо їх як 'unknown'.


-- 10. Категорії, для яких немає перекладу
SELECT DISTINCT p.product_category_name
FROM olist_products_dataset p
LEFT JOIN product_category_name_translation t
       ON p.product_category_name = t.product_category_name
WHERE t.product_category_name IS NULL
  AND p.product_category_name IS NOT NULL;
-- Висновок: 2 категорії без перекладу (pc_gamer та portateis_cozinha_e_preparadores_de_alimentos).
-- Тому в аналізі використовуємо LEFT JOIN, інакше їхні товари зникнуть із звітів.


-- 11. Мінімум, максимум і середнє значення ціни та доставки
SELECT ROUND(MIN(price), 2)         AS min_price,
       ROUND(MAX(price), 2)         AS max_price,
       ROUND(AVG(price), 2)         AS avg_price,
       ROUND(AVG(freight_value), 2) AS avg_freight
FROM olist_order_items_dataset;
-- Висновок: ціна від 0.85 до 6 735, середня ~120.65; середня доставка ~19.99.
-- Великий розкид цін (дорогі товари), тому середній чек чутливий до викидів.
