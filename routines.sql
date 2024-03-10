SET NAMES utf8;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;
SET sql_mode = 'NO_AUTO_VALUE_ON_ZERO';


DELIMITER $$
DROP PROCEDURE IF EXISTS `inventory`$$
CREATE PROCEDURE `inventory`(
  IN `Location` char(64) CHARSET ascii
 ,IN `Sku_starts_with_or_empty_for_all` char(64) CHARSET ascii
)
BEGIN
  SELECT
    'The table ww_recent_inventory rows refreshed:' AS `Table refresh`
  ;
  CALL wwInventory(
    Location
   ,Sku_starts_with_or_empty_for_all
  )
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `pick`$$
CREATE PROCEDURE `pick`(
  IN `CompositeSKU` char(64) CHARSET ascii
)
BEGIN
  SELECT
    CompositeSKU AS `Composite SKU`
   ,`s`.`alt_code` AS `Ref`
   ,`s`.`description` AS `Product`
  FROM `ww_composite` AS `c`
  JOIN `ww_sku` AS `s`
    ON `s`.`sku`=`c`.`sku`
  WHERE `c`.`sku`=CompositeSKU
  LIMIT 0,1
  ;
  CALL wwPick(
    CompositeSKU
  )
  ;
END$$


DELIMITER ;

