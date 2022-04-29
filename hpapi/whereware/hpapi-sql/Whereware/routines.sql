
DELIMITER $$
DROP PROCEDURE IF EXISTS `wwBins`$$
CREATE PROCEDURE `wwBins`(
  IN `startsWith` varchar(64) CHARSET ascii
)
BEGIN
  SELECT
    *
  FROM `ww_bin`
  WHERE (
       startsWith IS NULL
    OR startsWith=''
    OR `bin` LIKE CONCAT(startsWith,'%')
  )
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwBookingInsert`$$
CREATE PROCEDURE `wwBookingInsert`(
)
BEGIN
  INSERT INTO `ww_booking`
  SET
    `notes`=''
  ;
  SELECT LAST_INSERT_ID() AS `id`
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwInventory`$$
CREATE PROCEDURE `wwInventory`(
  IN `Location` char(64) CHARSET ascii
 ,IN `Sku_starts_with_or_empty_for_all` char(64) CHARSET ascii
)
BEGIN
  SET @stamp = NOW()
  ;
  -- Inputs
  INSERT IGNORE INTO `ww_recent_inventory`
    (`sku`,`location`,`bin`)
    SELECT
      `sku`
     ,`to_location`
     ,`to_bin`
    FROM `ww_move`
    WHERE `cancelled`=0
      AND (
           `to_location`=Location
        OR `from_location`=Location
      )
      AND (
           Sku_starts_with_or_empty_for_all IS NULL
        OR Sku_starts_with_or_empty_for_all=''
        OR `sku` LIKE CONCAT(Sku_starts_with_or_empty_for_all,'%')
      )
    GROUP BY `sku`,`to_location`,`to_bin`
  ;
  DROP TABLE IF EXISTS `inv_in_tmp`
  ;
  CREATE TABLE `inv_in_tmp` AS
    SELECT
      `sku`
     ,`to_bin` AS `bin`
     ,MAX(`updated`) AS `updated`
     ,SUM(`quantity`*(`status`='F')) AS `fulfilled`
     ,SUM(`quantity`*(`status`='T')) AS `in_transit`
     ,SUM(`quantity`*(`status`='R')) AS `raised`
    FROM `ww_move`
    WHERE `cancelled`=0
      AND `to_location`=Location
      AND (
           Sku_starts_with_or_empty_for_all IS NULL
        OR Sku_starts_with_or_empty_for_all=''
        OR `sku` LIKE CONCAT(Sku_starts_with_or_empty_for_all,'%')
      )
    GROUP BY `sku`,`to_location`,`to_bin`
  ;
  UPDATE `inv_in_tmp` AS `t`
  JOIN `ww_recent_inventory` AS `i`
    ON `i`.`sku`=`t`.`sku`
   AND `i`.`location`=Location
   AND `i`.`bin`=`t`.`bin`
  SET
    `i`.`refreshed`=@stamp
   ,`i`.`updated`=IF(`i`.`updated` IS NULL OR `t`.`updated`>`i`.`updated`,`t`.`updated`,`i`.`updated`)
   ,`i`.`fulfilled`=`t`.`fulfilled`
   ,`i`.`in_transit`=`t`.`in_transit`
   ,`i`.`raised`=`t`.`raised`
   ,`i`.`in_bin`=`t`.`fulfilled`
   ,`i`.`available`=`t`.`fulfilled`
  ;
  DROP TABLE `inv_in_tmp`
  ;
  -- Outputs
  INSERT IGNORE INTO `ww_recent_inventory`
    (`sku`,`location`,`bin`)
    SELECT
      `sku`
     ,`from_location`
     ,`from_bin`
    FROM `ww_move`
    WHERE `cancelled`=0
      AND `from_location`=Location
      AND (
           Sku_starts_with_or_empty_for_all IS NULL
        OR Sku_starts_with_or_empty_for_all=''
        OR `sku` LIKE CONCAT(Sku_starts_with_or_empty_for_all,'%')
      )
    GROUP BY `sku`,`from_location`,`from_bin`
  ;
  DROP TABLE IF EXISTS `inv_out_tmp`
  ;
  CREATE TABLE `inv_out_tmp` AS
    SELECT
      `sku`
     ,`from_bin` AS `bin`
     ,MAX(`updated`) AS `updated`
     ,SUM(`quantity`) AS `moved_on`
     ,SUM(`quantity`*(`status`='R')) AS `spoken_for`
    FROM `ww_move`
    WHERE `cancelled`=0
      AND `from_location`=Location
      AND (
           Sku_starts_with_or_empty_for_all IS NULL
        OR Sku_starts_with_or_empty_for_all=''
        OR `sku` LIKE CONCAT(Sku_starts_with_or_empty_for_all,'%')
      )
    GROUP BY `sku`,`from_location`,`from_bin`
  ;
  UPDATE `inv_out_tmp` AS `t`
  JOIN `ww_recent_inventory` AS `i`
    ON `i`.`sku`=`t`.`sku`
   AND `i`.`location`=Location
   AND `i`.`bin`=`t`.`bin`
  SET
    `i`.`refreshed`=@stamp
   ,`i`.`updated`=IF(`i`.`updated` IS NULL OR `t`.`updated`>`i`.`updated`,`t`.`updated`,`i`.`updated`)
   ,`i`.`moved_on`=`t`.`moved_on`
   ,`i`.`in_bin`=`i`.`in_bin`-`t`.`moved_on`+`t`.`spoken_for`
   ,`i`.`available`=`i`.`available`-`t`.`moved_on`
  ;
  DROP TABLE `inv_out_tmp`
  ;
  UPDATE `ww_sku` AS `s`
  JOIN `ww_recent_inventory` AS `i`
    ON `i`.`sku`=`s`.`sku`
  SET
    `i`.`sku_additional_ref`=`s`.`additional_ref`
   ,`i`.`sku_name`=`s`.`name`
  ;
  SELECT
    *
  FROM `ww_recent_inventory`
  WHERE `refreshed`=@stamp
  ORDER BY `sku`,`location`,`bin`
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwLocations`$$
CREATE PROCEDURE `wwLocations`(
  IN `startsWith` varchar(64) CHARSET ascii
)
BEGIN
  SELECT
    *
  FROM `ww_location`
  WHERE (
       startsWith IS NULL
    OR startsWith=''
    OR `location` LIKE CONCAT(startsWith,'%')
  )
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwMoveCancel`$$
CREATE PROCEDURE `wwMoveCancel`(
  IN `bookingId` int(11) UNSIGNED
)
BEGIN
  UPDATE `ww_move`
  SET
    `cancelled`=1
  WHERE `booking_id`=bookingId
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwMoveInsert`$$
CREATE PROCEDURE `wwMoveInsert`(
   IN `orderRef` varchar(64)
  ,IN `bookingId` int(11) unsigned
  ,IN `sts` varchar(64)
  ,IN `qty` int(11) unsigned
  ,IN `sk` varchar(64)
  ,IN `frLoc` varchar(64)
  ,IN `frBin` varchar(64)
  ,IN `toLoc` varchar(64)
  ,IN `toBin` varchar(64)
)
BEGIN
  INSERT INTO `ww_move`
  SET
   `order_ref`=orderRef
  ,`booking_id`=bookingId
  ,`sts`=sts
  ,`quantity`=qty
  ,`sku`=sk
  ,`from_location`=frLoc
  ,`from_bin`=frBin
  ,`to_location`=toLoc
  ,`to_bin`=toBin
  ;
  SELECT LAST_INSERT_ID() AS `id`
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwOrder`$$
CREATE PROCEDURE `wwOrder`(
  IN `orderRef` char(64) CHARSET ascii
)
BEGIN
  SELECT
    `m`.`order_ref`
  FROM `ww_move` AS `m`
  WHERE `order_ref`=orderRef
--  JOIN (
--    SELECT
--      `sku`
--     ,MIN(`created`) AS `created`
--    FROM `ww_movelog`
--    GROUP BY `sku`
--  ) AS `lg`
--    ON `lg`.`sku`=`m`.`sku`
  LIMIT 0,1
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwOrders`$$
CREATE PROCEDURE `wwOrders`(
  IN `sku` char(64) CHARSET ascii
 ,IN `customersLike` char(64) CHARSET ascii
 ,IN `rowsLimit` int(11) UNSIGNED
)
BEGIN
  SELECT
    `m`.`order_ref`
   ,COUNT(DISTINCT IFNULL(`booking_id`,0)) AS `bookings`
   ,GROUP_CONCAT(DISTINCT `m`.`to_location` SEPARATOR ', ') AS `to_locations`
   ,GROUP_CONCAT(DISTINCT `l`.`name` SEPARATOR ', ') AS `to_locations_customer`
--   ,`lg`.`created`
  FROM `ww_move` AS `m`
--  JOIN (
--    SELECT
--      `sku`
--     ,MIN(`created`) AS `created`
--    FROM `ww_movelog`
--    GROUP BY `sku`
--  ) AS `lg`
--    ON `lg`.`sku`=`m`.`sku`
  LEFT JOIN `ww_location` as `l`
    ON `l`.`location`=`m`.`to_location`
   AND `l`.`location` LIKE CONCAT(customersLike,'%')
  WHERE `m`.`cancelled`=0
    AND `m`.`sku`=sku
  GROUP BY `m`.`order_ref`
--  ORDER BY `lg`.`created` DESC
  ORDER BY `m`.`order_ref` DESC
  LIMIT 0,rowsLimit
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwPick`$$
CREATE PROCEDURE `wwPick`(
  IN `CompositeSKU` char(64) CHARSET ascii
)
BEGIN
  SELECT
    `g`.`quantity`
   ,`g`.`generic`
   ,`g`.`name`
   ,GROUP_CONCAT(
      CONCAT(`s`.`sku`,':',`s`.`name`) ORDER BY `v`.`give_preference` DESC SEPARATOR ','
    ) AS `options_preferred_first`
  FROM `ww_generic` AS `g`
  JOIN `ww_variant` AS `v`
    ON `v`.`generic`=`g`.`generic`
  JOIN `ww_sku` AS `s`
    ON `s`.`sku`=`v`.`sku`
  WHERE `g`.`sku`=CompositeSKU
  GROUP BY `g`.`generic`
  ORDER BY `g`.`generic`
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwSkus`$$
CREATE PROCEDURE `wwSkus`(
  IN `likeString` varchar(64) CHARSET ascii
 ,IN `includeComponents` int(1) UNSIGNED
 ,IN `includeComposites` int(1) UNSIGNED
 ,IN `rowsLimit` int(11) UNSIGNED
)
BEGIN
  SELECT
    `s`.`updated`
   ,`s`.`hidden`
   ,`s`.`sku`
   ,`s`.`bin`
   ,`s`.`additional_ref`
   ,`s`.`name`
   ,`s`.`notes`
   ,`s`.`sku` LIKE CONCAT(TRIM('%' FROM likeString),'%') AS `by_sku_left`
   ,`s`.`additional_ref` LIKE CONCAT(TRIM('%' FROM likeString),'%') AS `by_additional_ref_left`
   ,`s`.`name` LIKE CONCAT(TRIM('%' FROM likeString),'%') AS `by_name_left`
   ,`s`.`sku` LIKE CONCAT('%',TRIM('%' FROM likeString),'%') AS `by_sku`
   ,`s`.`additional_ref` LIKE CONCAT('%',TRIM('%' FROM likeString),'%') AS `by_additional_ref`
   ,`s`.`name` LIKE CONCAT('%',TRIM('%' FROM likeString),'%') AS `by_name`
   ,DATE(`s`.`updated`)=REPLACE(TRIM('%' FROM likeString),'%','-') AS `by_updated`
  FROM `ww_sku` AS `s`
  LEFT JOIN `ww_composite` AS `c`
         ON `c`.`sku`=`s`.`sku`
  WHERE (
       likeString IS NULL
    OR likeString=''
    OR `s`.`sku` LIKE CONCAT('%',TRIM('%' FROM likeString),'%')
    OR `s`.`additional_ref` LIKE CONCAT('%',TRIM('%' FROM likeString),'%')
    OR `s`.`name` LIKE CONCAT('%',TRIM('%' FROM likeString),'%')
    OR DATE(`s`.`updated`)=REPLACE(TRIM('%' FROM likeString),'%','-')
  )
    AND (
         includeComponents>0
      OR `c`.`sku` IS NOT NULL
    )
    AND (
         includeComposites>0
      OR `c`.`sku` IS NULL
    )
    ORDER BY
      `by_updated`
     ,`by_sku_left` OR `by_additional_ref_left` OR `by_name_left` DESC
     ,`by_sku` DESC
     ,`by_additional_ref` DESC
     ,`by_name_left` DESC
     ,`s`.`sku`
    LIMIT 0,rowsLimit
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwStatuses`$$
CREATE PROCEDURE `wwStatuses`(
)
BEGIN
  SELECT
    *
  FROM `ww_status`
  ORDER BY `id`
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwUsers`$$
CREATE PROCEDURE `wwUsers`(
    IN `eml` varchar(254) CHARSET ascii
)
BEGIN
  SELECT
    *
  FROM `ww_user`
  WHERE ( eml IS NULL OR eml='' OR `email`=eml )
  ;
END$$



DELIMITER ;

