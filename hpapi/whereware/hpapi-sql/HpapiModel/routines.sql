
SET NAMES utf8;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;
SET sql_mode = 'NO_AUTO_VALUE_ON_ZERO';


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwSetPasswordHash`$$
CREATE PROCEDURE `wwSetPasswordHash`(
    IN `userId` INT(11) UNSIGNED
   ,IN `passwordHash` VARCHAR(255) CHARSET ascii
   ,IN `expiresTs` INT(11) UNSIGNED
   ,IN `verifiedState` INT(1) UNSIGNED
)
BEGIN
  UPDATE `hpapi_user`
  SET
    `password_hash`=passwordHash
   ,`password_expires`=FROM_UNIXTIME(expiresTs)
   ,`verified`=IFNULL(verifiedState,`verified`)
  WHERE `id`=userId
  ;
END$$

DELIMITER ;

