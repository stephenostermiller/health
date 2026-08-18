-- Migration to dedup metric_fact and remove source_file, source_row columns
-- For duplicates (same timestamp, metric, user_id), keep the one with the latest loaded_at

-- First, identify and delete all but the latest one per (timestamp, metric, user_id)
DELETE FROM metric_fact
WHERE CONCAT(`timestamp`, '|', metric, '|', user_id) IN (
    SELECT CONCAT(mf.`timestamp`, '|', mf.metric, '|', mf.user_id)
    FROM metric_fact mf
    WHERE (mf.`timestamp`, mf.metric, mf.user_id, mf.loaded_at) NOT IN (
        SELECT `timestamp`, metric, user_id, MAX(loaded_at)
        FROM metric_fact
        GROUP BY `timestamp`, metric, user_id
    )
);

-- Now alter the table to remove the columns and change the primary key
ALTER TABLE metric_fact DROP PRIMARY KEY;
ALTER TABLE metric_fact DROP COLUMN source_file;
ALTER TABLE metric_fact DROP COLUMN source_row;
ALTER TABLE metric_fact ADD PRIMARY KEY (`timestamp`, metric, user_id);
