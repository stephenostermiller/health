-- Add user profile fields: user_name and initials
ALTER TABLE `user`
ADD COLUMN `user_name` VARCHAR(30) NULL AFTER `name`,
ADD COLUMN `initials` VARCHAR(3) NULL AFTER `user_name`,
ADD UNIQUE KEY `idx_user_user_name` (`user_name`);
