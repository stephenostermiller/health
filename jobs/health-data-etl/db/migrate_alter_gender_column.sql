-- Convert gender column to store readable values (male, female, unknown)
-- instead of numeric enum values
ALTER TABLE `user` MODIFY COLUMN gender VARCHAR(10) NULL COMMENT 'male, female, unknown (converted to protocol enum on output)';
