-- Заполнение фактовой таблицы
INSERT INTO fact_sales (
    customer_id, product_id, store_id, seller_id,
    sale_date, quantity, total_price
)
SELECT 
    r.sale_customer_id,
    r.sale_product_id,
    s.store_id,
    sel.seller_id,
    TO_DATE(r.sale_date, 'DD/MM/YYYY'),
    r.sale_quantity,
    r.sale_total_price
FROM raw_data r
JOIN dim_stores s ON r.store_name = s.store_name
JOIN dim_sellers sel ON r.first_name = sel.first_name 
                     AND r.last_name = sel.last_name;