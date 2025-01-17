CREATE TABLE `ers_player_shifts` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_id` VARCHAR(30) NOT NULL,
    `start_time` VARCHAR(20) NOT NULL,
    `end_time` VARCHAR(20) DEFAULT NULL,
    `payment` INT DEFAULT NULL,
    `rate_per_minute` DECIMAL(10, 2) DEFAULT NULL,
    `shift_duration` INT DEFAULT NULL,
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;