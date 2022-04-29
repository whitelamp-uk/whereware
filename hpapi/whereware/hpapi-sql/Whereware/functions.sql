

DELIMITER $$
DROP FUNCTION IF EXISTS `wwCTZIn`$$
CREATE FUNCTION `wwCTZIn` (
  t timestamp
) RETURNS timestamp DETERMINISTIC
BEGIN
  IF (@hpapiTimezone IS NULL) THEN BEGIN
    SET @hpapiTimezone = 'Europe/London'
    ;
    END
    ;
  END IF
  ;
  RETURN CONVERT_TZ(t,@hpapiTimezone,'UTC');
END$$


DELIMITER $$
DROP FUNCTION IF EXISTS `wwCTZOut`$$
CREATE FUNCTION `wwCTZOut` (
  t timestamp
) RETURNS timestamp DETERMINISTIC
BEGIN
  IF (@hpapiTimezone IS NULL) THEN BEGIN
    SET @hpapiTimezone = 'Europe/London'
    ;
    END
    ;
  END IF
  ;
  RETURN CONVERT_TZ(t,'UTC',@hpapiTimezone);
END$$


DELIMITER ;

