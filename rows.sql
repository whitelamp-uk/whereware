
INSERT IGNORE INTO `ww_bin` (`updated`, `bin`, `notes`) VALUES
(NOW(),	'',	'Any bin');

INSERT IGNORE INTO `ww_location` (`updated`, `location`, `name`) VALUES
(NOW(),	'',	'Any location of any type'),
(NOW(),	'A-0',	'Any assembly location'),
(NOW(),	'D-0',	'Any destination (eg customer) location'),
(NOW(),	'I-0',	'Any goods-in location'),
(NOW(),	'O-0',	'Any goods-out location'),
(NOW(),	'S-0',	'Any source (eg supplier) location'),
(NOW(),	'W-0',	'Any warehouse location');

INSERT IGNORE INTO `ww_status` (`updated`, `status`, `name`) VALUES
(NOW(),	'P',	'Preparing order'),
(NOW(),	'R',	'Raised (still in the from location/bin)'),
(NOW(),	'T',	'In transit (in between from/to locations/bins'),
(NOW(),	'F',	'Fulfilled (moved into the to location/bin)');

INSERT IGNORE INTO `ww_team` (`updated`, `team`, `name`) VALUES
(NOW(),	'',	'Any team');

