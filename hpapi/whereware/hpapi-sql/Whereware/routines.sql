
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
    `i`.`sku_additional_ref`=`s`.`additional_ref`
   ,`i`.`sku_name`=`s`.`name`
  ;
  SELECT
    *
  FROM `ww_recent_inventory`
  WHERE `refreshed`=@stamp
    AND `location`=inventoryLocation
  ORDER BY `sku`,`bin`
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
   ,`s`.`additional_ref`
   ,`s`.`bin`
   ,`s`.`name` AS `sku_name`
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
DROP PROCEDURE IF EXISTS `wwTask`$$
CREATE PROCEDURE `wwTask`(
  IN `taskId` int(11) unsigned
)
BEGIN
  SELECT
    `tk`.*
   ,IFNULL(`tk_nxt`.`rebook_date`,DATE_ADD(CURDATE(),INTERVAL 1 DAY)) AS `rebook_date`
   ,`mv`.`quantity`-IFNULL(`mv_rtn`.`quantity`,0) AS `quantity`
   ,`mv`.`sku`
   ,`mv`.`status`
   ,`mv`.`order_ref`
  FROM `ww_task` AS `tk`
  JOIN `ww_move` AS `mv`
    ON `mv`.`cancelled`=0
   AND `mv`.`task_id`=`tk`.`id`
   AND `mv`.`to_location`=`tk`.`location`
  LEFT JOIN `ww_move` AS `mv_rtn`
         ON `mv_rtn`.`id`!=`mv`.`id` -- this should be the case anyway...
        AND `mv_rtn`.`cancelled`=0
        AND `mv_rtn`.`task_id`=`tk`.`id`
        AND `mv_rtn`.`from_location`=`tk`.`location`
        AND `mv_rtn`.`sku`=`mv`.`sku`
  LEFT JOIN (
    SELECT
      `id`
     ,DATE_SUB(MIN(`scheduled_date`),INTERVAL 1 DAY) AS `rebook_date`
    FROM `ww_task`
    WHERE `id`=taskId
      AND `scheduled_date`>CURDATE()
  )      AS `tk_nxt`
         ON `tk_nxt`.`id`=`tk`.`id`
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
  INSERT INTO `ww_location`
  SET
    `updated`=NOW()
   ,`location`=locationCode
   ,`name`=locationName
   ,`postcode`=locationPostcode
  ON DUPLICATE KEY UPDATE
    `location`=locationCode
  ;
  INSERT INTO `ww_task`
  SET
    `updated`=NOW()
   ,`rebooks_task_id`=rebooksTaskId
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

