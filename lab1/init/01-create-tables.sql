CREATE TABLE raw_data (
    id INT,
    customer_first_name VARCHAR(100),
    customer_last_name VARCHAR(100),
    customer_age INT,
    customer_email VARCHAR(100),
    customer_country VARCHAR(100),
    customer_postal_code VARCHAR(20),
    customer_pet_type VARCHAR(50),
    customer_pet_name VARCHAR(100),
    customer_pet_breed VARCHAR(100),
    seller_first_name VARCHAR(100),
    seller_last_name VARCHAR(100),
    seller_email VARCHAR(100),
    seller_country VARCHAR(100),
    seller_postal_code VARCHAR(20),
    product_name VARCHAR(200),
    product_category VARCHAR(100),
    product_price DECIMAL(10,2),
    product_quantity INT,
    sale_date VARCHAR(20),
    sale_customer_id INT,
    sale_seller_id INT,
    sale_product_id INT,
    sale_quantity INT,
    sale_total_price DECIMAL(10,2),
    store_name VARCHAR(200),
    store_location VARCHAR(100),
    store_city VARCHAR(100),
    store_state VARCHAR(100),
    store_country VARCHAR(100),
    store_phone VARCHAR(20),
    store_email VARCHAR(100),
    pet_category VARCHAR(50),
    product_weight DECIMAL(10,2),
    product_color VARCHAR(50),
    product_size VARCHAR(20),
    product_brand VARCHAR(100),
    product_material VARCHAR(100),
    product_description TEXT,
    product_rating DECIMAL(3,1),
    product_reviews INT,
    product_release_date VARCHAR(20),
    product_expiry_date VARCHAR(20),
    supplier_name VARCHAR(200),
    supplier_contact VARCHAR(100),
    supplier_email VARCHAR(100),
    supplier_phone VARCHAR(20),
    supplier_address TEXT,
    supplier_city VARCHAR(100),
    supplier_country VARCHAR(100)
);

-- 1. Страны (UNIQUE на country_name)
CREATE TABLE dim_countries (
    country_id SERIAL PRIMARY KEY,
    country_name VARCHAR(100) UNIQUE NOT NULL
);

-- 2. Города (UNIQUE на city_name + state + country_id)
CREATE TABLE dim_cities (
    city_id SERIAL PRIMARY KEY,
    city_name VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    country_id INT REFERENCES dim_countries(country_id),
    UNIQUE (city_name, state, country_id)
);

-- 3. Почтовые индексы (UNIQUE на postal_code + city_id)
CREATE TABLE dim_postal_codes (
    postal_code_id SERIAL PRIMARY KEY,
    postal_code VARCHAR(20),
    city_id INT REFERENCES dim_cities(city_id),
    UNIQUE (postal_code, city_id)
);

-- 4. Поставщики (UNIQUE на supplier_name)
CREATE TABLE dim_suppliers (
    supplier_id SERIAL PRIMARY KEY,
    supplier_name VARCHAR(200) UNIQUE,
    contact_name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    address TEXT,
    city_id INT REFERENCES dim_cities(city_id)
);

-- 5. Категории (UNIQUE на category_name)
CREATE TABLE dim_categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) UNIQUE,
    pet_category VARCHAR(50)
);

-- 6. Товары (UNIQUE отсутствует, первичный ключ product_id)
CREATE TABLE dim_products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(200),
    price DECIMAL(10,2),
    weight DECIMAL(10,2),
    color VARCHAR(50),
    size VARCHAR(20),
    brand VARCHAR(100),
    material VARCHAR(100),
    category_id INT REFERENCES dim_categories(category_id),
    supplier_id INT REFERENCES dim_suppliers(supplier_id)
);

-- 7. Покупатели (UNIQUE на customer_id - PRIMARY KEY)
CREATE TABLE dim_customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    age INT,
    email VARCHAR(100),
    postal_code_id INT REFERENCES dim_postal_codes(postal_code_id),
    pet_type VARCHAR(50),
    pet_name VARCHAR(100),
    pet_breed VARCHAR(100)
);

-- 8. Магазины (UNIQUE на store_name)
CREATE TABLE dim_stores (
    store_id SERIAL PRIMARY KEY,
    store_name VARCHAR(200) UNIQUE,
    location VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(100),
    city_id INT REFERENCES dim_cities(city_id)
);

-- 9. Продавцы (UNIQUE на first_name + last_name)
CREATE TABLE dim_sellers (
    seller_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(100),
    postal_code_id INT REFERENCES dim_postal_codes(postal_code_id),
    UNIQUE (first_name, last_name)
);

-- 10. Фактовая таблица
CREATE TABLE fact_sales (
    sale_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES dim_customers(customer_id),
    product_id INT REFERENCES dim_products(product_id),
    store_id INT REFERENCES dim_stores(store_id),
    seller_id INT REFERENCES dim_sellers(seller_id),
    sale_date DATE,
    quantity INT,
    total_price DECIMAL(10,2)
);