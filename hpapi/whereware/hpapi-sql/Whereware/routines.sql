
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
DROP PROCEDURE IF EXISTS `wwBlueprint`$$
CREATE PROCEDURE `wwBlueprint`(
  IN `compositeSKU` char(64) CHARSET ascii
)
BEGIN
  SELECT
    `c`.`sku`
   ,`c`.`alt_code`
   ,`c`.`description`
   ,`g`.`quantity`
   ,`g`.`generic`
   ,`g`.`name`
   ,GROUP_CONCAT(
      CONCAT_WS(':',`v`.`quantity`,`v`.`sku`,`s`.`alt_code`,`s`.`description`) ORDER BY `v`.`give_preference` DESC SEPARATOR ','
    ) AS `options_preferred_first`
  FROM `ww_generic` AS `g`
  JOIN `ww_variant` AS `v`
    ON `v`.`generic`=`g`.`generic`
  JOIN `ww_sku` AS `s`
    ON `s`.`sku`=`v`.`sku`
  JOIN `ww_sku` AS `c`
    ON `c`.`sku`=`g`.`sku`
  WHERE `g`.`sku`=compositeSKU
  GROUP BY `g`.`generic`
  ORDER BY `g`.`generic`
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwBooking`$$
CREATE PROCEDURE `wwBooking`(
  IN `bookingId` int(11) UNSIGNED
)
BEGIN
  SELECT
    *
  FROM `ww_move`
  WHERE `cancelled`=0
    AND `booking_id`=bookingId
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwBookingCancel`$$
CREATE PROCEDURE `wwBookingCancel`(
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
DROP PROCEDURE IF EXISTS `wwBookingInsert`$$
CREATE PROCEDURE `wwBookingInsert`(
  IN `bookBooker` char(255) CHARSET ascii
 ,IN `bookProject` char(64) CHARSET ascii
 ,IN `bookOrderRef` char(64) CHARSET ascii
 ,IN `bookType` char(64) CHARSET ascii
 ,IN `bookExport` tinyint(1) unsigned
 ,IN `bookShipmentDetails` text CHARSET utf8
 ,IN `bookDeliverBy` date
 ,IN `bookETA` date
 ,IN `bookPickScheduled` date
 ,IN `bookPickBy` date
 ,IN `bookPreferBy` date
 ,IN `bookNotes` text CHARSET utf8
)
BEGIN
  INSERT INTO `ww_booking`
  SET
    `updated`= NOW()
   ,`project`=bookProject
   ,`booker`=bookBooker
   ,`order_ref`=bookOrderRef
   ,`type`=bookType
   ,`shipment_details`=bookShipmentDetails
   ,`export`=bookExport
   ,`eta`=bookEta
   ,`prefer_by`=bookPreferBy
   ,`pick_scheduled`=bookPickScheduled
   ,`pick_by`=bookPickBy
   ,`deliver_by`=bookDeliverBy
   ,`notes`=bookNotes
  ;
  SELECT LAST_INSERT_ID() AS `id`
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwBookingRelocate`$$
CREATE PROCEDURE `wwBookingRelocate`(
   IN `relocater` varchar(64)
  ,IN `bookingId` int(11) unsigned
  ,IN `fromLocation` char(64) CHARSET ascii
  ,IN `fromBin` char(64) CHARSET ascii
  ,IN `toLocation` char(64) CHARSET ascii
  ,IN `toBin` char(64) CHARSET ascii
)
BEGIN
  UPDATE `ww_move`
  SET
    `updater`=relocater
   ,`from_location`=IF(fromLocation IS NULL OR fromLocation='',`from_location`,fromLocation)
   ,`from_bin`=IF(fromBin IS NULL OR fromBin='',`from_bin`,fromBin)
   ,`to_location`=IF(toLocation IS NULL OR toLocation='',`to_location`,toLocation)
   ,`to_bin`=IF(toBin IS NULL OR toBin='',`to_bin`,toBin)
  WHERE `booking_id`=bookingId
    AND `from_location` NOT LIKE 'W-%'
    AND `to_location` NOT LIKE 'W-%'
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwGenerics`$$
CREATE PROCEDURE `wwGenerics`(
  IN `likeString` varchar(64) CHARSET ascii
 ,IN `rowsLimit` int(11) UNSIGNED
)
BEGIN
  SELECT
    `g`.`updated`
   ,`g`.`hidden`
   ,`g`.`sku`
   ,`g`.`quantity`
   ,`g`.`generic`
   ,`g`.`name`
   ,`g`.`notes`
   ,`g`.`sku`=likeString AS `matches_exactly_on_sku`
   ,`g`.`generic`=likeString AS `matches_on_generic_exactly`
   ,`g`.`sku` LIKE CONCAT(likeString,'%') AS `matches_on_sku_left`
   ,`g`.`generic` LIKE CONCAT(likeString,'%') AS `matches_on_generic_left`
   ,`g`.`name` LIKE CONCAT(likeString,'%') AS `matches_on_name_left`
   ,`s`.`alt_code` LIKE CONCAT(likeString,'%') AS `matches_on_alt_code_left`
   ,`s`.`description` LIKE CONCAT(likeString,'%') AS `matches_on_description_left`
   ,`g`.`sku` LIKE CONCAT('%',likeString,'%') AS `matches_on_sku`
   ,`g`.`generic` LIKE CONCAT('%',likeString,'%') AS `matches_on_generic`
   ,`g`.`name` LIKE CONCAT('%',likeString,'%') AS `matches_on_name`
   ,`s`.`alt_code` LIKE CONCAT('%',likeString,'%') AS `matches_on_alt_code`
   ,`s`.`description` LIKE CONCAT('%',likeString,'%') AS `matches_on_description`
   ,CONCAT(`g`.`sku`,`g`.`generic`,`g`.`name`,`s`.`alt_code`,`s`.`description`) LIKE CONCAT('%',likeString,'%') AS `matches`
   ,CONCAT(`s`.`description`,`s`.`alt_code`,`g`.`name`,`g`.`generic`,`g`.`sku`) LIKE CONCAT('%',likeString,'%') AS `matches_reverse`
  FROM `ww_generic` AS `g`
  JOIN `ww_composite` AS `c`
    ON `c`.`sku`=`g`.`sku`
  JOIN `ww_sku` AS `s`
    ON `s`.`sku`=`c`.`sku`
  WHERE likeString IS NULL
     OR likeString=''
     OR CONCAT(`g`.`sku`,`g`.`generic`,`g`.`name`,`s`.`alt_code`,`s`.`description`) LIKE CONCAT('%',likeString,'%')
     OR CONCAT(`s`.`description`,`s`.`alt_code`,`g`.`name`,`g`.`generic`,`g`.`sku`) LIKE CONCAT('%',likeString,'%')
  ORDER BY
    `matches_on_sku_left` DESC
   ,`matches_on_generic_left` DESC
   ,`matches_on_name_left` DESC
   ,`matches_on_alt_code_left` DESC
   ,`matches_on_description_left` DESC
   ,`matches_on_sku` DESC
   ,`matches_on_generic` DESC
   ,`matches_on_name` DESC
   ,`matches_on_alt_code` DESC
   ,`matches_on_description` DESC
   ,`matches` DESC
   ,`matches_reverse` DESC
   ,`g`.`generic`
  LIMIT 0,rowsLimit
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwHide`$$
CREATE PROCEDURE `wwHide`(
  IN `tableName` char(64) CHARSET ascii
 ,IN `columnName` char(64) CHARSET ascii
 ,IN `columnValue` char(64) CHARSET ascii
)
BEGIN
  EXECUTE IMMEDIATE CONCAT('UPDATE `',tableName,'` SET `hidden`=1 WHERE `',columnName,'`=?') USING columnValue
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwInventory`$$
CREATE PROCEDURE `wwInventory`(
  IN `inventoryLocation` char(64) CHARSET ascii
 ,IN `Sku_starts_with_or_empty_for_all` char(64) CHARSET ascii
)
BEGIN
  SET @stamp = NOW()
  ;
  -- Reset inventory to zero
  UPDATE `ww_recent_inventory`
  SET
    `moved_on`=0
   ,`fulfilled`=0
   ,`in_transit`=0
   ,`raised`=0
   ,`in_bin`=0
   ,`available`=0
  WHERE `location`=inventoryLocation
    AND (
        Sku_starts_with_or_empty_for_all IS NULL
     OR Sku_starts_with_or_empty_for_all=''
     OR `sku` LIKE CONCAT(Sku_starts_with_or_empty_for_all,'%')
  )
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
      AND `to_location`=inventoryLocation
      AND (
           Sku_starts_with_or_empty_for_all IS NULL
        OR Sku_starts_with_or_empty_for_all=''
        OR `sku` LIKE CONCAT(Sku_starts_with_or_empty_for_all,'%')
      )
    GROUP BY `sku`,`to_bin`
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
      AND `from_location`=inventoryLocation
      AND (
           Sku_starts_with_or_empty_for_all IS NULL
        OR Sku_starts_with_or_empty_for_all=''
        OR `sku` LIKE CONCAT(Sku_starts_with_or_empty_for_all,'%')
      )
    GROUP BY `sku`,`from_bin`
  ;
  -- Inputs
  DROP TEMPORARY TABLE IF EXISTS `inv_in_tmp`
  ;
  CREATE TEMPORARY TABLE `inv_in_tmp` AS
    SELECT
      `sku`
     ,`to_bin` AS `bin`
     ,MAX(`updated`) AS `updated`
     ,SUM(`quantity`*(`status`='F')) AS `fulfilled`
     ,SUM(`quantity`*(`status`='T')) AS `in_transit`
     ,SUM(`quantity`*(`status`='R')) AS `raised`
    FROM `ww_move`
    WHERE `cancelled`=0
      AND `status` IN ('R','T','F')
      AND `to_location`=inventoryLocation
      AND (
           Sku_starts_with_or_empty_for_all IS NULL
        OR Sku_starts_with_or_empty_for_all=''
        OR `sku` LIKE CONCAT(Sku_starts_with_or_empty_for_all,'%')
      )
    GROUP BY `sku`,`bin`
  ;
  UPDATE `inv_in_tmp` AS `t`
  JOIN `ww_recent_inventory` AS `i`
    ON `i`.`sku`=`t`.`sku`
   AND `i`.`location`=inventoryLocation
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
  DROP TEMPORARY TABLE `inv_in_tmp`
  ;
  -- Outputs
  DROP TEMPORARY TABLE IF EXISTS `inv_out_tmp`
  ;
  CREATE TEMPORARY TABLE `inv_out_tmp` AS
    SELECT
      `sku`
     ,`from_bin` AS `bin`
     ,MAX(`updated`) AS `updated`
     ,SUM(`quantity`) AS `moved_on`
     ,SUM(`quantity`*(`status`='R')) AS `spoken_for`
    FROM `ww_move`
    WHERE `cancelled`=0
      AND `status` IN ('R','T','F')
      AND `from_location`=inventoryLocation
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
   AND `i`.`location`=inventoryLocation
   AND `i`.`bin`=`t`.`bin`
  SET
    `i`.`refreshed`=@stamp
   ,`i`.`updated`=IF(`i`.`updated` IS NULL OR `t`.`updated`>`i`.`updated`,`t`.`updated`,`i`.`updated`)
   ,`i`.`moved_on`=`t`.`moved_on`
   ,`i`.`in_bin`=`i`.`in_bin`-`t`.`moved_on`+`t`.`spoken_for`
   ,`i`.`available`=`i`.`available`-`t`.`moved_on`
  ;
  DROP TEMPORARY TABLE `inv_out_tmp`
  ;
  UPDATE `ww_sku` AS `s`
  JOIN `ww_recent_inventory` AS `i`
    ON `i`.`location`=inventoryLocation
   AND `i`.`sku`=`s`.`sku`
  SET
    `i`.`sku_alt_code`=`s`.`alt_code`
   ,`i`.`sku_description`=`s`.`description`
  ;
  SELECT
    `i`.*
   ,`i`.`sku`=Sku_starts_with_or_empty_for_all as `matches`
   ,IFNULL(`s`.`bin`=`i`.`bin`,0) AS `is_home_bin`
  FROM `ww_recent_inventory` AS `i`
  LEFT JOIN `ww_sku` AS `s`
         ON `s`.`sku`=`i`.`sku`
  WHERE `i`.`location`=inventoryLocation
    AND (
        Sku_starts_with_or_empty_for_all IS NULL
     OR Sku_starts_with_or_empty_for_all=''
     OR `i`.`sku` LIKE CONCAT(Sku_starts_with_or_empty_for_all,'%')
  )
  ORDER BY `matches` DESC,`sku`,`available` DESC
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
  ORDER BY `location`=startsWith DESC,`location`
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwLocationInsertMissing`$$
CREATE PROCEDURE `wwLocationInsertMissing`(
   IN `locationCode` char(64)
  ,IN `locationName` char(64)
  ,IN `locationNotes` text
)
BEGIN
  SET @id = (
    SELECT `id` FROM `ww_location` WHERE `location`=locationCode
  )
  ;
  IF @id>0  THEN
    SELECT
      @id AS `id`
    ;
  ELSE
    INSERT INTO `ww_location`
    SET
      `updated`=NOW()
     ,`location`=locationCode
     ,`name`=locationName
     ,`notes`=locationNotes
    ;
    SELECT LAST_INSERT_ID() AS `id`
    ;
  END IF
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwMoveAssign`$$
CREATE PROCEDURE `wwMoveAssign`(
   IN `assigner` varchar(64)
  ,IN `moveId` int(11) unsigned
  ,IN `projectCode` char(64) CHARSET ascii
  ,IN `taskId` int(11) unsigned
  ,IN `teamCode` char(64) CHARSET ascii
)
BEGIN
  UPDATE `ww_move`
  SET
    `updater`=assigner
   ,`project`=projectCode
   ,`task_id`=taskId
   ,`team`=teamCode
  WHERE `id`=moveId
  LIMIT 1
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwMoveInsert`$$
CREATE PROCEDURE `wwMoveInsert`(
   IN `inserter` varchar(64)
  ,IN `orderRef` varchar(64)
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
    `updater`=inserter
   ,`order_ref`=orderRef
   ,`booking_id`=bookingId
   ,`status`=sts
   ,`quantity`=qty
   ,`sku`=sk
   ,`from_location`=frLoc
   ,`from_bin`=frBin
   ,`to_location`=toLoc
   ,`to_bin`=toBin
   ,`notes`='' 
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
  WHERE `cancelled`=0
    AND `order_ref`=orderRef
  LIMIT 0,1
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwOrders`$$
CREATE PROCEDURE `wwOrders`(
  IN `sku` char(64) CHARSET ascii
 ,IN `destinationsLike` char(64) CHARSET ascii
 ,IN `rowsLimit` int(11) UNSIGNED
)
BEGIN
  SELECT
    sku AS `sku`
   ,`m`.`order_ref`
   ,MAX(`m`.`updated`) AS `order_updated`
   ,COUNT(DISTINCT IFNULL(`m`.`booking_id`,0)) AS `bookings`
   ,IFNULL(`mdest`.`to_location`,'') AS `destination_last`
   ,IFNULL(`l`.`name`,'') AS `destination_last_name`
  FROM `ww_move` AS `m`
  LEFT JOIN (
    SELECT
      `order_ref`
     ,MAX(`id`) AS `id_latest`
    FROM `ww_move`
    WHERE `cancelled`=0
      AND `sku`=sku
      AND `to_location` LIKE CONCAT(destinationsLike,'%')
    GROUP BY `order_ref`
  ) AS `mlast`
    ON `mlast`.`order_ref`=`m`.`order_ref`
  LEFT JOIN `ww_move` AS `mdest`
         ON `mdest`.`id`=`mlast`.`id_latest`
  LEFT JOIN `ww_location` as `l`
         ON `l`.`location`=`mdest`.`to_location`
  WHERE `m`.`cancelled`=0
    AND `m`.`order_ref`!=''
    AND `m`.`sku`=sku
  GROUP BY `order_ref`
  ORDER BY `order_updated` DESC
  LIMIT 0,rowsLimit
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwProjectInsert`$$
CREATE PROCEDURE `wwProjectInsert`(
   IN `projectCode` char(64)
  ,IN `projectName` char(64)
  ,IN `projectNotes` text
)
BEGIN
  INSERT INTO `ww_project`
  SET
    `updated`=NOW()
   ,`project`=projectCode
   ,`name`=projectName
   ,`notes`=projectNotes
  ;
  SELECT LAST_INSERT_ID() AS `id`
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwProjectSkuInsert`$$
CREATE PROCEDURE `wwProjectSkuInsert`(
   IN `projectCode` char(64)
  ,IN `skuCode` char(64)
  ,IN `binCode` char(64)
  ,IN `skuName` varchar(64)
  ,IN `skuComposite` tinyint(1)
)
BEGIN
  INSERT INTO `ww_bin`
  SET
    `updated`=NOW()
   ,`bin`=binCode
  ON DUPLICATE KEY UPDATE
    `bin`=binCode
  ;
  INSERT INTO `ww_sku`
  SET
    `updated`=NOW()
   ,`sku`=skuCode
   ,`bin`=binCode
   ,`name`=skuName
  ON DUPLICATE KEY UPDATE
    `sku`=skuCode
  ;
  IF ROW_COUNT()>0 AND skuComposite>0 THEN
    INSERT INTO `ww_composite`
    SET
      `updated`=NOW()
     ,`sku`=skuCode
    ON DUPLICATE KEY UPDATE
      `sku`=skuCode
  ;
  END IF
  ;
  INSERT INTO `ww_project_sku`
  SET
    `updated`=NOW()
   ,`project`=projectCode
   ,`sku`=skuCode
  ON DUPLICATE KEY UPDATE
    `sku`=skuCode
  ;
  SELECT LAST_INSERT_ID() AS `id`
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwProjects`$$
CREATE PROCEDURE `wwProjects`(
  IN `project` varchar(64) CHARSET ascii
)
BEGIN
  SELECT
    `p`.`project`
   ,`p`.`hidden`
   ,`p`.`name`
   ,`p`.`notes`
   ,`s`.`sku`
   ,(`s`.`hidden` OR `ps`.`hidden`) AS `sku_hidden`
   ,`s`.`alt_code` AS `sku_alt_code`
   ,`s`.`bin`
   ,`s`.`description` AS `sku_description`
   ,`s`.`notes` AS `sku_notes`
  FROM `ww_project` AS `p`
  LEFT JOIN `ww_project_sku` AS `ps`
    ON `ps`.`project`=`p`.`project`
  LEFT JOIN `ww_sku` AS `s`
    ON `s`.`sku`=`ps`.`sku`
  WHERE (project IS NULL OR `p`.`project`=project)
  GROUP BY `p`.`project`,`s`.`sku`
  ORDER BY `p`.`project`,`s`.`sku`
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwSkuInsert`$$
CREATE PROCEDURE `wwSkuInsert`(
   IN `newSku` char(64)
  ,IN `newBin` char(64)
  ,IN `newAltCode` char(64)
  ,IN `newUnitPrice` decimal(8,2) unsigned
  ,IN `newDescription` varchar(64)
  ,IN `newNotes` text
)
BEGIN
  INSERT INTO `ww_sku`
  SET
    `sku`=newSku
   ,`bin`=newBin
   ,`alt_code`=newAltCode
   ,`unit_price`=newUnitPrice
   ,`description`=newDescription
   ,`notes`=newNotes
  ;
  SELECT LAST_INSERT_ID() AS `id`
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwSkuUpdate`$$
CREATE PROCEDURE `wwSkuUpdate`(
   IN `oldSku` char(64)
  ,IN `newBin` char(64)
  ,IN `newAltCode` char(64)
  ,IN `newUnitPrice` decimal(8,2) unsigned
  ,IN `newDescription` varchar(64)
  ,IN `newNotes` text
)
BEGIN
  UPDATE `ww_sku`
  SET
    `bin`=newBin
   ,`alt_code`=newAltCode
   ,`unit_price`=newUnitPrice
   ,`description`=newDescription
   ,`notes`=newNotes
  WHERE `sku`=oldSku
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwSkus`$$
CREATE PROCEDURE `wwSkus`(
  IN `likeString` varchar(64) CHARSET ascii
 ,IN `includeComponents` int(1) UNSIGNED
 ,IN `includeComposites` int(1) UNSIGNED
 ,IN `rowsLimit` int(11) UNSIGNED
 ,IN `locationComponent` varchar(64) CHARSET ascii
 ,IN `locationComposite` varchar(64) CHARSET ascii
)
BEGIN
  SELECT
    `s`.`updated`
   ,`s`.`hidden`
   ,`s`.`sku`
   ,`c`.`sku` IS NOT NULL AS `is_composite`
   ,`s`.`bin` AS `bin`
   ,`s`.`alt_code`
   ,`s`.`unit_price`
   ,`s`.`description`
   ,`s`.`notes`
   ,`m`.`sku` IS NOT NULL AS `moved`
   ,`s`.`sku`=likeString AS `matches_exactly_on_sku`
   ,`s`.`sku` LIKE CONCAT(TRIM('%' FROM likeString),'%') AS `matches_on_sku_left`
   ,`s`.`alt_code` LIKE CONCAT(TRIM('%' FROM likeString),'%') AS `matches_on_alt_code_left`
   ,`s`.`description` LIKE CONCAT(TRIM('%' FROM likeString),'%') AS `matches_on_description_left`
   ,`s`.`sku` LIKE CONCAT('%',TRIM('%' FROM likeString),'%') AS `matches_on_sku`
   ,`s`.`alt_code` LIKE CONCAT('%',TRIM('%' FROM likeString),'%') AS `matches_on_alt_code`
   ,`s`.`description` LIKE CONCAT('%',TRIM('%' FROM likeString),'%') AS `matches_on_description`
   ,CONCAT(`s`.`sku`,`s`.`alt_code`,`s`.`description`) LIKE CONCAT('%',TRIM('%' FROM likeString),'%') AS `matches`
   ,CONCAT(`s`.`description`,`s`.`alt_code`,`s`.`sku`) LIKE CONCAT('%',TRIM('%' FROM likeString),'%') AS `matches_reverse`
   ,SUBSTRING_INDEX(`s`.`sku`,'-',2) AS `sku_group`
   ,1*SUBSTR(`s`.`sku`,LENGTH(SUBSTRING_INDEX(`s`.`sku`,'-',2))+2) AS `sku_group_id`
   ,IF(
      `c`.`sku` IS NOT NULL
     ,CONCAT(locationComposite,'/',`s`.`bin`)
     ,CONCAT(locationComponent,'/',`s`.`bin`)
    ) AS `location_bin`
   ,IF(
      `c`.`sku` IS NOT NULL
     ,IFNULL(`assemblies`.`in_bins`,0)
     ,IFNULL(`parts`.`in_bins`,0)
    ) AS `in_bins`
   ,IF(
      `c`.`sku` IS NOT NULL
     ,IFNULL(`assemblies`.`available`,0)
     ,IFNULL(`parts`.`available`,0)
    ) AS `available`
  FROM `ww_sku` AS `s`
  LEFT JOIN `ww_composite` AS `c`
         ON `c`.`sku`=`s`.`sku`
  LEFT JOIN (
    SELECT
      `sku`
     ,SUM(`in_bin`) AS `in_bins`
     ,SUM(`available`) AS `available`
    FROM `ww_recent_inventory`
    WHERE `location`=locationComponent
    GROUP BY `sku`
  )      AS `parts`
         ON LENGTH(locationComponent)>0
        AND `parts`.`sku`=`s`.`sku`
  LEFT JOIN (
    SELECT
      `sku`
     ,SUM(`in_bin`) AS `in_bins`
     ,SUM(`available`) AS `available`
    FROM `ww_recent_inventory`
    WHERE `location`=locationComposite
    GROUP BY `sku`
  )      AS `assemblies`
         ON LENGTH(locationComposite)>0
        AND `assemblies`.`sku`=`s`.`sku`
  LEFT JOIN (
    SELECT
      DISTINCT `sku` AS `sku`
    FROM `ww_move`
    WHERE `cancelled`=0
      AND `status` IN ('R','T','F')
  )      AS `m`
         ON `m`.`sku`=`s`.`sku`
  WHERE (
       likeString IS NULL
    OR likeString=''
    OR CONCAT(`s`.`sku`,`s`.`alt_code`,`s`.`description`) LIKE CONCAT('%',TRIM('%' FROM likeString),'%')
    OR CONCAT(`s`.`description`,`s`.`alt_code`,`s`.`sku`) LIKE CONCAT('%',TRIM('%' FROM likeString),'%')
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
      `matches_exactly_on_sku` DESC
     ,`matches_on_sku_left` DESC
     ,`matches_on_alt_code_left` DESC
     ,`matches_on_description_left` DESC
     ,`matches_on_sku` DESC
     ,`matches_on_alt_code` DESC
     ,`matches_on_description` DESC
     ,`matches` DESC
     ,`matches_reverse` DESC
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
DROP PROCEDURE IF EXISTS `wwTask`$$
CREATE PROCEDURE `wwTask`(
  IN `taskId` int(11) unsigned
)
BEGIN
  SELECT
    `tk`.*
   ,`mv`.`quantity`
   ,`mv`.`sku`
   ,`mv`.`status`
   ,`mv`.`order_ref`
   ,`mv`.`booking_id`
  FROM `ww_task` AS `tk`
  JOIN `ww_move` AS `mv`
    ON `mv`.`cancelled`=0
   AND `mv`.`task_id`=`tk`.`id`
   AND `mv`.`to_location`=`tk`.`location`
  WHERE `tk`.`id`=taskId
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwTaskInsert`$$
CREATE PROCEDURE `wwTaskInsert`(
   IN `projectCode` char(64)
  ,IN `teamCode` char(64)
  ,IN `locationCode` char(64)
  ,IN `scheduledDate` date
  ,IN `locationName` varchar(64)
  ,IN `locationPostcode` char(64)
  ,IN `rebooksTaskId` int(11) unsigned
)
BEGIN
  /*
  -- Removed because the locations should exist before the task may be inserted
  INSERT INTO `ww_location`
  SET
    `updated`=NOW()
   ,`location`=locationCode
   ,`name`=locationName
   ,`postcode`=locationPostcode
  ON DUPLICATE KEY UPDATE
    `location`=locationCode
  ;
  */
  INSERT INTO `ww_task`
  SET
    `updated`=NOW()
-- obsolete
--   ,`rebooks_task_id`=rebooksTaskId
   ,`location`=locationCode
   ,`scheduled_date`=scheduledDate
   ,`project`=projectCode
   ,`team`=teamCode
  ON DUPLICATE KEY UPDATE
    `location`=locationCode
   ,`scheduled_date`=scheduledDate
  ;
  IF ROW_COUNT()>0 THEN
    SELECT
      LAST_INSERT_ID() AS `id`
    ;
  ELSE
    SELECT
      `id`
    FROM `ww_task`
    WHERE `location`=locationCode
      AND `scheduled_date`=scheduledDate
    LIMIT 0,1
    ;
  END IF
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwTasks`$$
CREATE PROCEDURE `wwTasks`(
  IN `project` varchar(64) CHARSET ascii
)
BEGIN
  SELECT
    `tk`.*
   ,IF(
      `mv`.`task_id` IS NOT NULL
     ,IF (
        `mv`.`status_max`=0
       ,'P' -- preparing
       ,IF (
          `mv`.`status_min`<2
         ,'R' -- raised
         ,IF (
            `mv`.`status_min`<3
           ,'T' -- transit
           ,'F' -- fulfilled
          )
        )
      )
     ,'N' -- new task
    ) AS `status`
   ,`mv`.`skus`
   ,`lc`.`name` AS `location_name`
   ,`lc`.`territory` AS `location_territory`
   ,`lc`.`postcode` AS `location_postcode`
   ,`lc`.`address_1` AS `location_address_1`
   ,`lc`.`address_2` AS `location_address_2`
   ,`lc`.`address_3` AS `location_address_3`
   ,`lc`.`town` AS `location_town`
   ,`lc`.`region` AS `location_region`
   ,`lc`.`map_url` AS `location_map_url`
   ,`lc`.`notes` AS `location_notes`
  FROM `ww_task` as `tk`
  JOIN `ww_location` AS `lc`
    ON `lc`.`location`=`tk`.`location`
  LEFT JOIN `ww_team` AS `tm`
         ON `tm`.`team`=`tk`.`team`
  LEFT JOIN (
    SELECT
      `task_id`
     ,MIN(1*(`status`='R')+2*(`status`='T')+3*(`status`='F')) AS `status_min`
     ,MAX(1*(`status`='R')+2*(`status`='T')+3*(`status`='F')) AS `status_max`
     ,GROUP_CONCAT(
        CONCAT(`sku`,'::',`quantity`) SEPARATOR ';;'
      ) AS `skus`
    FROM `ww_move`
    WHERE `cancelled`=0
    GROUP BY `task_id`
  ) AS `mv`
         ON `mv`.`task_id`=`tk`.`id`
  WHERE project IS NULL
     OR project=''
     OR `tk`.`project`=project
  ORDER BY
    `tm`.`team` IS NULL DESC -- no team assigned
   ,`tk`.`scheduled_date` IS NULL DESC -- no date scheduled
   ,`status`='N' DESC -- no moves yet
   ,`status`='P' DESC -- moves still need to be raised
   ,`tk`.`scheduled_date` DESC -- recent
   ,`lc`.`location`
  LIMIT 100
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwTeam`$$
CREATE PROCEDURE `wwTeam`(
  IN `teamCode` varchar(64) CHARSET ascii
)
BEGIN
  SELECT
    `tm`.`hidden`
   ,`tm`.`name`
   ,`tk`.`id`
   ,`tk`.`updated`
   ,`tk`.`rebooks_task_id`
   ,`tk`.`location`
   ,`tk`.`scheduled_date`
   ,IF(
      `mv`.`task_id` IS NOT NULL
     ,IF (
        `mv`.`status_max`=0
       ,'P' -- preparing
       ,IF (
          `mv`.`status_min`<2
         ,'R' -- raised
         ,IF (
            `mv`.`status_min`<3
           ,'T' -- transit
           ,'F' -- fulfilled
          )
        )
      )
     ,'N' -- new task
    ) AS `status`
   ,`mv`.`skus`
   ,`lc`.`name` AS `location_name`
   ,`lc`.`territory` AS `location_territory`
   ,`lc`.`postcode` AS `location_postcode`
   ,`lc`.`address_1` AS `location_address_1`
   ,`lc`.`address_2` AS `location_address_2`
   ,`lc`.`address_3` AS `location_address_3`
   ,`lc`.`town` AS `location_town`
   ,`lc`.`region` AS `location_region`
   ,`lc`.`map_url` AS `location_map_url`
   ,`lc`.`notes` AS `location_notes`
  FROM `ww_team` AS `tm`
  JOIN `ww_task` as `tk`
    ON `tm`.`team`=`tk`.`team`
  JOIN `ww_location` AS `lc`
    ON `lc`.`location`=`tk`.`location`
  LEFT JOIN (
    SELECT
      `mvm`.`task_id`
     ,MIN(1*(`mvm`.`status`='R')+2*(`mvm`.`status`='T')+3*(`mvm`.`status`='F')) AS `status_min`
     ,MAX(1*(`mvm`.`status`='R')+2*(`mvm`.`status`='T')+3*(`mvm`.`status`='F')) AS `status_max`
     ,GROUP_CONCAT(
        DISTINCT CONCAT(`mvm`.`sku`,'::',`mvm`.`quantity`,'::',`mvs`.`bin`) SEPARATOR ';;'
      ) AS `skus`
    FROM `ww_move` AS `mvm`
    JOIN `ww_sku` AS `mvs`
      ON `mvs`.`sku`=`mvm`.`sku`
    WHERE `mvm`.`cancelled`=0
    GROUP BY `task_id`
  ) AS `mv`
         ON `mv`.`task_id`=`tk`.`id`
  WHERE `tm`.`team`=teamCode
  ORDER BY
    `tk`.`scheduled_date` DESC
  LIMIT 100
  ;
END$$


DELIMITER $$
DROP PROCEDURE IF EXISTS `wwTeams`$$
CREATE PROCEDURE `wwTeams`(
)
BEGIN
  SELECT
    *
  FROM `ww_team`
  WHERE `team`!=''
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

