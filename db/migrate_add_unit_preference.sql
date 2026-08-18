-- Add unit preference field to user table
-- Stores preferred unit system: 'imperial' (feet/inches) or 'metric' (meters)
ALTER TABLE `user` ADD COLUMN unit_preference ENUM('imperial', 'metric') DEFAULT 'imperial' COMMENT 'preferred unit system';
