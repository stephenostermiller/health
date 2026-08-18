-- Convert gender column to VARCHAR
ALTER TABLE `user` MODIFY COLUMN gender VARCHAR(10) NULL COMMENT 'male, female, unknown (converted to protocol enum on output)';
