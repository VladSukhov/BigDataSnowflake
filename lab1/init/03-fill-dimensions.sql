-- 1. Заполнение стран
INSERT INTO dim_countries (country_name)
SELECT DISTINCT customer_country FROM raw_data
UNION
SELECT DISTINCT store_country FROM raw_data
UNION
SELECT DISTINCT supplier_country FROM raw_data
ON CONFLICT (country_name) DO NOTHING;

-- 2. Заполнение городов
INSERT INTO dim_cities (city_name, state, country_id)
SELECT 
    DISTINCT store_city, 
    store_state, 
    c.country_id
FROM raw_data r
JOIN dim_countries c ON r.store_country = c.country_name
ON CONFLICT (city_name, state, country_id) DO NOTHING;

-- 3. Заполнение почтовых индексов
INSERT INTO dim_postal_codes (postal_code, city_id)
SELECT 
    DISTINCT r.customer_postal_code,
    ci.city_id
FROM raw_data r
JOIN dim_cities ci ON r.store_city = ci.city_name
ON CONFLICT (postal_code, city_id) DO NOTHING;

-- 4. Заполнение поставщиков
INSERT INTO dim_suppliers (
    supplier_name, contact_name, email, 
    phone, address, city_id
)
SELECT DISTINCT ON (supplier_name)
    supplier_name,
    supplier_contact,
    supplier_email,
    supplier_phone,    -- Добавлено!
    supplier_address,  -- Добавлено!
    ci.city_id
FROM raw_data r
JOIN dim_cities ci ON r.supplier_city = ci.city_name
ON CONFLICT (supplier_name) DO UPDATE 
SET 
    contact_name = EXCLUDED.contact_name,
    email = EXCLUDED.email,
    phone = EXCLUDED.phone,    -- Добавлено!
    address = EXCLUDED.address;-- Добавлено!

-- 5. Заполнение категорий
INSERT INTO dim_categories (category_name, pet_category)
SELECT DISTINCT 
    product_category,
    COALESCE(NULLIF(pet_category, ''), 'Unknown') -- Обработка пустых значений
FROM raw_data 
WHERE product_category IS NOT NULL
ON CONFLICT (category_name) DO NOTHING;

-- 6. Заполнение товаров (без ON CONFLICT, так как product_id - PRIMARY KEY)
INSERT INTO dim_products (
    product_id, product_name, price, weight, color, size, 
    brand, material, category_id, supplier_id
)
SELECT DISTINCT ON (r.sale_product_id)
    r.sale_product_id,
    r.product_name,
    r.product_price,
    r.product_weight,
    r.product_color,
    r.product_size,
    r.product_brand,
    r.product_material,
    cat.category_id,
    sup.supplier_id
FROM raw_data r
JOIN dim_categories cat ON r.product_category = cat.category_name
JOIN dim_suppliers sup ON r.supplier_name = sup.supplier_name
ORDER BY r.sale_product_id, r.product_price DESC -- Берем товар с максимальной ценой при дубликатах
ON CONFLICT (product_id) DO UPDATE 
SET 
    product_name = EXCLUDED.product_name,
    price = EXCLUDED.price;

-- 7. Заполнение покупателей
INSERT INTO dim_customers (
    customer_id, 
    first_name, 
    last_name, 
    age, 
    email,
    postal_code_id, 
    pet_type, 
    pet_name, 
    pet_breed
)
SELECT DISTINCT ON (r.sale_customer_id)
    r.sale_customer_id,
    r.customer_first_name,
    r.customer_last_name,
    r.customer_age,
    r.customer_email,
    pc.postal_code_id,
    r.customer_pet_type,
    r.customer_pet_name,
    r.customer_pet_breed
FROM (
    SELECT 
        sale_customer_id,
        customer_first_name,
        customer_last_name,
        customer_age,
        customer_email,
        customer_postal_code,
        customer_pet_type,
        customer_pet_name,
        customer_pet_breed
    FROM mock_data
    ORDER BY sale_customer_id, customer_email DESC  -- Берем последний email
) r
LEFT JOIN dim_postal_codes pc 
    ON r.customer_postal_code = pc.postal_code
ON CONFLICT (customer_id) DO NOTHING;  -- Игнорируем существующие записи

-- 8. Заполнение магазинов
INSERT INTO dim_stores (store_name, location, phone, email, city_id)
SELECT DISTINCT ON (store_name)
    store_name,
    MAX(store_location) AS location,
    MAX(store_phone) AS phone,
    MAX(store_email) AS email,
    MAX(ci.city_id) AS city_id
FROM raw_data r
JOIN dim_cities ci ON r.store_city = ci.city_name
GROUP BY store_name
ON CONFLICT (store_name) DO UPDATE 
SET 
    location = EXCLUDED.location,
    phone = EXCLUDED.phone;

-- 9. Заполнение продавцов
INSERT INTO dim_sellers (first_name, last_name, email, postal_code_id)
SELECT DISTINCT ON (seller_first_name, seller_last_name)
    seller_first_name,
    seller_last_name,
    MAX(seller_email) AS email,
    MAX(pc.postal_code_id) AS postal_code_id
FROM mock_data r
JOIN dim_postal_codes pc ON r.seller_postal_code = pc.postal_code
GROUP BY seller_first_name, seller_last_name
ON CONFLICT (first_name, last_name) DO UPDATE 
SET 
    email = EXCLUDED.email;