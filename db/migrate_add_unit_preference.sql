-- Add unit preference field to user table
ALTER TABLE `user` ADD COLUMN unit_preference ENUM('imperial', 'metric') DEFAULT 'imperial' COMMENT 'preferred unit system';
