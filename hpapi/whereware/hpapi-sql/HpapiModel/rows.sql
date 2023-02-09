
SET NAMES utf8;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;
SET sql_mode = 'NO_AUTO_VALUE_ON_ZERO';


-- BESPOKE PATTERNS
INSERT IGNORE INTO `hpapi_pattern` (`pattern`, `constraints`, `expression`, `input`, `php_filter`, `length_minimum`, `length_maximum`, `value_minimum`, `value_maximum`) VALUES
('varchar-3-64', 'Between 3 and 64 characters',  '^.*$',     'text', '',     3,      64,     '',     '');


-- BESPOKE USER GROUPS

INSERT IGNORE INTO `hpapi_usergroup` (`usergroup`, `level`, `name`, `password_self_manage`, `notes`) VALUES

('wwadmin',	10,	'Whereware admin',	1,	'Whereware administrator.');

-- HPAPI PRIVILEGE TABLES (THINGS YOU CAN DO)

--         Expose vendor-repository/package-directory to the API

INSERT IGNORE INTO `hpapi_package` (`vendor`, `package`, `requires_key`, `notes`) VALUES

('whereware',	'whereware-server',	0,	'Whereware stock control');


--         Expose \NameSpace\ClassName::methodName () to the API

INSERT IGNORE INTO `hpapi_method` (`vendor`, `package`, `class`, `method`, `label`, `notes`) VALUES

('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'authenticate',	'Basic current user details',	'Dummy method to authenticate'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'book',	'Book out stock for assembly/shipping',	'Move quantities of components from bins found to composite bins'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'components',	'Component SKUs',	'Component SKUs filtered by search terms'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'composites',	'Composite SKUs',	'Composite SKUs filtered by search terms'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'config',	'Config data',	'Gets Swimlanes configuration data for client'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'move',	'Book moves',	'Insert moves to raise moves from components to composites'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'orders',	'Order list',	'Orders for a given SKU'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'picklist',	'Picklist',	'Picks component options for a composite SKU'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'projects',	'Projects',	'Project list with SKU data'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'skus',	'SKUs',	'All SKUs filtered by search terms'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'tasks',	'Tasks',	'Tasks assigned to teams (that implement project SKU moves)'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'teams',	'Teams',	'Team list with location data');



--         Define \NameSpace\ClassName::method (arguments)

INSERT IGNORE INTO `hpapi_methodarg` (`vendor`, `package`, `class`, `method`, `argument`, `name`, `empty_allowed`, `pattern`) VALUES

('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'components',	1,	'Search terms',	1,	'varchar-64'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'composites',	1,	'Search terms',	1,	'varchar-3-64'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'move',	1,	'Picklist object',	0,	'object'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'orders',	1,	'Order reference',	0,	'varchar-64'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'picklist',	1,	'SKU',	0,	'varchar-64'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'skus',	1,	'Search terms',	1,	'varchar-3-64'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'tasks',	1,	'Project code',	1,	'varchar-3-64');



--         Expose \NameSpace\ClassName::methodName () to user group

INSERT IGNORE INTO `hpapi_run` (`usergroup`, `vendor`, `package`, `class`, `method`) VALUES

('staff',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'authenticate'),
('staff',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'components'),
('staff',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'composites'),
('staff',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'config'),
('staff',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'move'),
('staff',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'orders'),
('staff',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'picklist'),
('staff',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'projects'),
('staff',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'skus'),
('staff',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'tasks'),
('staff',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'teams');



--    DATA LAYER EXPOSURE

--         Expose DataModel to the API

INSERT IGNORE INTO `hpapi_model` (`model`, `notes`) VALUES

('Whereware',	'Model for Whereware stock control.'),
('HpapiModel', 'Model for the API itself.');


--         Expose DataModel.storedProcedureName to the API

INSERT IGNORE INTO `hpapi_spr` (`model`, `spr`, `notes`) VALUES
('Whereware',	'wwBins',	'Bins'),
('Whereware',	'wwBookingCancel',	'Cancel a booked group of stock moves'),
('Whereware',	'wwBookingInsert',	'Unique booking ID for a group of stock moves'),
('Whereware',	'wwBinsUsed',	'Location/bins that have had stock moves'),
('Whereware',	'wwInventory',	'Inventory at a given location for SKUs beginning with...'),
('Whereware',	'wwLocations',	'Locations'),
('Whereware',	'wwMoveInsert',	'Insert a new stock move'),
('Whereware',	'wwOrders',	'List orders for a given SKU'),
('Whereware',	'wwPick',	'Picklist of generics/components for a given composite SKU'),
('Whereware',	'wwProjects',	'List of projects/associated SKUs'),
('Whereware',	'wwSkus',	'List SKUs'),
('Whereware',	'wwStatuses',	'Allowed move statuses'),
('Whereware',	'wwTasks',	'List of tasks with location/team/status'),
('Whereware',	'wwTeams',	'List of teams/associated locations'),
('Whereware',	'wwUsers',	'Users by user group (optional email match)');


--         Define DataModel.storedProcedureName arguments

INSERT IGNORE INTO `hpapi_sprarg` (`model`, `spr`, `argument`, `name`, `empty_allowed`, `pattern`) VALUES

('Whereware',	'wwBins',	1,	'Bin code starts with',	0,	'varchar-64'),
('Whereware',	'wwBookingCancel',	1,	'Booking ID',	0,	'int-11-positive'),
('Whereware',	'wwInventory',	1,	'Location code',	0,	'varchar-64'),
('Whereware',	'wwInventory',	2,	'SKU start with',	0,	'varchar-64'),
('Whereware',	'wwLocations',	1,	'Location code starts with',	0,	'varchar-64'),
('Whereware',	'wwMoveInsert',	1,	'Order reference',	0,	'varchar-64'),
('Whereware',	'wwMoveInsert',	2,	'Booking ID',	0,	'int-11-positive'),
('Whereware',	'wwMoveInsert',	3,	'Status',	0,	'varchar-4'),
('Whereware',	'wwMoveInsert',	4,	'Quantity',	0,	'int-11-positive'),
('Whereware',	'wwMoveInsert',	5,	'SKU',	0,	'varchar-64'),
('Whereware',	'wwMoveInsert',	6,	'From location',	0,	'varchar-64'),
('Whereware',	'wwMoveInsert',	7,	'From bin',	1,	'varchar-64'),
('Whereware',	'wwMoveInsert',	8,	'To location',	0,	'varchar-64'),
('Whereware',	'wwMoveInsert',	9,	'To bin',	1,	'varchar-64'), -- The anywhere bin is an empty string
('Whereware',	'wwOrders',	1,	'SKU',	0,	'varchar-64'),
('Whereware',	'wwOrders',	2,	'Destination locations start with',	0,	'varchar-64'),
('Whereware',	'wwOrders',	3,	'Results limit',	0,	'int-11-positive'),
('Whereware',	'wwPick',	1,	'Composite SKU',	0,	'varchar-64'),
('Whereware',	'wwSkus',	1,	'SKU like',	0,	'varchar-64'),
('Whereware',	'wwSkus',	2,	'Include components',	0,	'db-boolean'),
('Whereware',	'wwSkus',	3,	'Include composites',	0,	'db-boolean'),
('Whereware',	'wwSkus',	4,	'Results limit',	0,	'int-11-positive'),
('Whereware',	'wwTasks',	1,	'Project code',	1,	'varchar-64'),
('Whereware',	'wwUsers',	1,	'Email',	1,	'email');


--         Expose DataModel.storedProcedureName to \NameSpace\ClassName::methodName ()

INSERT IGNORE INTO `hpapi_call` (`model`, `spr`, `vendor`, `package`, `class`, `method`) VALUES

('HpapiModel',	'hpapiUUIDGenerate',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'book'),
('Whereware',	'wwBookingCancel',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'move'),
('Whereware',	'wwBookingInsert',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'move'),
('Whereware',	'wwBins',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'config'),
('Whereware',	'wwInventory',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'picklist'),
('Whereware',	'wwLocations',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'config'),
('Whereware',	'wwOrders',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'orders'),
('Whereware',	'wwMoveInsert',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'move'),
('Whereware',	'wwPick',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'picklist'),
('Whereware',	'wwStatuses',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'config'),
('Whereware',	'wwSkus',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'components'),
('Whereware',	'wwSkus',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'composites'),
('Whereware',	'wwSkus',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'move'),
('Whereware',	'wwProjects',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'projects'),
('Whereware',	'wwSkus',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'skus'),
('Whereware',	'wwTasks',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'tasks'),
('Whereware',	'wwTeams',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'teams'),
('Whereware',	'wwUsers',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'authenticate'),
('Whereware',	'wwUsers',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'config');




-- HPAPI PERMISSION TABLES (DATA YOU CAN MODIFY DIRECTLY)

--     DATA LAYER EXPOSURE



--         Expose server-side tableName.columnName to the API

INSERT IGNORE INTO `hpapi_column` (`table`, `column`, `model`, `pattern`, `empty_allowed`, `empty_is_null`) VALUES

('ww_blah',	'some_column',	'Whereware',	'varchar-64',	0,	0);



--         Allow user group to insert tuples into a column (inserts deploy SQL_MODE='STRICT_ALL_TABLES')

INSERT IGNORE INTO `hpapi_insert` (`usergroup`, `table`, `column`) VALUES

('wwadmin',	'ww_blah',	'some_column');



--         Allow user group to update tuple in a column (Hpapi inserts enforce SQL_MODE='STRICT_ALL_TABLES')

INSERT IGNORE INTO `hpapi_update` (`usergroup`, `table`, `column`) VALUES

('wwadmin',	'ezp_blah',	'some_column'),
('wwadmin',	'ezp_blah',	'deleted'); -- Gives logical delete/undelete capability; Hpapi does not use SQL DELETE statements


