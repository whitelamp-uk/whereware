-- Adminer 4.8.1 MySQL 5.5.62-0+deb8u1 dump

SET NAMES utf8;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;
SET sql_mode = 'NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `ww_bin` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `updated` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `hidden` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `bin` char(64) CHARACTER SET ascii NOT NULL,
  `notes` text CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `bin` (`bin`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `ww_composite` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `updated` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `hidden` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `sku` char(64) CHARACTER SET ascii NOT NULL,
  `from_pick` char(64) CHARACTER SET ascii NOT NULL,
  `to_bin` char(64) CHARACTER SET ascii NOT NULL,
  `notes` text COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sku` (`sku`),
  KEY `from_pick` (`from_pick`),
  KEY `to_bin` (`to_bin`),
  CONSTRAINT `ww_composite_ibfk_1` FOREIGN KEY (`from_pick`) REFERENCES `ww_bin` (`bin`),
  CONSTRAINT `ww_composite_ibfk_2` FOREIGN KEY (`to_bin`) REFERENCES `ww_bin` (`bin`),
  CONSTRAINT `ww_composite_sku` FOREIGN KEY (`sku`) REFERENCES `ww_sku` (`sku`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


CREATE TABLE IF NOT EXISTS `ww_generic` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `updated` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `hidden` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `sku` char(64) CHARACTER SET ascii NOT NULL,
  `generic` char(64) CHARACTER SET ascii NOT NULL,
  `quantity` int(11) unsigned NOT NULL,
  `name` varchar(64) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `notes` text CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sku_generic` (`sku`,`generic`),
  KEY `sku` (`sku`),
  KEY `generic` (`generic`),
  CONSTRAINT `ww_generic_composite` FOREIGN KEY (`sku`) REFERENCES `ww_composite` (`sku`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `ww_recent_inventory` (
  `refreshed` datetime DEFAULT NULL COMMENT 'Last time this row was calculated',
  `sku` char(64) CHARACTER SET ascii NOT NULL,
  `additional_ref` char(64) CHARACTER SET ascii NOT NULL,
  `name` varchar(64) CHARACTER SET utf8 NOT NULL,
  `location` char(64) CHARACTER SET ascii NOT NULL,
  `bin` char(64) CHARACTER SET ascii NOT NULL,
  `hidden` int(1) unsigned NOT NULL DEFAULT 0,
  `updated` datetime DEFAULT NULL COMMENT 'Last time a move took place involving this bin',
  `moved_on` int(11) NOT NULL DEFAULT 0 COMMENT 'Notionally moved out of this "from" bin (even if still there)',
  `fulfilled` int(11) NOT NULL DEFAULT 0 COMMENT 'Physically landed in this "to" bin at some point',
  `in_transit` int(11) NOT NULL DEFAULT 0 COMMENT 'Somewhere between a "from" bin and this "to" bin',
  `raised` int(11) NOT NULL DEFAULT 0 COMMENT 'Still in a "from" bin but raised to this "to" bin',
  `in_bin` int(11) NOT NULL DEFAULT 0 COMMENT 'What you should get if you did a bin count',
  `available` int(11) NOT NULL DEFAULT 0 COMMENT 'Available to be booked out',
  PRIMARY KEY (`sku`,`location`,`bin`),
  KEY `sku` (`sku`),
  KEY `location` (`location`),
  KEY `bin` (`location`,`bin`),
  KEY `refreshed` (`refreshed`),
  KEY `updated` (`updated`),
  KEY `ww_inventory_bin` (`bin`),
  CONSTRAINT `ww_inventory_bin` FOREIGN KEY (`bin`) REFERENCES `ww_bin` (`bin`),
  CONSTRAINT `ww_inventory_location` FOREIGN KEY (`location`) REFERENCES `ww_location` (`location`),
  CONSTRAINT `ww_inventory_sku` FOREIGN KEY (`sku`) REFERENCES `ww_sku` (`sku`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


CREATE TABLE IF NOT EXISTS `ww_location` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `updated` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `hidden` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `location` char(64) CHARACTER SET ascii NOT NULL,
  `name` varchar(64) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `territory` char(64) CHARACTER SET ascii NOT NULL DEFAULT 'GB',
  `postcode` char(64) CHARACTER SET ascii NOT NULL,
  `address_1` char(64) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `address_2` char(64) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `address_3` char(64) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `town` char(64) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `region` char(64) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `notes` text CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `location` (`location`),
  KEY `territory` (`territory`),
  KEY `postcode` (`postcode`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `ww_move` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `hidden` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `cancelled` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `updated` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `updater` char(64) CHARACTER SET ascii NOT NULL,
  `order_ref` char(64) CHARACTER SET ascii NOT NULL,
  `booking_ref` char(64) CHARACTER SET ascii NOT NULL,
  `status` char(64) CHARACTER SET ascii NOT NULL DEFAULT 'R',
  `quantity` int(11) unsigned NOT NULL,
  `sku` char(64) CHARACTER SET ascii NOT NULL,
  `from_location` char(64) CHARACTER SET ascii NOT NULL,
  `from_bin` char(64) CHARACTER SET ascii NOT NULL,
  `to_location` char(64) CHARACTER SET ascii NOT NULL,
  `to_bin` char(64) CHARACTER SET ascii NOT NULL,
  `notes` text COLLATE utf8_unicode_ci NOT NULL,
  `attachment_1` mediumblob DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `sku` (`sku`),
  KEY `from_location` (`from_location`),
  KEY `to_location` (`to_location`),
  KEY `from_bin` (`from_location`,`from_bin`),
  KEY `to_bin` (`to_location`,`to_bin`),
  KEY `status` (`status`),
  KEY `from_bin_2` (`from_bin`),
  KEY `to_bin_2` (`to_bin`),
  CONSTRAINT `ww_move_ibfk_1` FOREIGN KEY (`from_location`) REFERENCES `ww_location` (`location`),
  CONSTRAINT `ww_move_ibfk_2` FOREIGN KEY (`from_bin`) REFERENCES `ww_bin` (`bin`),
  CONSTRAINT `ww_move_ibfk_3` FOREIGN KEY (`to_location`) REFERENCES `ww_location` (`location`),
  CONSTRAINT `ww_move_ibfk_4` FOREIGN KEY (`to_bin`) REFERENCES `ww_bin` (`bin`),
  CONSTRAINT `ww_move_sku` FOREIGN KEY (`sku`) REFERENCES `ww_sku` (`sku`),
  CONSTRAINT `ww_move_status` FOREIGN KEY (`status`) REFERENCES `ww_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


CREATE TABLE IF NOT EXISTS `ww_movelog` (
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `move_id` int(11) unsigned NOT NULL,
  `hidden` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `cancelled` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `updater` char(64) CHARACTER SET ascii NOT NULL,
  `order_ref` char(64) CHARACTER SET ascii NOT NULL,
  `status` char(64) CHARACTER SET ascii NOT NULL DEFAULT 'RAISED',
  `quantity` int(11) unsigned NOT NULL,
  `sku` char(64) CHARACTER SET ascii NOT NULL,
  `from_location` char(64) CHARACTER SET ascii NOT NULL,
  `from_bin` char(64) CHARACTER SET ascii NOT NULL,
  `to_location` char(64) CHARACTER SET ascii NOT NULL,
  `to_bin` char(64) CHARACTER SET ascii NOT NULL,
  PRIMARY KEY (`created`,`move_id`),
  KEY `ww_movelog_move` (`move_id`),
  CONSTRAINT `ww_movelog_move` FOREIGN KEY (`move_id`) REFERENCES `ww_move` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


CREATE TABLE IF NOT EXISTS `ww_sku` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `updated` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `hidden` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `sku` char(64) CHARACTER SET ascii NOT NULL,
  `bin` char(64) CHARACTER SET ascii NOT NULL,
  `additional_ref` char(64) CHARACTER SET ascii NOT NULL,
  `name` varchar(64) COLLATE utf8_unicode_ci NOT NULL,
  `notes` text COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sku` (`sku`),
  KEY `bin` (`bin`),
  CONSTRAINT `ww_sku_ibfk_1` FOREIGN KEY (`bin`) REFERENCES `ww_bin` (`bin`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


CREATE TABLE IF NOT EXISTS `ww_status` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `hidden` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `status` char(64) CHARACTER SET ascii NOT NULL,
  `name` varchar(64) COLLATE utf8_unicode_ci NOT NULL,
  `notes` text COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


CREATE TABLE IF NOT EXISTS `ww_user` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `hidden` int(11) NOT NULL DEFAULT 0,
  `user` char(64) CHARACTER SET ascii NOT NULL,
  `email` char(254) CHARACTER SET ascii NOT NULL COMMENT 'Eventually this will point to the API user',
  `mobile` char(16) CHARACTER SET ascii NOT NULL,
  `notes` text CHARACTER SET ascii NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user` (`user`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


CREATE TABLE IF NOT EXISTS `ww_variant` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `updated` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `hidden` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `generic` char(64) CHARACTER SET ascii NOT NULL,
  `give_preference` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `sku` char(64) CHARACTER SET ascii NOT NULL,
  `notes` text CHARACTER SET ascii NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `generic_sku` (`generic`,`sku`),
  KEY `generic` (`generic`),
  KEY `sku` (`sku`),
  CONSTRAINT `ww_variant_generic` FOREIGN KEY (`generic`) REFERENCES `ww_generic` (`generic`),
  CONSTRAINT `ww_variant_sku` FOREIGN KEY (`sku`) REFERENCES `ww_sku` (`sku`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `ww_web` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `updated` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `hidden` int(1) unsigned NOT NULL DEFAULT 0,
  `user` char(64) NOT NULL,
  `group` char(64) NOT NULL COMMENT 'Eventually this will point to the API user group',
  `location` char(64) NOT NULL,
  `notes` text CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `allow_user_location` (`group`,`user`,`location`),
  KEY `user` (`user`),
  KEY `location` (`location`),
  CONSTRAINT `ww_web_ibfk_1` FOREIGN KEY (`user`) REFERENCES `ww_user` (`user`),
  CONSTRAINT `ww_web_ibfk_2` FOREIGN KEY (`location`) REFERENCES `ww_location` (`location`)
) ENGINE=InnoDB DEFAULT CHARSET=ascii;


-- 2022-03-23 20:19:34
