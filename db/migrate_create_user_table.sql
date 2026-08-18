-- Fitbit Aria protocol user table
-- Based on: https://github.com/cequencer/helvetic/blob/a64b6faed38ad2b174144906724508b5aed6cb07/protocol.md
--
-- Protocol encoding: ASCII only (char[20] name field, single-byte encoding)
-- Non-ASCII characters are replaced with '?' during serialization
--
-- Password security: Passwords are hashed using bcrypt (Crypt::Bcrypt module)
-- Never store or log plaintext passwords. Always use hash_password() and verify_password()
-- from UserAuth module for password operations.
--
-- gender values (enum gender_type uint8):
--   0x00 = female
--   0x02 = male
--   0x34 = unknown (default)

CREATE TABLE IF NOT EXISTS `user` (
    id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
    name VARCHAR(20) NOT NULL COMMENT 'max 20 characters (Aria protocol limit: char[20])',
    birthdate DATE NULL,
    gender VARCHAR(10) NULL COMMENT 'male, female, unknown (converted to protocol enum on output)',
    height_mm INT UNSIGNED NULL,
    password_hash VARCHAR(255) NULL COMMENT 'bcrypt hash of password (60 chars) or longer for future algorithms',
    min_weight_tolerance INT UNSIGNED NULL DEFAULT 0,
    max_weight_tolerance INT UNSIGNED NULL DEFAULT 100000000,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_user_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
