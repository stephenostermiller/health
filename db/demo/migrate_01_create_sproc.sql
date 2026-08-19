DELIMITER ;;

DROP PROCEDURE IF EXISTS update_demo_timestamps;

CREATE PROCEDURE update_demo_timestamps()
BEGIN
  DECLARE v_max_timestamp DATETIME;
  DECLARE v_delta INT;

  SELECT MAX(`timestamp`) INTO v_max_timestamp FROM `metric_fact` WHERE user_id = 12345;
  SET v_delta = TIMESTAMPDIFF(DAY, v_max_timestamp, NOW());

  IF v_delta != 0 THEN
    UPDATE `metric_fact` SET `timestamp` = ADDDATE(`timestamp`, INTERVAL v_delta DAY) WHERE user_id = 12345;
    CALL refresh_metric_aggregates();
  END IF;
END;;

DELIMITER ;
