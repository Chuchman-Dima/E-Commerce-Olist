COPY olist_customers_dataset
FROM 'C:/E-Commerce Olist/E-Commerce-Olist/data/olist_customers_dataset.csv'
WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');

COPY olist_geolocation_dataset
FROM 'C:/E-Commerce Olist/E-Commerce-Olist/data/olist_geolocation_dataset.csv'
WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');

COPY olist_orders_dataset
FROM 'C:/E-Commerce Olist/E-Commerce-Olist/data/olist_orders_dataset.csv'
WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');

COPY olist_order_items_dataset
FROM 'C:/E-Commerce Olist/E-Commerce-Olist/data/olist_order_items_dataset.csv'
WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');

COPY olist_order_payments_dataset
FROM 'C:/E-Commerce Olist/E-Commerce-Olist/data/olist_order_payments_dataset.csv'
WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');

COPY olist_order_reviews_dataset
FROM 'C:/E-Commerce Olist/E-Commerce-Olist/data/olist_order_reviews_dataset.csv'
WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');

COPY olist_products_dataset
FROM 'C:/E-Commerce Olist/E-Commerce-Olist/data/olist_products_dataset.csv'
WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');

COPY olist_sellers_dataset
FROM 'C:/E-Commerce Olist/E-Commerce-Olist/data/olist_sellers_dataset.csv'
WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');

COPY product_category_name_translation
FROM 'C:/E-Commerce Olist/E-Commerce-Olist/data/product_category_name_translation.csv'
WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');