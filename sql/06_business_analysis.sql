-- =====================================================================
-- 06. Бізнес-аналіз
-- Усі запити беруть дані з orders_full та order_items_full (див. 05)
-- і дотримуються однакових правил:
--   * валідні замовлення: is_valid_order = 1
--   * виручка = ціна товарів без доставки
--   * динаміка за період 2017-01 ... 2018-08 (інші місяці неповні)
-- Розгорнуті висновки з цифрами: notebooks/01_eda.ipynb і README.md.
-- =====================================================================

-- 3.1 KPI по місяцях: замовлення, виручка, середній чек
SELECT
    purchase_month                      AS month,
    COUNT(*)                            AS orders,
    ROUND(SUM(items_value), 0)          AS revenue,
    ROUND(SUM(items_value) / COUNT(*), 2) AS avg_order_value
FROM orders_full
WHERE is_valid_order = 1
  AND purchased_at >= '2017-01-01'
  AND purchased_at <  '2018-09-01'
GROUP BY purchase_month
ORDER BY purchase_month;
-- Висновок: динаміка, сезонність і пік замовлень та виручки розібрані в розділі 3 ноутбука.


-- 3.2 Топ-10 категорій за виручкою (з часткою від загальної виручки)
SELECT
    category,
    COUNT(*)                   AS items_sold,
    ROUND(SUM(price), 0)       AS revenue,
    ROUND(SUM(price) * 100.0
          / (SELECT SUM(price) FROM order_items_full WHERE is_valid_order = 1), 1) AS revenue_pct
FROM order_items_full
WHERE is_valid_order = 1
GROUP BY category
ORDER BY revenue DESC
LIMIT 10;
-- Висновок: частка топ-3 і топ-10 категорій розрахована в розділі 4 ноутбука
-- (частка топ-3 = сума перших трьох значень revenue_pct).


-- 3.3 Замовлення за штатами клієнтів
SELECT
    customer_state,
    COUNT(*) AS orders,
    ROUND(COUNT(*) * 100.0
          / (SELECT COUNT(*) FROM orders_full WHERE is_valid_order = 1), 1) AS orders_pct
FROM orders_full
WHERE is_valid_order = 1
GROUP BY customer_state
ORDER BY orders DESC;
-- Висновок: частка топ-3 штатів розрахована в розділі 7 ноутбука (сума перших трьох orders_pct).


-- 3.4 Способи оплати
SELECT
    p.payment_type,
    COUNT(*)                          AS payments,
    ROUND(SUM(p.payment_value), 0)    AS total_value,
    ROUND(AVG(p.payment_installments), 1) AS avg_installments
FROM olist_order_payments_dataset p
JOIN orders_full o ON p.order_id = o.order_id
WHERE o.is_valid_order = 1
GROUP BY p.payment_type
ORDER BY payments DESC;


-- 3.5 Розподіл оцінок відгуків (одна оцінка на замовлення)
SELECT
    review_score,
    COUNT(*) AS orders,
    ROUND(COUNT(*) * 100.0
          / (SELECT COUNT(*) FROM orders_full
             WHERE is_valid_order = 1 AND review_score IS NOT NULL), 1) AS pct
FROM orders_full
WHERE is_valid_order = 1
  AND review_score IS NOT NULL
GROUP BY review_score
ORDER BY review_score;
-- Висновок: приблизно 58% оцінок дорівнюють 5, а на оцінки 1-2 припадає близько 15%.
-- Оцінки 1-2 вважаємо "поганими" в аналізі далі.


-- 3.6 Середній час доставки (у днях) і частка запізнених замовлень
SELECT
    ROUND(AVG(delivery_days), 1)    AS avg_delivery_days,
    ROUND(100.0 * AVG(is_late), 1)  AS late_pct
FROM orders_full
WHERE delivery_days IS NOT NULL;
-- Висновок: середня доставка близько 12 днів, і в середньому товар приходить приблизно
-- на 12 днів раніше обіцяної дати, тож запізнюється лише невелика частка замовлень (≈7%).


-- 3.7 Вчасно чи із запізненням: середня оцінка
SELECT
    CASE WHEN is_late = 1 THEN 'Late' ELSE 'On time' END AS delivery_status,
    COUNT(*)                      AS orders,
    ROUND(AVG(review_score), 2)   AS avg_score
FROM orders_full
WHERE delivery_days IS NOT NULL
  AND review_score IS NOT NULL
GROUP BY 1
ORDER BY 1 DESC;
-- Висновок: замовлення, доставлені вчасно, отримують в середньому близько 4.3,
-- а із запізненням близько 2.3. Різниця приблизно 2 бали.


-- 3.8 Те саме за групами затримки
SELECT
    delay_group,
    COUNT(*)                    AS orders,
    ROUND(AVG(review_score), 2) AS avg_score
FROM orders_full
WHERE delivery_days IS NOT NULL
  AND review_score IS NOT NULL
GROUP BY delay_group
ORDER BY delay_group;
-- Висновок (головний інсайт проєкту): чим довша затримка, тим нижча оцінка:
-- вчасно ~4.3, 1-3 дні ~3.3, 4-7 днів ~2.1, понад 7 днів ~1.7.
-- Навіть невелика затримка швидко знижує задоволеність, тож терміни обіцянок важливіші за швидкість.


-- 3.9 Скільки клієнтів зробили 1, 2, 3... замовлення
SELECT orders_count,
       COUNT(*) AS customers
FROM (
    SELECT customer_unique_id,
           COUNT(*) AS orders_count
    FROM orders_full
    WHERE is_valid_order = 1
    GROUP BY customer_unique_id
) t
GROUP BY orders_count
ORDER BY orders_count;


-- 3.10 Частка повторних покупців (у відсотках)
SELECT ROUND(100.0 * SUM(CASE WHEN orders_count > 1 THEN 1 ELSE 0 END)
             / COUNT(*), 2) AS repeat_customers_pct
FROM (
    SELECT customer_unique_id,
           COUNT(*) AS orders_count
    FROM orders_full
    WHERE is_valid_order = 1
    GROUP BY customer_unique_id
) t;
-- Висновок: близько 97% клієнтів купили лише один раз, повторні покупці близько 3%.
-- Для бізнесу це головна точка росту: маркетплейс майже не утримує клієнтів,
-- і вартість залучення "окупається" одним замовленням.


-- 3.11 Топ-10 продавців за виручкою
SELECT
    seller_id,
    seller_state,
    COUNT(DISTINCT order_id)  AS orders,
    ROUND(SUM(price), 0)      AS revenue
FROM order_items_full
WHERE is_valid_order = 1
GROUP BY seller_id, seller_state
ORDER BY revenue DESC
LIMIT 10;


-- 3.12 Доставка за штатом клієнта: середня вартість і частка від ціни товару
SELECT
    customer_state,
    ROUND(AVG(freight_value), 2)                  AS avg_freight,
    ROUND(100.0 * SUM(freight_value) / SUM(price), 1) AS freight_pct_of_price
FROM order_items_full
WHERE is_valid_order = 1
GROUP BY customer_state
ORDER BY avg_freight DESC;
-- Висновок: штати з найдорожчою доставкою і її частка в ціні товару розібрані в розділі 8 ноутбука.


-- 3.13 Частка запізнень за штатами (штати з 500+ доставлених замовлень)
SELECT
    customer_state,
    COUNT(*)                        AS delivered_orders,
    ROUND(100.0 * AVG(is_late), 1)  AS late_pct
FROM orders_full
WHERE delivery_days IS NOT NULL
GROUP BY customer_state
HAVING COUNT(*) >= 500
ORDER BY late_pct DESC;
-- Висновок: найбільше запізнень у MA (~17%), CE (~14%), BA (~12%), RJ (~12%).
-- RJ найбільший із них за обсягом, тому саме там затримки зачіпають найбільше клієнтів.
