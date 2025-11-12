CREATE TABLE IF NOT EXISTS `props` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `model` VARCHAR(255) NOT NULL,
    `coords_x` FLOAT NOT NULL,
    `coords_y` FLOAT NOT NULL,
    `coords_z` FLOAT NOT NULL,
    `heading` FLOAT NOT NULL,
    `permanent` BOOLEAN DEFAULT TRUE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 