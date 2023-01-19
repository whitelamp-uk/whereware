
SET NAMES utf8;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;
SET sql_mode = 'NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `ww_bin` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `updated` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  `hidden` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `bin` char(64) CHARACTER SET ascii NOT NULL,
  `notes` text CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `bin` (`bin`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `ww_booking` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `updated` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  `hidden` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `notes` text CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `ww_composite` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `updated` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  `hidden` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `sku` char(64) CHARACTER SET ascii NOT NULL,
  `notes` text COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sku` (`sku`),
  CONSTRAINT `ww_composite_sku` FOREIGN KEY (`sku`) REFERENCES `ww_sku` (`sku`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


CREATE TABLE IF NOT EXISTS `ww_consignment` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `hidden` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `team` char(64) CHARACTER SET ascii NOT NULL,
  `notes` text COLLATE utf8_unicode_ci NOT NULL,
  `attachment_1` mediumblob DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `team` (`team`),
  CONSTRAINT `ww_consignment_team` FOREIGN KEY (`team`) REFERENCES `ww_team` (`team`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


CREATE TABLE IF NOT EXISTS `ww_generic` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `updated` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
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


CREATE TABLE IF NOT EXISTS `ww_location` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `updated` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  `hidden` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `location` char(64) CHARACTER SET ascii NOT NULL,
  `name` varchar(64) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `territory` char(64) CHARACTER SET ascii NOT NULL DEFAULT 'GB',
  `postcode` char(64) CHARACTER SET ascii NOT NULL DEFAULT '',
  `address_1` char(64) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `address_2` char(64) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `address_3` char(64) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `town` char(64) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `region` char(64) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `map_url` varchar(255) CHARACTER SET ascii NOT NULL DEFAULT '',
  `notes` text CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `location` (`location`),
  KEY `territory` (`territory`),
  KEY `postcode` (`postcode`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `ww_move` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `hidden` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `cancelled` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `updated` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  `updater` char(64) CHARACTER SET ascii NOT NULL,
  `project` char(64) CHARACTER SET ascii DEFAULT NULL,
  `order_ref` char(64) CHARACTER SET ascii NOT NULL,
  `booking_id` int(11) unsigned DEFAULT NULL,
  `consignment_id` int(11) unsigned DEFAULT NULL,
  `status` char(1) CHARACTER SET ascii NOT NULL DEFAULT 'R',
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
  KEY `status` (`status`),
  KEY `booking_id` (`booking_id`),
  KEY `consignment_id` (`consignment_id`),
  KEY `from_bin` (`from_bin`),
  KEY `to_bin` (`to_bin`),
  KEY `project` (`project`),
  CONSTRAINT `ww_move_from_location` FOREIGN KEY (`from_location`) REFERENCES `ww_location` (`location`),
  CONSTRAINT `ww_move_from_bin` FOREIGN KEY (`from_bin`) REFERENCES `ww_bin` (`bin`),
  CONSTRAINT `ww_move_to_location` FOREIGN KEY (`to_location`) REFERENCES `ww_location` (`location`),
  CONSTRAINT `ww_move_to_bin` FOREIGN KEY (`to_bin`) REFERENCES `ww_bin` (`bin`),
  CONSTRAINT `ww_move_booking` FOREIGN KEY (`booking_id`) REFERENCES `ww_booking` (`id`),
  CONSTRAINT `ww_move_consignment` FOREIGN KEY (`consignment_id`) REFERENCES `ww_consignment` (`id`),
  CONSTRAINT `ww_move_project` FOREIGN KEY (`project`) REFERENCES `ww_project` (`project`),
  CONSTRAINT `ww_move_sku` FOREIGN KEY (`sku`) REFERENCES `ww_sku` (`sku`),
  CONSTRAINT `ww_move_status` FOREIGN KEY (`status`) REFERENCES `ww_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


CREATE TABLE IF NOT EXISTS `ww_movelog` (
  `created` timestamp NOT NULL DEFAULT current_timestamp(),
  `move_id` int(11) unsigned NOT NULL,
  `hidden` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `cancelled` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `updater` char(64) CHARACTER SET ascii NOT NULL,
  `project` char(64) CHARACTER SET ascii DEFAULT NULL,
  `order_ref` char(64) CHARACTER SET ascii NOT NULL,
  `booking_id` int(11) unsigned DEFAULT NULL,
  `consignment_id` int(11) unsigned DEFAULT NULL,
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


CREATE TABLE IF NOT EXISTS `ww_project` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `updated` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  `hidden` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `project` char(64) CHARACTER SET ascii NOT NULL,
  `name` varchar(64) COLLATE utf8_unicode_ci NOT NULL,
  `notes` text COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sku` (`project`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


CREATE TABLE IF NOT EXISTS `ww_recent_inventory` (
  `refreshed` datetime DEFAULT NULL COMMENT 'Last time this row was calculated',
  `sku` char(64) CHARACTER SET ascii NOT NULL,
  `sku_additional_ref` char(64) CHARACTER SET ascii NOT NULL,
  `sku_name` varchar(64) COLLATE utf8_unicode_ci NOT NULL,
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


CREATE TABLE `ww_refresh` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `updated` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  `hidden` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `sku` char(64) CHARACTER SET ascii NOT NULL,
  `order_ref` char(64) CHARACTER SET ascii NOT NULL,
  `notes` text COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sku` (`sku`),
  CONSTRAINT `ww_refresh_composite` FOREIGN KEY (`sku`) REFERENCES `ww_composite` (`sku`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


CREATE TABLE IF NOT EXISTS `ww_sku` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `updated` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  `hidden` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `sku` char(64) CHARACTER SET ascii NOT NULL,
  `bin` char(64) CHARACTER SET ascii NOT NULL COMMENT 'This field is the current bin but is not a constraint on move from/to bins',
  `additional_ref` char(64) CHARACTER SET ascii NOT NULL,
  `name` varchar(64) COLLATE utf8_unicode_ci NOT NULL,
  `notes` text COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sku` (`sku`),
  KEY `bin` (`bin`),
  CONSTRAINT `ww_sku_bin` FOREIGN KEY (`bin`) REFERENCES `ww_bin` (`bin`)
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


CREATE TABLE IF NOT EXISTS `ww_team` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `updated` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  `hidden` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `team` char(64) CHARACTER SET ascii NOT NULL,
  `name` varchar(64) NOT NULL AFTER `team`,
  `notes` text CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `team` (`team`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `ww_user` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
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
  `updated` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
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
  `updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `hidden` int(1) unsigned NOT NULL DEFAULT 0,
  `user` char(64) NOT NULL,
  `group` char(64) NOT NULL COMMENT 'Eventually this will point to the API user group',
  `location` char(64) NOT NULL,
  `notes` text CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `allow_user_location` (`group`,`user`,`location`),
  KEY `user` (`user`),
  KEY `location` (`location`),
  CONSTRAINT `ww_web_user` FOREIGN KEY (`user`) REFERENCES `ww_user` (`user`),
  CONSTRAINT `ww_web_location` FOREIGN KEY (`location`) REFERENCES `ww_location` (`location`)
) ENGINE=InnoDB DEFAULT CHARSET=ascii;




