-- Remove source_file, source_row columns if they exist
-- (Only relevant if database started from very old schema)
ALTER TABLE metric_fact DROP PRIMARY KEY;
ALTER TABLE metric_fact DROP COLUMN IF EXISTS source_file;
ALTER TABLE metric_fact DROP COLUMN IF EXISTS source_row;
ALTER TABLE metric_fact ADD PRIMARY KEY (`timestamp`, metric, user_id);
