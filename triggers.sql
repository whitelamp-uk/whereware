
SET NAMES utf8;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;
SET sql_mode = 'NO_AUTO_VALUE_ON_ZERO';


-- ww_bin

DELIMITER $$
DROP TRIGGER IF EXISTS `wwBinOnBeforeInsert`$$
CREATE TRIGGER `wwBinOnBeforeInsert`
BEFORE INSERT ON `ww_bin` FOR EACH ROW
BEGIN
  SET NEW.`updated` = NOW()
  ;
  SET NEW.`bin` = UPPER(NEW.`bin`)
  ;
END$$

DELIMITER $$
DROP TRIGGER IF EXISTS `wwBinOnBeforeUpdate`$$
CREATE TRIGGER `wwBinOnBeforeUpdate`
BEFORE UPDATE ON `ww_bin` FOR EACH ROW
BEGIN
  SET NEW.`bin` = UPPER(NEW.`bin`)
  ;
END$$


-- ww_composite

DELIMITER $$
DROP TRIGGER IF EXISTS `wwCompositeOnBeforeInsert`$$
CREATE TRIGGER `wwCompositeOnBeforeInsert`
BEFORE INSERT ON `ww_composite` FOR EACH ROW
BEGIN
  SET NEW.`updated` = NOW()
  ;
  SET NEW.`sku` = UPPER(NEW.`sku`)
  ;
END$$

DELIMITER $$
DROP TRIGGER IF EXISTS `wwCompositeOnBeforeUpdate`$$
CREATE TRIGGER `wwCompositeOnBeforeUpdate`
BEFORE UPDATE ON `ww_composite` FOR EACH ROW
BEGIN
  SET NEW.`sku` = UPPER(NEW.`sku`)
  ;
END$$


-- ww_generic

DELIMITER $$
DROP TRIGGER IF EXISTS `wwGenericOnBeforeInsert`$$
CREATE TRIGGER `wwGenericOnBeforeInsert`
BEFORE INSERT ON `ww_generic` FOR EACH ROW
BEGIN
  SET NEW.`updated` = NOW()
  ;
  SET NEW.`sku` = UPPER(NEW.`sku`)
  ;
  SET NEW.`generic` = UPPER(NEW.`generic`)
  ;
END$$

DELIMITER $$
DROP TRIGGER IF EXISTS `wwGenericOnBeforeUpdate`$$
CREATE TRIGGER `wwGenericOnBeforeUpdate`
BEFORE UPDATE ON `ww_generic` FOR EACH ROW
BEGIN
  SET NEW.`sku` = UPPER(NEW.`sku`)
  ;
  SET NEW.`generic` = UPPER(NEW.`generic`)
  ;
END$$


-- ww_location

DELIMITER $$
DROP TRIGGER IF EXISTS `wwLocationOnBeforeInsert`$$
CREATE TRIGGER `wwLocationOnBeforeInsert`
BEFORE INSERT ON `ww_location` FOR EACH ROW
BEGIN
  SET NEW.`updated` = NOW()
  ;
  SET NEW.`location` = UPPER(NEW.`location`)
  ;
  SET NEW.`territory` = UPPER(NEW.`territory`)
  ;
END$$

DELIMITER $$
DROP TRIGGER IF EXISTS `wwLocationOnBeforeUpdate`$$
CREATE TRIGGER `wwLocationOnBeforeUpdate`
BEFORE UPDATE ON `ww_location` FOR EACH ROW
BEGIN
  SET NEW.`location` = UPPER(NEW.`location`)
  ;
  SET NEW.`territory` = UPPER(NEW.`territory`)
  ;
END$$


-- ww_move

DELIMITER $$
DROP TRIGGER IF EXISTS `wwMoveOnBeforeInsert`$$
CREATE TRIGGER `wwMoveOnBeforeInsert`
BEFORE INSERT ON `ww_move` FOR EACH ROW
BEGIN
  DECLARE usr varchar(255)
  ;
  SELECT USER() INTO usr
  ;
  IF (usr!='whereware@localhost') THEN
    SET NEW.`updater` = usr
    ;
  END IF
  ;
  SET NEW.`updated` = NOW()
  ;
  SET NEW.`project` = UPPER(NEW.`project`)
  ;
  SET NEW.`team` = UPPER(NEW.`team`)
  ;
  SET NEW.`order_ref` = UPPER(NEW.`order_ref`)
  ;
  SET NEW.`status` = UPPER(NEW.`status`)
  ;
  SET NEW.`sku` = UPPER(NEW.`sku`)
  ;
  SET NEW.`from_location` = UPPER(NEW.`from_location`)
  ;
  SET NEW.`from_bin` = UPPER(NEW.`from_bin`)
  ;
  SET NEW.`to_location` = UPPER(NEW.`to_location`)
  ;
  SET NEW.`to_bin` = UPPER(NEW.`to_bin`)
  ;
END$$


DELIMITER $$
DROP TRIGGER IF EXISTS `wwMoveOnAfterInsert`$$
CREATE TRIGGER `wwMoveOnAfterInsert`
AFTER INSERT ON `ww_move` FOR EACH ROW
BEGIN
  INSERT INTO `ww_movelog` (
    `move_id`,`created`,
    `hidden`,`cancelled`,`updater`,
    `project`,`team`,`order_ref`,`booking_id`,`task_id`,`consignment_id`,
    `status`,`quantity`,`sku`,
    `from_location`,`from_bin`,
    `to_location`,`to_bin`
  )
  VALUES (
    NEW.`id`,NOW(),
    NEW.`hidden`,NEW.`cancelled`,NEW.`updater`,
    NEW.`project`,NEW.`team`,NEW.`order_ref`,NEW.`booking_id`,NEW.`task_id`,NEW.`consignment_id`,
    NEW.`status`,NEW.`quantity`,NEW.`sku`,
    NEW.`from_location`,NEW.`from_bin`,
    NEW.`to_location`,NEW.`to_bin`
  )
  ;
END$$


DELIMITER $$
DROP TRIGGER IF EXISTS `wwMoveOnBeforeUpdate`$$
CREATE TRIGGER `wwMoveOnBeforeUpdate`
BEFORE UPDATE ON `ww_move` FOR EACH ROW
BEGIN
  DECLARE usr varchar(255);
  IF
    (
         ( NEW.`from_location` LIKE 'W-%' AND NEW.`from_location`!='W-0' AND NEW.`from_bin`='' )
      OR ( NEW.`to_location` LIKE 'W-%' AND NEW.`to_location`!='W-0' AND NEW.`to_bin`='' )
    )
    AND NEW.`status`='F'
  THEN
      SET @msg = 'You cannot fulfil a move involving a warehouse location without specifying the bin'
      ;
      SIGNAL SQLSTATE '45000' SET message_text = @msg
      ;
  END IF
  ;
  SELECT USER() INTO usr
  ;
  IF (usr!='whereware@localhost') THEN
    SET NEW.`updater` = usr
    ;
  END IF
  ;
  SET NEW.`hidden` = IF(NEW.`cancelled`>0,1,NEW.`hidden`)
  ;
  SET NEW.`project` = UPPER(NEW.`project`)
  ;
  SET NEW.`team` = UPPER(NEW.`team`)
  ;
  SET NEW.`order_ref` = UPPER(NEW.`order_ref`)
  ;
  SET NEW.`status` = UPPER(NEW.`status`)
  ;
  SET NEW.`sku` = UPPER(NEW.`sku`)
  ;
  SET NEW.`from_location` = UPPER(NEW.`from_location`)
  ;
  SET NEW.`from_bin` = UPPER(NEW.`from_bin`)
  ;
  SET NEW.`to_location` = UPPER(NEW.`to_location`)
  ;
  SET NEW.`to_bin` = UPPER(NEW.`to_bin`)
  ;
END$$


DELIMITER $$
DROP TRIGGER IF EXISTS `wwMoveOnAfterUpdate`$$
CREATE TRIGGER `wwMoveOnAfterUpdate`
AFTER UPDATE ON `ww_move` FOR EACH ROW
BEGIN
  INSERT INTO `ww_movelog` (
    `move_id`,`created`,
    `hidden`,`cancelled`,`updater`,
    `project`,`team`,`order_ref`,`booking_id`,`task_id`,`consignment_id`,
    `status`,`quantity`,`sku`,
    `from_location`,`from_bin`,
    `to_location`,`to_bin`
  )
  VALUES (
    NEW.`id`,NOW(),
    NEW.`hidden`,NEW.`cancelled`,NEW.`updater`,
    NEW.`project`,NEW.`team`,NEW.`order_ref`,NEW.`booking_id`,NEW.`task_id`,NEW.`consignment_id`,
    NEW.`status`,NEW.`quantity`,NEW.`sku`,
    NEW.`from_location`,NEW.`from_bin`,
    NEW.`to_location`,NEW.`to_bin`
  )
  ;
END$$


DELIMITER $$
DROP TRIGGER IF EXISTS `wwMoveOnBeforeDelete`$$
CREATE TRIGGER `wwMoveOnBeforeDelete`
BEFORE DELETE ON `ww_move` FOR EACH ROW
BEGIN
  -- Bad practice to delete but just in case
  DECLARE usr varchar(255);
  SELECT USER() INTO usr;
  INSERT INTO `ww_movelog` (
    `move_id`,`created`,
    `hidden`,`cancelled`,`updater`,
    `project`,`team`,`order_ref`,`booking_id`,`task_id`,`consignment_id`,
    `status`,`quantity`,`sku`,
    `from_location`,`from_bin`,
    `to_location`,`to_bin`
  )
  VALUES (
    OLD.`id`,NOW(),
    OLD.`hidden`,OLD.`cancelled`,usr,
    OLD.`project`,OLD.`team`,OLD.`order_ref`,OLD.`booking_id`,OLD.`task_id`,OLD.`consignment_id`,
    'DELETED',OLD.`quantity`,OLD.`sku`,
    OLD.`from_location`,OLD.`from_bin`,
    OLD.`to_location`,OLD.`to_bin`
  );
END$$


-- ww_project

DELIMITER $$
DROP TRIGGER IF EXISTS `wwProjectOnBeforeInsert`$$
CREATE TRIGGER `wwProjectOnBeforeInsert`
BEFORE INSERT ON `ww_project` FOR EACH ROW
BEGIN
  SET NEW.`updated` = NOW()
  ;
  SET NEW.`project` = UPPER(NEW.`project`)
  ;
END$$

DELIMITER $$
DROP TRIGGER IF EXISTS `wwProjectOnBeforeUpdate`$$
CREATE TRIGGER `wwProjectOnBeforeUpdate`
BEFORE UPDATE ON `ww_project` FOR EACH ROW
BEGIN
  SET NEW.`project` = UPPER(NEW.`project`)
  ;
END$$


-- ww_task

DELIMITER $$
DROP TRIGGER IF EXISTS `wwTaskOnBeforeInsert`$$
CREATE TRIGGER `wwTaskOnBeforeInsert`
BEFORE INSERT ON `ww_task` FOR EACH ROW
BEGIN
  SET NEW.`updated` = NOW()
  ;
  SET NEW.`team` = UPPER(NEW.`team`)
  ;
  SET NEW.`location` = UPPER(NEW.`location`)
  ;
END$$

DELIMITER $$
DROP TRIGGER IF EXISTS `wwTaskOnBeforeUpdate`$$
CREATE TRIGGER `wwTaskOnBeforeUpdate`
BEFORE UPDATE ON `ww_task` FOR EACH ROW
BEGIN
  SET NEW.`team` = UPPER(NEW.`team`)
  ;
  SET NEW.`location` = UPPER(NEW.`location`)
  ;
END$$


-- ww_project_sku

DELIMITER $$
DROP TRIGGER IF EXISTS `wwProjectSkuOnBeforeInsert`$$
CREATE TRIGGER `wwProjectSkuOnBeforeInsert`
BEFORE INSERT ON `ww_project_sku` FOR EACH ROW
BEGIN
  SET NEW.`updated` = NOW()
  ;
  SET NEW.`project` = UPPER(NEW.`project`)
  ;
  SET NEW.`sku` = UPPER(NEW.`sku`)
  ;
END$$

DELIMITER $$
DROP TRIGGER IF EXISTS `wwProjectSkuOnBeforeUpdate`$$
CREATE TRIGGER `wwProjectSkuOnBeforeUpdate`
BEFORE UPDATE ON `ww_project_sku` FOR EACH ROW
BEGIN
  SET NEW.`project` = UPPER(NEW.`project`)
  ;
  SET NEW.`sku` = UPPER(NEW.`sku`)
  ;
END$$


-- ww_sku

DELIMITER $$
DROP TRIGGER IF EXISTS `wwSkuOnBeforeInsert`$$
CREATE TRIGGER `wwSkuOnBeforeInsert`
BEFORE INSERT ON `ww_sku` FOR EACH ROW
BEGIN
  SET NEW.`updated` = NOW()
  ;
  SET NEW.`sku` = UPPER(NEW.`sku`)
  ;
  SET NEW.`bin` = UPPER(NEW.`bin`)
  ;
  SET NEW.`additional_ref` = UPPER(NEW.`additional_ref`)
  ;
END$$

DELIMITER $$
DROP TRIGGER IF EXISTS `wwSkuOnBeforeUpdate`$$
CREATE TRIGGER `wwSkuOnBeforeUpdate`
BEFORE UPDATE ON `ww_sku` FOR EACH ROW
BEGIN
  SET NEW.`sku` = UPPER(NEW.`sku`)
  ;
  SET NEW.`bin` = UPPER(NEW.`bin`)
  ;
  SET NEW.`additional_ref` = UPPER(NEW.`additional_ref`)
  ;
END$$


-- ww_team

DELIMITER $$
DROP TRIGGER IF EXISTS `wwTeamOnBeforeInsert`$$
CREATE TRIGGER `wwTeamOnBeforeInsert`
BEFORE INSERT ON `ww_team` FOR EACH ROW
BEGIN
  SET NEW.`updated` = NOW()
  ;
  SET NEW.`team` = UPPER(NEW.`team`)
  ;
END$$

DELIMITER $$
DROP TRIGGER IF EXISTS `wwTeamOnBeforeUpdate`$$
CREATE TRIGGER `wwTeamOnBeforeUpdate`
BEFORE UPDATE ON `ww_team` FOR EACH ROW
BEGIN
  SET NEW.`team` = UPPER(NEW.`team`)
  ;
END$$


-- ww_user

DELIMITER $$
DROP TRIGGER IF EXISTS `wwUserOnBeforeInsert`$$
CREATE TRIGGER `wwUserOnBeforeInsert`
BEFORE INSERT ON `ww_user` FOR EACH ROW
BEGIN
  SET NEW.`updated` = NOW()
  ;
  SET NEW.`user` = LOWER(NEW.`user`)
  ;
  SET NEW.`email` = LOWER(NEW.`email`)
  ;
END$$

DELIMITER $$
DROP TRIGGER IF EXISTS `wwUserOnBeforeUpdate`$$
CREATE TRIGGER `wwUserOnBeforeUpdate`
BEFORE UPDATE ON `ww_user` FOR EACH ROW
BEGIN
  SET NEW.`user` = LOWER(NEW.`user`)
  ;
  SET NEW.`email` = LOWER(NEW.`email`)
  ;
END$$


-- ww_variant

DELIMITER $$
DROP TRIGGER IF EXISTS `wwVariantOnBeforeInsert`$$
CREATE TRIGGER `wwVariantOnBeforeInsert`
BEFORE INSERT ON `ww_variant` FOR EACH ROW
BEGIN
  SET NEW.`updated` = NOW()
  ;
  SET NEW.`generic` = UPPER(NEW.`generic`)
  ;
  SET NEW.`sku` = UPPER(NEW.`sku`)
  ;
END$$

DELIMITER $$
DROP TRIGGER IF EXISTS `wwVariantOnBeforeUpdate`$$
CREATE TRIGGER `wwVariantOnBeforeUpdate`
BEFORE UPDATE ON `ww_variant` FOR EACH ROW
BEGIN
  SET NEW.`generic` = UPPER(NEW.`generic`)
  ;
  SET NEW.`sku` = UPPER(NEW.`sku`)
  ;
END$$


-- ww_web

DELIMITER $$
DROP TRIGGER IF EXISTS `wwWebOnBeforeInsert`$$
CREATE TRIGGER `wwWebOnBeforeInsert`
BEFORE INSERT ON `ww_web` FOR EACH ROW
BEGIN
  SET NEW.`updated` = NOW()
  ;
  SET NEW.`location` = UPPER(NEW.`location`)
  ;
  SET NEW.`user` = LOWER(NEW.`user`)
  ;
  SET NEW.`group` = LOWER(NEW.`group`)
  ;
END$$

DELIMITER $$
DROP TRIGGER IF EXISTS `wwWebOnBeforeUpdate`$$
CREATE TRIGGER `wwWebOnBeforeUpdate`
BEFORE UPDATE ON `ww_web` FOR EACH ROW
BEGIN
  SET NEW.`location` = UPPER(NEW.`location`)
  ;
  SET NEW.`user` = LOWER(NEW.`user`)
  ;
  SET NEW.`group` = LOWER(NEW.`group`)
  ;
END$$


