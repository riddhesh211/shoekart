
-- ============================================================
-- ShoeKart Database Schema
-- Run this file in MySQL to create the database and tables.
-- Usage: mysql -u root -p < shoekart.sql
-- ============================================================

DROP DATABASE IF EXISTS shoekart_db;
CREATE DATABASE shoekart_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE shoekart_db;

-- ------------------------------------------------------------
-- 1. USERS
-- ------------------------------------------------------------
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_admin TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 2. CATEGORIES
-- ------------------------------------------------------------
CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    slug VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 3. PRODUCTS
-- ------------------------------------------------------------
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    discount_price DECIMAL(10,2) DEFAULT NULL,
    rating DECIMAL(2,1) DEFAULT 4.0,
    image VARCHAR(255) DEFAULT 'default_shoe.jpg',
    is_new TINYINT(1) DEFAULT 0,
    is_popular TINYINT(1) DEFAULT 0,
    stock INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 4. PRODUCT SIZES (stock per size)
-- ------------------------------------------------------------
CREATE TABLE product_sizes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    size VARCHAR(10) NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    UNIQUE KEY uniq_product_size (product_id, size)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 5. ADDRESSES
-- ------------------------------------------------------------
CREATE TABLE addresses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    mobile VARCHAR(20) NOT NULL,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(80) NOT NULL,
    state VARCHAR(80) NOT NULL,
    pincode VARCHAR(10) NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 6. CART (one active cart per user)
-- ------------------------------------------------------------
CREATE TABLE cart (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY uniq_user_cart (user_id)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 7. CART ITEMS
-- ------------------------------------------------------------
CREATE TABLE cart_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cart_id INT NOT NULL,
    product_id INT NOT NULL,
    size VARCHAR(10) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    FOREIGN KEY (cart_id) REFERENCES cart(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 8. ORDERS
-- ------------------------------------------------------------
CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    address_id INT NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    delivery_charge DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(30) NOT NULL DEFAULT 'COD',
    status VARCHAR(20) NOT NULL DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (address_id) REFERENCES addresses(id)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 9. ORDER ITEMS
-- ------------------------------------------------------------
CREATE TABLE order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    product_name VARCHAR(150) NOT NULL,
    size VARCHAR(10) NOT NULL,
    quantity INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id)
) ENGINE=InnoDB;

-- ============================================================
-- SAMPLE DATA
-- ============================================================

-- Categories
INSERT INTO categories (name, slug) VALUES
('Sneakers', 'sneakers'),
('Sandals', 'sandals'),
('Chappals', 'chappals');

-- Admin user (password: admin123)
-- Password hash generated with werkzeug generate_password_hash('admin123')
INSERT INTO users (full_name, email, phone, password_hash, is_admin) VALUES
('Admin User', 'admin@shoekart.com', '9999999999',
 'pbkdf2:sha256:600000$4nQ2hFZ8f0d1s0Yg$6f6b6c5e5e2a2b1a9c9d9e9f0a0b0c0d0e0f1a1b2c2d3e3f4a4b5c5d6e6f7a8b', 1);
-- NOTE: The hash above is a placeholder. app.py creates/repairs the real admin
-- account automatically on first run using generate_password_hash(), so the
-- admin login (admin@shoekart.com / admin123) always works out of the box.

-- Products (70 Sneakers, 65 Sandals, 65 Chappals = 200 total)
INSERT INTO products (category_id, name, description, price, discount_price, rating, image, is_new, is_popular, stock) VALUES
(1, 'CloudWalk Walking Sneakers', 'CloudWalk Walking Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 2799.00, 1874, 4.1, 'cloudwalk_walking_sneakers_1_0.jpg', 0, 0, 16),
(1, 'NimbleFoot Gym Trainers', 'NimbleFoot Gym Trainers is a breathable, cushioned sneaker built for everyday performance and comfort.', 699.00, 556, 4.7, 'nimblefoot_gym_trainers_1_1.jpg', 1, 1, 78),
(1, 'RapidFoot Walking Sneakers', 'RapidFoot Walking Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 2999.00, 2059, 4.2, 'rapidfoot_walking_sneakers_1_2.jpg', 0, 1, 80),
(1, 'AeroFlex Training Shoes', 'AeroFlex Training Shoes is a breathable, cushioned sneaker built for everyday performance and comfort.', 699.00, 594, 4.8, 'aeroflex_training_shoes_1_3.jpg', 0, 0, 40),
(1, 'AeroFlex Casual Sneakers', 'AeroFlex Casual Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 999.00, 746, 4.8, 'aeroflex_casual_sneakers_1_4.jpg', 0, 1, 10),
(1, 'DynaStep Retro Sneakers', 'DynaStep Retro Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 2499.00, 2016, 4.2, 'dynastep_retro_sneakers_1_5.jpg', 0, 0, 72),
(1, 'AirFlex Trail Runners', 'AirFlex Trail Runners is a breathable, cushioned sneaker built for everyday performance and comfort.', 799.00, 554, 3.6, 'airflex_trail_runners_1_6.jpg', 0, 1, 50),
(1, 'FlashRun Skate Sneakers', 'FlashRun Skate Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 499.00, 372, 4.9, 'flashrun_skate_sneakers_1_7.jpg', 0, 1, 75),
(1, 'EliteStride Retro Sneakers', 'EliteStride Retro Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 599.00, NULL, 3.6, 'elitestride_retro_sneakers_1_8.jpg', 1, 0, 61),
(1, 'SwiftRunner Training Shoes', 'SwiftRunner Training Shoes is a breathable, cushioned sneaker built for everyday performance and comfort.', 699.00, NULL, 4.4, 'swiftrunner_training_shoes_1_9.jpg', 0, 1, 20),
(1, 'AirFlex Training Shoes', 'AirFlex Training Shoes is a breathable, cushioned sneaker built for everyday performance and comfort.', 2799.00, NULL, 4.3, 'airflex_training_shoes_1_10.jpg', 0, 0, 50),
(1, 'TurboStride Casual Sneakers', 'TurboStride Casual Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 1299.00, 878, 4.5, 'turbostride_casual_sneakers_1_11.jpg', 0, 0, 19),
(1, 'StreetMax Basketball Shoes', 'StreetMax Basketball Shoes is a breathable, cushioned sneaker built for everyday performance and comfort.', 399.00, NULL, 5.0, 'streetmax_basketball_shoes_1_12.jpg', 0, 1, 37),
(1, 'VeloRun Trail Runners', 'VeloRun Trail Runners is a breathable, cushioned sneaker built for everyday performance and comfort.', 3499.00, 2927, 4.8, 'velorun_trail_runners_1_13.jpg', 0, 0, 30),
(1, 'HyperBounce Trail Runners', 'HyperBounce Trail Runners is a breathable, cushioned sneaker built for everyday performance and comfort.', 2999.00, NULL, 4.6, 'hyperbounce_trail_runners_1_14.jpg', 0, 0, 77),
(1, 'VeloRun Basketball Shoes', 'VeloRun Basketball Shoes is a breathable, cushioned sneaker built for everyday performance and comfort.', 399.00, NULL, 4.3, 'velorun_basketball_shoes_1_15.jpg', 0, 1, 27),
(1, 'SwiftRunner Basketball Shoes', 'SwiftRunner Basketball Shoes is a breathable, cushioned sneaker built for everyday performance and comfort.', 1499.00, 1006, 4.3, 'swiftrunner_basketball_shoes_1_16.jpg', 0, 0, 53),
(1, 'UrbanStep Casual Sneakers', 'UrbanStep Casual Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 1199.00, NULL, 4.8, 'urbanstep_casual_sneakers_1_17.jpg', 0, 0, 16),
(1, 'PowerStep Training Shoes', 'PowerStep Training Shoes is a breathable, cushioned sneaker built for everyday performance and comfort.', 599.00, NULL, 4.7, 'powerstep_training_shoes_1_18.jpg', 1, 0, 26),
(1, 'PowerStep Basketball Shoes', 'PowerStep Basketball Shoes is a breathable, cushioned sneaker built for everyday performance and comfort.', 1499.00, 1107, 4.6, 'powerstep_basketball_shoes_1_19.jpg', 0, 1, 29),
(1, 'HyperBounce Running Sneakers', 'HyperBounce Running Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 499.00, NULL, 4.4, 'hyperbounce_running_sneakers_1_20.jpg', 1, 1, 49),
(1, 'FlexCore Training Shoes', 'FlexCore Training Shoes is a breathable, cushioned sneaker built for everyday performance and comfort.', 2299.00, NULL, 4.7, 'flexcore_training_shoes_1_21.jpg', 0, 0, 36),
(1, 'ProGrip Casual Sneakers', 'ProGrip Casual Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 1299.00, NULL, 4.0, 'progrip_casual_sneakers_1_22.jpg', 0, 0, 29),
(1, 'UrbanStep Trail Runners', 'UrbanStep Trail Runners is a breathable, cushioned sneaker built for everyday performance and comfort.', 1299.00, NULL, 5.0, 'urbanstep_trail_runners_1_23.jpg', 0, 0, 13),
(1, 'AeroFlex Skate Sneakers', 'AeroFlex Skate Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 999.00, NULL, 4.0, 'aeroflex_skate_sneakers_1_24.jpg', 0, 0, 41),
(1, 'BoltRunner Sports Sneakers', 'BoltRunner Sports Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 1499.00, 1185, 4.1, 'boltrunner_sports_sneakers_1_25.jpg', 1, 0, 35),
(1, 'MaxCushion Sports Sneakers', 'MaxCushion Sports Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 2999.00, 2442, 4.8, 'maxcushion_sports_sneakers_1_26.jpg', 0, 0, 61),
(1, 'CloudWalk Basketball Shoes', 'CloudWalk Basketball Shoes is a breathable, cushioned sneaker built for everyday performance and comfort.', 1999.00, 1327, 4.7, 'cloudwalk_basketball_shoes_1_27.jpg', 0, 0, 78),
(1, 'FlashRun Walking Sneakers', 'FlashRun Walking Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 1999.00, NULL, 3.7, 'flashrun_walking_sneakers_1_28.jpg', 0, 1, 43),
(1, 'TrekLite Training Shoes', 'TrekLite Training Shoes is a breathable, cushioned sneaker built for everyday performance and comfort.', 499.00, 368, 4.6, 'treklite_training_shoes_1_29.jpg', 0, 0, 75),
(1, 'PowerStep Walking Sneakers', 'PowerStep Walking Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 699.00, 535, 3.9, 'powerstep_walking_sneakers_1_30.jpg', 0, 1, 78),
(1, 'NimbleFoot Basketball Shoes', 'NimbleFoot Basketball Shoes is a breathable, cushioned sneaker built for everyday performance and comfort.', 1199.00, 796, 4.5, 'nimblefoot_basketball_shoes_1_31.jpg', 0, 0, 25),
(1, 'ProGrip Skate Sneakers', 'ProGrip Skate Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 1799.00, NULL, 4.5, 'progrip_skate_sneakers_1_32.jpg', 0, 0, 80),
(1, 'DynaStep Walking Sneakers', 'DynaStep Walking Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 799.00, 626, 4.1, 'dynastep_walking_sneakers_1_33.jpg', 0, 1, 48),
(1, 'FlexCore Gym Trainers', 'FlexCore Gym Trainers is a breathable, cushioned sneaker built for everyday performance and comfort.', 2499.00, NULL, 3.5, 'flexcore_gym_trainers_1_34.jpg', 0, 0, 51),
(1, 'EliteStride Trail Runners', 'EliteStride Trail Runners is a breathable, cushioned sneaker built for everyday performance and comfort.', 2999.00, 2355, 4.3, 'elitestride_trail_runners_1_35.jpg', 0, 0, 31),
(1, 'MaxCushion Gym Trainers', 'MaxCushion Gym Trainers is a breathable, cushioned sneaker built for everyday performance and comfort.', 599.00, 469, 4.4, 'maxcushion_gym_trainers_1_36.jpg', 1, 0, 40),
(1, 'MaxCushion Trail Runners', 'MaxCushion Trail Runners is a breathable, cushioned sneaker built for everyday performance and comfort.', 1799.00, 1241, 3.5, 'maxcushion_trail_runners_1_37.jpg', 0, 0, 19),
(1, 'StreetMax Sports Sneakers', 'StreetMax Sports Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 2999.00, 2327, 3.8, 'streetmax_sports_sneakers_1_38.jpg', 0, 0, 41),
(1, 'EliteStride Skate Sneakers', 'EliteStride Skate Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 799.00, NULL, 3.5, 'elitestride_skate_sneakers_1_39.jpg', 0, 0, 23),
(1, 'PulseRun Trail Runners', 'PulseRun Trail Runners is a breathable, cushioned sneaker built for everyday performance and comfort.', 2799.00, 2269, 4.5, 'pulserun_trail_runners_1_40.jpg', 0, 0, 25),
(1, 'UrbanStep Retro Sneakers', 'UrbanStep Retro Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 2999.00, 2228, 4.3, 'urbanstep_retro_sneakers_1_41.jpg', 0, 0, 66),
(1, 'VeloRun Casual Sneakers', 'VeloRun Casual Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 3499.00, 2909, 4.2, 'velorun_casual_sneakers_1_42.jpg', 1, 0, 67),
(1, 'NimbleFoot Trail Runners', 'NimbleFoot Trail Runners is a breathable, cushioned sneaker built for everyday performance and comfort.', 1499.00, NULL, 4.8, 'nimblefoot_trail_runners_1_43.jpg', 0, 0, 72),
(1, 'SprintX Walking Sneakers', 'SprintX Walking Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 1299.00, 864, 3.9, 'sprintx_walking_sneakers_1_44.jpg', 0, 0, 79),
(1, 'StreetMax Running Sneakers', 'StreetMax Running Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 599.00, 417, 4.5, 'streetmax_running_sneakers_1_45.jpg', 0, 1, 62),
(1, 'CoreFit Training Shoes', 'CoreFit Training Shoes is a breathable, cushioned sneaker built for everyday performance and comfort.', 1999.00, NULL, 4.1, 'corefit_training_shoes_1_46.jpg', 0, 0, 12),
(1, 'AeroFlex Walking Sneakers', 'AeroFlex Walking Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 2499.00, NULL, 4.9, 'aeroflex_walking_sneakers_1_47.jpg', 0, 0, 63),
(1, 'CloudWalk Sports Sneakers', 'CloudWalk Sports Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 1299.00, NULL, 3.9, 'cloudwalk_sports_sneakers_1_48.jpg', 0, 0, 61),
(1, 'BoltRunner Training Shoes', 'BoltRunner Training Shoes is a breathable, cushioned sneaker built for everyday performance and comfort.', 999.00, NULL, 4.9, 'boltrunner_training_shoes_1_49.jpg', 0, 0, 60),
(1, 'SwiftRunner Casual Sneakers', 'SwiftRunner Casual Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 399.00, 294, 4.8, 'swiftrunner_casual_sneakers_1_50.jpg', 1, 0, 51),
(1, 'AeroFlex Running Sneakers', 'AeroFlex Running Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 1199.00, NULL, 4.0, 'aeroflex_running_sneakers_1_51.jpg', 0, 0, 63),
(1, 'ActivePro Training Shoes', 'ActivePro Training Shoes is a breathable, cushioned sneaker built for everyday performance and comfort.', 1499.00, NULL, 4.2, 'activepro_training_shoes_1_52.jpg', 0, 1, 54),
(1, 'CoreFit Running Sneakers', 'CoreFit Running Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 1299.00, NULL, 4.7, 'corefit_running_sneakers_1_53.jpg', 0, 0, 41),
(1, 'AirFlex Walking Sneakers', 'AirFlex Walking Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 1199.00, NULL, 4.4, 'airflex_walking_sneakers_1_54.jpg', 0, 0, 24),
(1, 'TurboStride Sports Sneakers', 'TurboStride Sports Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 1199.00, NULL, 3.9, 'turbostride_sports_sneakers_1_55.jpg', 0, 0, 24),
(1, 'FlexCore Casual Sneakers', 'FlexCore Casual Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 999.00, NULL, 3.7, 'flexcore_casual_sneakers_1_56.jpg', 1, 0, 58),
(1, 'MaxCushion Training Shoes', 'MaxCushion Training Shoes is a breathable, cushioned sneaker built for everyday performance and comfort.', 2499.00, NULL, 3.8, 'maxcushion_training_shoes_1_57.jpg', 0, 0, 41),
(1, 'TrekLite Gym Trainers', 'TrekLite Gym Trainers is a breathable, cushioned sneaker built for everyday performance and comfort.', 699.00, NULL, 4.0, 'treklite_gym_trainers_1_58.jpg', 0, 0, 15),
(1, 'AirFlex Basketball Shoes', 'AirFlex Basketball Shoes is a breathable, cushioned sneaker built for everyday performance and comfort.', 2299.00, NULL, 4.5, 'airflex_basketball_shoes_1_59.jpg', 1, 0, 11),
(1, 'ProGrip Running Sneakers', 'ProGrip Running Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 2799.00, NULL, 3.7, 'progrip_running_sneakers_1_60.jpg', 0, 0, 68),
(1, 'CoreFit Basketball Shoes', 'CoreFit Basketball Shoes is a breathable, cushioned sneaker built for everyday performance and comfort.', 799.00, 637, 4.9, 'corefit_basketball_shoes_1_61.jpg', 0, 0, 78),
(1, 'CoreFit Gym Trainers', 'CoreFit Gym Trainers is a breathable, cushioned sneaker built for everyday performance and comfort.', 3299.00, NULL, 4.7, 'corefit_gym_trainers_1_62.jpg', 0, 0, 41),
(1, 'AeroFlex Basketball Shoes', 'AeroFlex Basketball Shoes is a breathable, cushioned sneaker built for everyday performance and comfort.', 599.00, 443, 4.6, 'aeroflex_basketball_shoes_1_63.jpg', 0, 0, 53),
(1, 'SprintX Casual Sneakers', 'SprintX Casual Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 399.00, NULL, 4.0, 'sprintx_casual_sneakers_1_64.jpg', 0, 0, 43),
(1, 'ZoomPace Running Sneakers', 'ZoomPace Running Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 1999.00, 1538, 4.8, 'zoompace_running_sneakers_1_65.jpg', 0, 0, 34),
(1, 'HyperBounce Walking Sneakers', 'HyperBounce Walking Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 599.00, 438, 4.3, 'hyperbounce_walking_sneakers_1_66.jpg', 0, 0, 72),
(1, 'CloudWalk Skate Sneakers', 'CloudWalk Skate Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 2999.00, NULL, 3.6, 'cloudwalk_skate_sneakers_1_67.jpg', 0, 0, 49),
(1, 'BoltRunner Casual Sneakers', 'BoltRunner Casual Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 2299.00, NULL, 4.3, 'boltrunner_casual_sneakers_1_68.jpg', 0, 0, 52),
(1, 'AirFlex Sports Sneakers', 'AirFlex Sports Sneakers is a breathable, cushioned sneaker built for everyday performance and comfort.', 2299.00, NULL, 3.9, 'airflex_sports_sneakers_1_69.jpg', 0, 1, 34),
(2, 'AquaComfort Outdoor Sandals', 'AquaComfort Outdoor Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 599.00, 484, 4.4, 'aquacomfort_outdoor_sandals_2_0.jpg', 0, 0, 66),
(2, 'DailyFit Formal Sandals', 'DailyFit Formal Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 699.00, NULL, 4.0, 'dailyfit_formal_sandals_2_1.jpg', 0, 0, 79),
(2, 'CoolStep Beach Sandals', 'CoolStep Beach Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 3299.00, 2539, 4.8, 'coolstep_beach_sandals_2_2.jpg', 0, 0, 13),
(2, 'AquaComfort Sports Sandals', 'AquaComfort Sports Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 599.00, 470, 4.8, 'aquacomfort_sports_sandals_2_3.jpg', 0, 1, 44),
(2, 'DailyFit Beach Sandals', 'DailyFit Beach Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 499.00, NULL, 3.8, 'dailyfit_beach_sandals_2_4.jpg', 0, 0, 45),
(2, 'ActiveStep Comfort Sandals', 'ActiveStep Comfort Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 999.00, NULL, 4.2, 'activestep_comfort_sandals_2_5.jpg', 0, 0, 70),
(2, 'TrailEase Beach Sandals', 'TrailEase Beach Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 2299.00, 1642, 3.7, 'trailease_beach_sandals_2_6.jpg', 1, 0, 73),
(2, 'AquaComfort Formal Sandals', 'AquaComfort Formal Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 1799.00, NULL, 4.1, 'aquacomfort_formal_sandals_2_7.jpg', 0, 1, 21),
(2, 'FlexiComfort Beach Sandals', 'FlexiComfort Beach Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 1999.00, 1346, 4.7, 'flexicomfort_beach_sandals_2_8.jpg', 0, 0, 10),
(2, 'SunStep Formal Sandals', 'SunStep Formal Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 2999.00, 2062, 4.0, 'sunstep_formal_sandals_2_9.jpg', 0, 0, 16),
(2, 'BreezeWalk Sports Sandals', 'BreezeWalk Sports Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 1199.00, 811, 3.9, 'breezewalk_sports_sandals_2_10.jpg', 0, 0, 13),
(2, 'ComfortWalk Outdoor Sandals', 'ComfortWalk Outdoor Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 1299.00, NULL, 4.0, 'comfortwalk_outdoor_sandals_2_11.jpg', 1, 0, 38),
(2, 'SummerStep Casual Sandals', 'SummerStep Casual Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 699.00, NULL, 3.7, 'summerstep_casual_sandals_2_12.jpg', 0, 0, 47),
(2, 'EasyStride Casual Sandals', 'EasyStride Casual Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 3499.00, NULL, 4.1, 'easystride_casual_sandals_2_13.jpg', 0, 0, 68),
(2, 'EasyStride Formal Sandals', 'EasyStride Formal Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 799.00, 667, 4.3, 'easystride_formal_sandals_2_14.jpg', 0, 0, 45),
(2, 'SummerStep Sports Sandals', 'SummerStep Sports Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 2799.00, 2260, 3.9, 'summerstep_sports_sandals_2_15.jpg', 1, 0, 72),
(2, 'FlexiComfort Formal Sandals', 'FlexiComfort Formal Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 799.00, 597, 4.0, 'flexicomfort_formal_sandals_2_16.jpg', 0, 0, 51),
(2, 'DailyFit Outdoor Sandals', 'DailyFit Outdoor Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 1199.00, NULL, 3.9, 'dailyfit_outdoor_sandals_2_17.jpg', 0, 0, 62),
(2, 'FlexiComfort Trekking Sandals', 'FlexiComfort Trekking Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 499.00, 372, 4.9, 'flexicomfort_trekking_sandals_2_18.jpg', 0, 0, 29),
(2, 'SoftLand Outdoor Sandals', 'SoftLand Outdoor Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 3299.00, NULL, 3.7, 'softland_outdoor_sandals_2_19.jpg', 0, 0, 22),
(2, 'CoolStep Formal Sandals', 'CoolStep Formal Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 2999.00, 2495, 3.5, 'coolstep_formal_sandals_2_20.jpg', 1, 0, 29),
(2, 'BreezeWalk Trekking Sandals', 'BreezeWalk Trekking Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 599.00, NULL, 5.0, 'breezewalk_trekking_sandals_2_21.jpg', 0, 0, 20),
(2, 'RelaxFit Trekking Sandals', 'RelaxFit Trekking Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 1999.00, NULL, 4.8, 'relaxfit_trekking_sandals_2_22.jpg', 0, 0, 72),
(2, 'FlexiComfort Casual Sandals', 'FlexiComfort Casual Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 499.00, NULL, 3.9, 'flexicomfort_casual_sandals_2_23.jpg', 0, 0, 39),
(2, 'TrailEase Walking Sandals', 'TrailEase Walking Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 599.00, 401, 4.5, 'trailease_walking_sandals_2_24.jpg', 0, 0, 48),
(2, 'TrailEase Trekking Sandals', 'TrailEase Trekking Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 399.00, 323, 3.9, 'trailease_trekking_sandals_2_25.jpg', 0, 1, 77),
(2, 'ComfortWalk Casual Sandals', 'ComfortWalk Casual Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 2799.00, NULL, 4.7, 'comfortwalk_casual_sandals_2_26.jpg', 1, 1, 58),
(2, 'BreezeWalk Walking Sandals', 'BreezeWalk Walking Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 1299.00, NULL, 4.4, 'breezewalk_walking_sandals_2_27.jpg', 0, 0, 68),
(2, 'ComfortWalk Formal Sandals', 'ComfortWalk Formal Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 1499.00, NULL, 4.8, 'comfortwalk_formal_sandals_2_28.jpg', 0, 0, 79),
(2, 'DailyFit Sports Sandals', 'DailyFit Sports Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 999.00, 838, 5.0, 'dailyfit_sports_sandals_2_29.jpg', 0, 0, 42),
(2, 'AquaComfort Trekking Sandals', 'AquaComfort Trekking Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 2999.00, NULL, 3.8, 'aquacomfort_trekking_sandals_2_30.jpg', 0, 0, 40),
(2, 'UrbanGlide Sports Sandals', 'UrbanGlide Sports Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 2499.00, NULL, 4.4, 'urbanglide_sports_sandals_2_31.jpg', 0, 0, 60),
(2, 'ActiveStep Formal Sandals', 'ActiveStep Formal Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 1499.00, 1234, 4.7, 'activestep_formal_sandals_2_32.jpg', 0, 0, 73),
(2, 'UrbanGlide Formal Sandals', 'UrbanGlide Formal Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 1799.00, NULL, 3.8, 'urbanglide_formal_sandals_2_33.jpg', 0, 1, 34),
(2, 'SoftLand Beach Sandals', 'SoftLand Beach Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 1499.00, NULL, 4.6, 'softland_beach_sandals_2_34.jpg', 0, 0, 22),
(2, 'TrailEase Sports Sandals', 'TrailEase Sports Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 499.00, 368, 4.4, 'trailease_sports_sandals_2_35.jpg', 0, 1, 47),
(2, 'SoftLand Formal Sandals', 'SoftLand Formal Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 1999.00, NULL, 3.8, 'softland_formal_sandals_2_36.jpg', 1, 0, 56),
(2, 'CoolStep Sports Sandals', 'CoolStep Sports Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 3499.00, NULL, 3.9, 'coolstep_sports_sandals_2_37.jpg', 1, 0, 71),
(2, 'ComfortWalk Comfort Sandals', 'ComfortWalk Comfort Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 1799.00, NULL, 4.0, 'comfortwalk_comfort_sandals_2_38.jpg', 1, 0, 28),
(2, 'CoolStep Trekking Sandals', 'CoolStep Trekking Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 1299.00, NULL, 4.6, 'coolstep_trekking_sandals_2_39.jpg', 0, 0, 56),
(2, 'SummerStep Formal Sandals', 'SummerStep Formal Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 599.00, NULL, 3.5, 'summerstep_formal_sandals_2_40.jpg', 0, 0, 43),
(2, 'SummerStep Trekking Sandals', 'SummerStep Trekking Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 2499.00, NULL, 4.9, 'summerstep_trekking_sandals_2_41.jpg', 1, 1, 13),
(2, 'SoftLand Walking Sandals', 'SoftLand Walking Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 1999.00, NULL, 3.8, 'softland_walking_sandals_2_42.jpg', 1, 0, 48),
(2, 'UrbanGlide Comfort Sandals', 'UrbanGlide Comfort Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 2799.00, 1845, 3.6, 'urbanglide_comfort_sandals_2_43.jpg', 0, 1, 40),
(2, 'AquaComfort Beach Sandals', 'AquaComfort Beach Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 799.00, 579, 4.9, 'aquacomfort_beach_sandals_2_44.jpg', 0, 0, 29),
(2, 'BreezeWalk Outdoor Sandals', 'BreezeWalk Outdoor Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 2799.00, NULL, 4.8, 'breezewalk_outdoor_sandals_2_45.jpg', 0, 0, 45),
(2, 'FlexiComfort Outdoor Sandals', 'FlexiComfort Outdoor Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 499.00, NULL, 3.8, 'flexicomfort_outdoor_sandals_2_46.jpg', 0, 1, 56),
(2, 'SunStep Sports Sandals', 'SunStep Sports Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 699.00, NULL, 4.1, 'sunstep_sports_sandals_2_47.jpg', 0, 0, 17),
(2, 'SoftLand Trekking Sandals', 'SoftLand Trekking Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 2499.00, 2108, 4.9, 'softland_trekking_sandals_2_48.jpg', 0, 1, 37),
(2, 'SunStep Trekking Sandals', 'SunStep Trekking Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 399.00, 286, 5.0, 'sunstep_trekking_sandals_2_49.jpg', 0, 1, 80),
(2, 'TrailEase Formal Sandals', 'TrailEase Formal Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 1199.00, NULL, 4.7, 'trailease_formal_sandals_2_50.jpg', 0, 0, 10),
(2, 'TrailEase Outdoor Sandals', 'TrailEase Outdoor Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 1499.00, NULL, 3.7, 'trailease_outdoor_sandals_2_51.jpg', 1, 0, 32),
(2, 'RelaxFit Beach Sandals', 'RelaxFit Beach Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 699.00, NULL, 3.5, 'relaxfit_beach_sandals_2_52.jpg', 1, 0, 40),
(2, 'BreezeWalk Formal Sandals', 'BreezeWalk Formal Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 1999.00, 1405, 3.7, 'breezewalk_formal_sandals_2_53.jpg', 0, 1, 18),
(2, 'TrailEase Casual Sandals', 'TrailEase Casual Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 3299.00, 2383, 4.4, 'trailease_casual_sandals_2_54.jpg', 0, 1, 15),
(2, 'CasualEdge Beach Sandals', 'CasualEdge Beach Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 3499.00, 2725, 3.5, 'casualedge_beach_sandals_2_55.jpg', 0, 0, 64),
(2, 'ComfortWalk Trekking Sandals', 'ComfortWalk Trekking Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 699.00, NULL, 4.9, 'comfortwalk_trekking_sandals_2_56.jpg', 1, 1, 28),
(2, 'RelaxFit Walking Sandals', 'RelaxFit Walking Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 599.00, 464, 4.4, 'relaxfit_walking_sandals_2_57.jpg', 0, 0, 77),
(2, 'CasualEdge Sports Sandals', 'CasualEdge Sports Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 1799.00, NULL, 4.4, 'casualedge_sports_sandals_2_58.jpg', 1, 0, 80),
(2, 'UrbanGlide Trekking Sandals', 'UrbanGlide Trekking Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 1199.00, 992, 4.1, 'urbanglide_trekking_sandals_2_59.jpg', 0, 0, 22),
(2, 'EasyStride Walking Sandals', 'EasyStride Walking Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 1999.00, 1565, 4.1, 'easystride_walking_sandals_2_60.jpg', 1, 0, 18),
(2, 'EasyStride Trekking Sandals', 'EasyStride Trekking Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 599.00, NULL, 3.6, 'easystride_trekking_sandals_2_61.jpg', 1, 0, 26),
(2, 'SummerStep Comfort Sandals', 'SummerStep Comfort Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 499.00, NULL, 4.3, 'summerstep_comfort_sandals_2_62.jpg', 0, 1, 55),
(2, 'CoolStep Casual Sandals', 'CoolStep Casual Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 2799.00, NULL, 4.6, 'coolstep_casual_sandals_2_63.jpg', 0, 0, 55),
(2, 'DailyFit Comfort Sandals', 'DailyFit Comfort Sandals is a lightweight sandal designed for all-day comfort in casual or active settings.', 699.00, NULL, 3.8, 'dailyfit_comfort_sandals_2_64.jpg', 0, 1, 23),
(3, 'SoftGlide Indoor Slipper', 'SoftGlide Indoor Slipper is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 1299.00, NULL, 4.8, 'softglide_indoor_slipper_3_0.jpg', 0, 1, 15),
(3, 'QuickStep Daily Chappal', 'QuickStep Daily Chappal is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 2799.00, 2335, 4.8, 'quickstep_daily_chappal_3_1.jpg', 0, 0, 63),
(3, 'EasyWalk Home Slipper', 'EasyWalk Home Slipper is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 1799.00, 1177, 4.0, 'easywalk_home_slipper_3_2.jpg', 0, 0, 56),
(3, 'LiteStep Indoor Slipper', 'LiteStep Indoor Slipper is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 599.00, 402, 4.2, 'litestep_indoor_slipper_3_3.jpg', 0, 1, 49),
(3, 'CozyWalk Indoor Slipper', 'CozyWalk Indoor Slipper is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 1999.00, 1611, 3.6, 'cozywalk_indoor_slipper_3_4.jpg', 0, 0, 34),
(3, 'LiteStep Party Slipper', 'LiteStep Party Slipper is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 2299.00, 1935, 4.5, 'litestep_party_slipper_3_5.jpg', 1, 1, 42),
(3, 'QuickStep Party Slipper', 'QuickStep Party Slipper is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 1199.00, 816, 4.6, 'quickstep_party_slipper_3_6.jpg', 1, 0, 73),
(3, 'HomeStep Daily Chappal', 'HomeStep Daily Chappal is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 2999.00, NULL, 4.6, 'homestep_daily_chappal_3_7.jpg', 0, 0, 51),
(3, 'RelaxSlide Casual Slide', 'RelaxSlide Casual Slide is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 1999.00, 1327, 4.2, 'relaxslide_casual_slide_3_8.jpg', 0, 0, 17),
(3, 'SimpleWear Party Slipper', 'SimpleWear Party Slipper is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 2299.00, NULL, 4.0, 'simplewear_party_slipper_3_9.jpg', 0, 1, 46),
(3, 'LiteStep Flip-Flop', 'LiteStep Flip-Flop is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 599.00, NULL, 5.0, 'litestep_flip_flop_3_10.jpg', 1, 0, 59),
(3, 'EasyWalk Indoor Slipper', 'EasyWalk Indoor Slipper is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 2999.00, NULL, 4.9, 'easywalk_indoor_slipper_3_11.jpg', 0, 1, 34),
(3, 'BasicComfort Outdoor Chappal', 'BasicComfort Outdoor Chappal is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 1999.00, NULL, 4.3, 'basiccomfort_outdoor_chappal_3_12.jpg', 0, 0, 53),
(3, 'EasyWalk Party Slipper', 'EasyWalk Party Slipper is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 599.00, NULL, 3.8, 'easywalk_party_slipper_3_13.jpg', 0, 0, 66),
(3, 'BasicComfort Indoor Slipper', 'BasicComfort Indoor Slipper is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 3499.00, NULL, 3.7, 'basiccomfort_indoor_slipper_3_14.jpg', 0, 0, 62),
(3, 'CozyWalk Home Slipper', 'CozyWalk Home Slipper is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 1999.00, NULL, 3.6, 'cozywalk_home_slipper_3_15.jpg', 0, 0, 52),
(3, 'QuickStep Outdoor Chappal', 'QuickStep Outdoor Chappal is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 699.00, NULL, 4.1, 'quickstep_outdoor_chappal_3_16.jpg', 0, 0, 29),
(3, 'Comfort Slide Casual Slide', 'Comfort Slide Casual Slide is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 1999.00, 1565, 4.9, 'comfort_slide_casual_slide_3_17.jpg', 0, 0, 60),
(3, 'CasualFlex Home Slipper', 'CasualFlex Home Slipper is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 799.00, NULL, 4.9, 'casualflex_home_slipper_3_18.jpg', 0, 0, 52),
(3, 'EasyWalk Daily Chappal', 'EasyWalk Daily Chappal is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 799.00, NULL, 4.7, 'easywalk_daily_chappal_3_19.jpg', 0, 0, 77),
(3, 'RelaxSlide Indoor Slipper', 'RelaxSlide Indoor Slipper is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 599.00, NULL, 4.1, 'relaxslide_indoor_slipper_3_20.jpg', 0, 0, 33),
(3, 'HomeStep Party Slipper', 'HomeStep Party Slipper is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 1199.00, 963, 3.8, 'homestep_party_slipper_3_21.jpg', 0, 1, 47),
(3, 'DailyWear Indoor Slipper', 'DailyWear Indoor Slipper is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 699.00, NULL, 4.3, 'dailywear_indoor_slipper_3_22.jpg', 0, 0, 53),
(3, 'DailyWear Daily Chappal', 'DailyWear Daily Chappal is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 799.00, NULL, 3.7, 'dailywear_daily_chappal_3_23.jpg', 1, 0, 31),
(3, 'CozyWalk Daily Chappal', 'CozyWalk Daily Chappal is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 2999.00, 2168, 4.6, 'cozywalk_daily_chappal_3_24.jpg', 0, 0, 67),
(3, 'BasicComfort Daily Chappal', 'BasicComfort Daily Chappal is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 1299.00, NULL, 4.0, 'basiccomfort_daily_chappal_3_25.jpg', 0, 0, 34),
(3, 'QuickStep Home Slipper', 'QuickStep Home Slipper is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 2299.00, NULL, 4.4, 'quickstep_home_slipper_3_26.jpg', 0, 0, 58),
(3, 'PlushStep Flip-Flop', 'PlushStep Flip-Flop is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 3499.00, NULL, 4.9, 'plushstep_flip_flop_3_27.jpg', 0, 0, 27),
(3, 'RelaxSlide Home Slipper', 'RelaxSlide Home Slipper is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 1499.00, 1118, 4.1, 'relaxslide_home_slipper_3_28.jpg', 0, 0, 76),
(3, 'SoftGlide Party Slipper', 'SoftGlide Party Slipper is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 699.00, 561, 3.9, 'softglide_party_slipper_3_29.jpg', 0, 1, 65),
(3, 'Comfort Slide Party Slipper', 'Comfort Slide Party Slipper is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 599.00, NULL, 3.8, 'comfort_slide_party_slipper_3_30.jpg', 0, 0, 13),
(3, 'Comfort Slide Flip-Flop', 'Comfort Slide Flip-Flop is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 2799.00, 2100, 3.9, 'comfort_slide_flip_flop_3_31.jpg', 0, 0, 13),
(3, 'LiteStep Outdoor Chappal', 'LiteStep Outdoor Chappal is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 1999.00, NULL, 4.8, 'litestep_outdoor_chappal_3_32.jpg', 0, 0, 27),
(3, 'CasualFlex Flip-Flop', 'CasualFlex Flip-Flop is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 499.00, 407, 4.5, 'casualflex_flip_flop_3_33.jpg', 1, 0, 67),
(3, 'LiteStep Daily Chappal', 'LiteStep Daily Chappal is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 399.00, NULL, 3.5, 'litestep_daily_chappal_3_34.jpg', 0, 1, 77),
(3, 'LiteStep Casual Slide', 'LiteStep Casual Slide is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 2799.00, 1981, 4.0, 'litestep_casual_slide_3_35.jpg', 1, 0, 68),
(3, 'SoftGlide Outdoor Chappal', 'SoftGlide Outdoor Chappal is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 599.00, 498, 4.4, 'softglide_outdoor_chappal_3_36.jpg', 1, 0, 40),
(3, 'HomeStep Home Slipper', 'HomeStep Home Slipper is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 799.00, 520, 4.0, 'homestep_home_slipper_3_37.jpg', 0, 1, 20),
(3, 'BasicComfort Flip-Flop', 'BasicComfort Flip-Flop is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 3499.00, NULL, 3.6, 'basiccomfort_flip_flop_3_38.jpg', 0, 0, 74),
(3, 'DailyWear Outdoor Chappal', 'DailyWear Outdoor Chappal is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 399.00, 297, 4.5, 'dailywear_outdoor_chappal_3_39.jpg', 0, 0, 12),
(3, 'CozyWalk Outdoor Chappal', 'CozyWalk Outdoor Chappal is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 2299.00, NULL, 4.0, 'cozywalk_outdoor_chappal_3_40.jpg', 0, 0, 52),
(3, 'CasualFlex Outdoor Chappal', 'CasualFlex Outdoor Chappal is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 799.00, 607, 4.7, 'casualflex_outdoor_chappal_3_41.jpg', 1, 0, 69),
(3, 'PlushStep Indoor Slipper', 'PlushStep Indoor Slipper is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 3299.00, NULL, 4.7, 'plushstep_indoor_slipper_3_42.jpg', 1, 0, 68),
(3, 'SimpleWear Home Slipper', 'SimpleWear Home Slipper is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 499.00, 329, 3.8, 'simplewear_home_slipper_3_43.jpg', 1, 0, 75),
(3, 'Comfort Slide Indoor Slipper', 'Comfort Slide Indoor Slipper is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 2499.00, NULL, 4.3, 'comfort_slide_indoor_slipper_3_44.jpg', 0, 0, 34),
(3, 'CozyWalk Flip-Flop', 'CozyWalk Flip-Flop is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 1799.00, 1450, 4.8, 'cozywalk_flip_flop_3_45.jpg', 0, 1, 57),
(3, 'LiteStep Home Slipper', 'LiteStep Home Slipper is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 2799.00, NULL, 4.6, 'litestep_home_slipper_3_46.jpg', 0, 0, 33),
(3, 'RelaxSlide Outdoor Chappal', 'RelaxSlide Outdoor Chappal is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 3299.00, NULL, 4.1, 'relaxslide_outdoor_chappal_3_47.jpg', 0, 0, 20),
(3, 'RelaxSlide Daily Chappal', 'RelaxSlide Daily Chappal is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 2799.00, 2157, 4.7, 'relaxslide_daily_chappal_3_48.jpg', 0, 0, 20),
(3, 'QuickStep Flip-Flop', 'QuickStep Flip-Flop is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 1999.00, NULL, 4.0, 'quickstep_flip_flop_3_49.jpg', 0, 0, 66),
(3, 'DailyWear Home Slipper', 'DailyWear Home Slipper is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 2299.00, 1829, 4.9, 'dailywear_home_slipper_3_50.jpg', 0, 0, 17),
(3, 'CasualFlex Party Slipper', 'CasualFlex Party Slipper is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 599.00, NULL, 4.1, 'casualflex_party_slipper_3_51.jpg', 0, 0, 30),
(3, 'DailyWear Casual Slide', 'DailyWear Casual Slide is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 399.00, 308, 4.7, 'dailywear_casual_slide_3_52.jpg', 1, 1, 56),
(3, 'CozyWalk Casual Slide', 'CozyWalk Casual Slide is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 2299.00, 1755, 4.4, 'cozywalk_casual_slide_3_53.jpg', 0, 0, 57),
(3, 'Comfort Slide Outdoor Chappal', 'Comfort Slide Outdoor Chappal is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 2999.00, NULL, 4.4, 'comfort_slide_outdoor_chappal_3_54.jpg', 0, 0, 45),
(3, 'HomeStep Flip-Flop', 'HomeStep Flip-Flop is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 1299.00, NULL, 3.5, 'homestep_flip_flop_3_55.jpg', 1, 0, 25),
(3, 'SoftGlide Daily Chappal', 'SoftGlide Daily Chappal is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 1499.00, NULL, 4.6, 'softglide_daily_chappal_3_56.jpg', 0, 0, 72),
(3, 'HomeStep Casual Slide', 'HomeStep Casual Slide is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 1199.00, 984, 4.2, 'homestep_casual_slide_3_57.jpg', 0, 0, 21),
(3, 'HomeStep Outdoor Chappal', 'HomeStep Outdoor Chappal is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 1999.00, NULL, 4.6, 'homestep_outdoor_chappal_3_58.jpg', 0, 0, 48),
(3, 'Comfort Slide Home Slipper', 'Comfort Slide Home Slipper is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 999.00, NULL, 4.9, 'comfort_slide_home_slipper_3_59.jpg', 0, 0, 75),
(3, 'SoftGlide Casual Slide', 'SoftGlide Casual Slide is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 1299.00, 897, 3.7, 'softglide_casual_slide_3_60.jpg', 0, 1, 80),
(3, 'BasicComfort Party Slipper', 'BasicComfort Party Slipper is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 2299.00, NULL, 5.0, 'basiccomfort_party_slipper_3_61.jpg', 1, 0, 18),
(3, 'EasyWalk Casual Slide', 'EasyWalk Casual Slide is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 1799.00, 1427, 4.2, 'easywalk_casual_slide_3_62.jpg', 0, 0, 19),
(3, 'PlushStep Casual Slide', 'PlushStep Casual Slide is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 799.00, NULL, 4.5, 'plushstep_casual_slide_3_63.jpg', 0, 0, 54),
(3, 'CozyWalk Party Slipper', 'CozyWalk Party Slipper is an easy-to-wear chappal with a soft footbed for daily indoor and outdoor use.', 799.00, NULL, 4.7, 'cozywalk_party_slipper_3_64.jpg', 0, 1, 26);

-- Product sizes (standard shoe sizes 6-10) for every product
INSERT INTO product_sizes (product_id, size, stock)
SELECT p.id, s.size, 10
FROM products p
JOIN (SELECT '6' AS size UNION SELECT '7' UNION SELECT '8' UNION SELECT '9' UNION SELECT '10') s;
