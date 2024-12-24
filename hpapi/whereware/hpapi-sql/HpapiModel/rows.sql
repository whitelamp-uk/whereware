
SET NAMES utf8;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;
SET sql_mode = 'NO_AUTO_VALUE_ON_ZERO';


-- BESPOKE PATTERNS

INSERT IGNORE INTO `hpapi_pattern` (`pattern`, `constraints`, `expression`, `input`, `php_filter`, `length_minimum`, `length_maximum`, `value_minimum`, `value_maximum`) VALUES

('varchar-3-64', 'Between 3 and 64 characters',  '^.*$',     'text', '',     3,      64,     '',     '');


-- BESPOKE USER GROUPS

INSERT IGNORE INTO `hpapi_usergroup` (`usergroup`, `level`, `name`, `password_self_manage`, `notes`) VALUES

('wwadmin',	10,	'Whereware admin',	1,	'Whereware administrator'),
('wwstores', 10, 'Whereware admin',  1,  'Whereware stores personnel');


-- SYSTEM USERS

INSERT IGNORE INTO `hpapi_user` (`active`,`verified`,`remote_addr_pattern`,`name`,`notes`,`email`) VALUES

(1,1,'^127\..+$','System user','','system@whereware');

IF(MYSQL_AFFECTED_ROWS()>0) THEN

  INSERT IGNORE INTO `hpapi_membership` (`user_id`,`usergroup`) VALUES

  (LAST_INSERT_ID(),'system');

ENDIF;


-- HPAPI PRIVILEGE TABLES (THINGS YOU CAN DO)

--         Expose vendor-repository/package-directory to the API

INSERT IGNORE INTO `hpapi_package` (`vendor`, `package`, `requires_key`, `notes`) VALUES

('whereware',	'whereware-server',	0,	'Whereware stock control');


--         Expose \NameSpace\ClassName::methodName () to the API

INSERT IGNORE INTO `hpapi_method` (`vendor`, `package`, `class`, `method`, `label`, `notes`) VALUES

('whereware', 'whereware-server', '\\Whereware\\Blueprint', 'blueprint', 'Blueprint', 'Get blueprint definition'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'authenticate',	'Basic current user details',	'Dummy method to authenticate'),
('whereware', 'whereware-server', '\\Whereware\\Whereware', 'binSelect', 'Bin selection algorithm', 'Select a bin based on the algorithm'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'book',	'Create booking',	'Add booking and raise its stock moves'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'components',	'Component SKUs',	'Component SKUs filtered by search terms'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'composites',	'Composite SKUs',	'Composite SKUs filtered by search terms'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'config',	'Config data',	'Gets Swimlanes configuration data for client'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'inventory',	'Recalculate inventory',	'Regenerate data in ww_recent_inventory for the given location'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'move',	'Book moves',	'Insert moves to raise moves from components to composites'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'orders',	'Order list',	'Orders for a given SKU'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'picklist',	'Picklist',	'Picks component options for a composite SKU'),
('whereware', 'whereware-server', '\\Whereware\\Whereware', 'projectInsert',  'Project insert', 'Insert a new project'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'projectUpdate',	'Project update',	'Project SKU data and tasks'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'projects',	'Projects',	'Project list with SKU data'),
('whereware', 'whereware-server', '\\Whereware\\Whereware', 'returns', 'Returns', 'Move and fulfil returned stock to a holding location, raise move back again as new task'),
('whereware', 'whereware-server', '\\Whereware\\Whereware', 'skuUserUpdate', 'Update user SKU', 'Update name of user-space SKU'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'skus',	'SKUs',	'All SKUs filtered by search terms'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'tasks',	'Tasks',	'Tasks assigned to teams (that implement project SKU moves)'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'team',	'Team',	'Team and its tasks'),
('whereware', 'whereware-server', '\\Whereware\\Whereware', 'teams',  'Teams',  'Team list with location data');



--         Define \NameSpace\ClassName::method (arguments)

INSERT IGNORE INTO `hpapi_methodarg` (`vendor`, `package`, `class`, `method`, `argument`, `name`, `empty_allowed`, `pattern`) VALUES

('whereware', 'whereware-server', '\\Whereware\\Blueprint', 'blueprint', 1,  'Composite SKU', 0,  'varchar-64'),
('whereware', 'whereware-server', '\\Whereware\\Whereware', 'binSelect', 1,  'Location code', 0,  'varchar-64'),
('whereware', 'whereware-server', '\\Whereware\\Whereware', 'binSelect', 2,  'Quantity', 0,  'int-11-positive'),
('whereware', 'whereware-server', '\\Whereware\\Whereware', 'binSelect', 3,  'SKU code', 0,  'varchar-64'),
('whereware', 'whereware-server', '\\Whereware\\Whereware', 'binSelect', 4,  'Give diagnostic?', 0,  'db-boolean'),
('whereware', 'whereware-server', '\\Whereware\\Whereware', 'book', 1,  'Booking object', 0,  'object'),
('whereware', 'whereware-server', '\\Whereware\\Whereware', 'components', 1,  'Search terms', 1,  'varchar-64'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'composites',	1,	'Search terms',	1,	'varchar-3-64'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'inventory',	1,	'Location code',	0,	'varchar-3-64'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'move',	1,	'Picklist object',	0,	'object'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'orders',	1,	'Order reference',	0,	'varchar-64'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'picklist',	1,	'SKU',	0,	'varchar-64'),
('whereware', 'whereware-server', '\\Whereware\\Whereware', 'projectInsert',  1,  'Project code', 0,  'varchar-64'),
('whereware', 'whereware-server', '\\Whereware\\Whereware', 'projectInsert',  2,  'Project name', 0,  'varchar-64'),
('whereware', 'whereware-server', '\\Whereware\\Whereware', 'projectInsert',  3,  'Project notes', 1,  'varchar-4096'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'projectUpdate',	1,	'Project object',	0,	'object'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'projects',	1,	'Optional project code',	1,	'varchar-64'),
('whereware', 'whereware-server', '\\Whereware\\Whereware', 'returns', 1,  'Returns object',  0,  'object'),
('whereware', 'whereware-server', '\\Whereware\\Whereware', 'skuUserUpdate',  1,  'SKU code', 0,  'varchar-64'),
('whereware', 'whereware-server', '\\Whereware\\Whereware', 'skuUserUpdate',  2,  'SKU additional ref', 1,  'varchar-64'),
('whereware', 'whereware-server', '\\Whereware\\Whereware', 'skuUserUpdate',  3,  'SKU name', 1,  'varchar-255'),
('whereware', 'whereware-server', '\\Whereware\\Whereware', 'skuUserUpdate',  4,  'SKU notes', 1,  'varchar-4096'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'skus',	1,	'Search terms',	1,	'varchar-3-64'),
('whereware', 'whereware-server', '\\Whereware\\Whereware', 'skus', 2,  'Show components', 1,  'db-boolean'),
('whereware', 'whereware-server', '\\Whereware\\Whereware', 'skus', 3,  'Show composites', 1,  'db-boolean'),
('whereware',	'whereware-server',	'\\Whereware\\Whereware',	'tasks',	1,	'Project code',	1,	'varchar-3-64'),
('whereware', 'whereware-server', '\\Whereware\\Whereware', 'team',  1,  'Team code', 0,  'varchar-3-64');



--         Expose \NameSpace\ClassName::methodName () to user group

INSERT IGNORE INTO `hpapi_run` (`usergroup`, `vendor`, `package`, `class`, `method`) VALUES

('admin', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'binSelect'),
('admin', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'book'),
('admin', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'move'),
('admin', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'projectInsert'),
('admin', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'projectUpdate'),
('admin', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'returns'),
('admin', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'skuUserUpdate'),
('manager', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'binSelect'),
('manager', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'book'),
('manager', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'projectInsert'),
('manager', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'projectUpdate'),
('manager', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'skuUserUpdate'),
('staff', 'whereware',  'whereware-server', '\\Whereware\\Blueprint', 'blueprint'),
('staff', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'authenticate'),
('staff', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'components'),
('staff', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'composites'),
('staff', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'config'),
('staff', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'orders'),
('staff', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'picklist'),
('staff', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'projects'),
('staff', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'skus'),
('staff', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'tasks'),
('staff', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'team'),
('staff', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'teams'),
('system',  'whereware',  'whereware-server', '\\Whereware\\Whereware', 'inventory'),
('wwstores', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'returns');





--    DATA LAYER EXPOSURE

--         Expose DataModel to the API

INSERT IGNORE INTO `hpapi_model` (`model`, `notes`) VALUES

('Whereware',	'Model for Whereware stock control.'),
('HpapiModel', 'Model for the API itself.');


--         Expose DataModel.storedProcedureName to the API

INSERT IGNORE INTO `hpapi_spr` (`model`, `spr`, `notes`) VALUES

('Whereware',	'wwBins',	'Bins'),
('Whereware', 'wwBlueprint', 'For a given composite SKU, list generic/quantities with their variant SKUs'),
('Whereware', 'wwBooking',  'List a booked group of stock moves'),
('Whereware',	'wwBookingCancel',	'Cancel a booked group of stock moves'),
('Whereware',	'wwBookingInsert',	'Insert a unique booking ID for a group of stock moves'),
('Whereware', 'wwBookingRelocate',  'Modify the locations/bins for a given booking'),
('Whereware',	'wwBinsUsed',	'Location/bins that have had stock moves'),
('Whereware',	'wwHide',	'Hide a row of data'),
('Whereware', 'wwInventory',  'Inventory at a given location for SKUs beginning with...'),
('Whereware', 'wwLocationInsertMissing',  'Insert a location if missing'),
('Whereware',	'wwLocations',	'Locations'),
('Whereware', 'wwMoveAssign', 'Update task ID and team for a given move'),
('Whereware',	'wwMoveInsert',	'Insert a new stock move'),
('Whereware', 'wwOrder', 'Confirms a given order reference has been used'),
('Whereware',	'wwOrders',	'List orders for a given SKU'),
('Whereware',	'wwPick',	'Picklist of generics/components for a given composite SKU'),
('Whereware', 'wwProjectInsert',  'Insert a project'),
('Whereware', 'wwProjectSkuInsert',  'Insert SKU for a project, inserting the SKU and its bin where missing'),
('Whereware',	'wwProjects',	'List of projects/associated SKUs'),
('Whereware', 'wwSkuInsertIgnore', 'Insert a new SKU (ignore if exists)'),
('Whereware', 'wwSkuUpdate', 'Update an existing SKU'),
('Whereware',	'wwSkus',	'List SKUs'),
('Whereware',	'wwStatuses',	'Allowed move statuses'),
('Whereware', 'wwTask',  'Task details and list of moves to task location with quantities (less existing return quantities)'),
('Whereware', 'wwTaskInsert',  'Insert task for a project, inserting the location where missing'),
('Whereware',	'wwTasks',	'List of tasks with location/team/status'),
('Whereware', 'wwTeam',  'Team details and its tasks'),
('Whereware',	'wwTeams',	'List of teams/associated locations'),
('Whereware',	'wwUsers',	'Users by user group (optional email match)');


--         Define DataModel.storedProcedureName arguments

INSERT IGNORE INTO `hpapi_sprarg` (`model`, `spr`, `argument`, `name`, `empty_allowed`, `pattern`) VALUES

('Whereware',	'wwBins',	1,	'Bin code starts with',	0,	'varchar-64'),
('Whereware', 'wwBlueprint', 1,  'Composite SKU',  0,  'varchar-64'),
('Whereware', 'wwBooking',  1,  'Booking ID', 0,  'int-11-positive'),
('Whereware',	'wwBookingCancel',	1,	'Booking ID',	0,	'int-11-positive'),
('Whereware', 'wwBookingInsert',  1,  'Booker', 0,  'varchar-255'),
('Whereware', 'wwBookingInsert',  2,  'Project',  0,  'varchar-64'),
('Whereware', 'wwBookingInsert',  3,  'Order ref', 0,  'varchar-64'),
('Whereware', 'wwBookingInsert',  4,  'Type', 0,  'varchar-64'),
('Whereware', 'wwBookingInsert',  5,  'Export?', 0,  'db-boolean'),
('Whereware', 'wwBookingInsert',  6,  'Shipment details',  1,  'varchar-64'),
('Whereware', 'wwBookingInsert',  7,  'Deliver by',  1,  'yyyy-mm-dd'),
('Whereware', 'wwBookingInsert',  8,  'ETA',  1,  'yyyy-mm-dd'),
('Whereware', 'wwBookingInsert',  9,  'Pick scheduled',  1,  'yyyy-mm-dd'),
('Whereware', 'wwBookingInsert',  10,  'Pick by',  1,  'yyyy-mm-dd'),
('Whereware', 'wwBookingInsert',  11,  'Prefer by',  1,  'yyyy-mm-dd'),
('Whereware', 'wwBookingInsert',  12,  'Notes', 1,  'varchar-4096'),
('Whereware', 'wwBookingRelocate',  1,  'Relocater', 0,  'varchar-255'),
('Whereware', 'wwBookingRelocate',  2,  'Booking ID', 0,  'int-11-positive'),
('Whereware', 'wwBookingRelocate',  3,  'From location', 1,  'varchar-64'),
('Whereware', 'wwBookingRelocate',  4,  'From bin', 1,  'varchar-64'),
('Whereware', 'wwBookingRelocate',  5,  'To location', 1,  'varchar-64'),
('Whereware', 'wwBookingRelocate',  6,  'To bin', 1,  'varchar-64'),
('Whereware', 'wwHide',  1,  'Table name',  0,  'varchar-64'),
('Whereware', 'wwHide',  2,  'Column name',  0,  'varchar-64'),
('Whereware', 'wwHide',  3,  'Column value',  0,  'varchar-64'),
('Whereware',	'wwInventory',	1,	'Location code',	0,	'varchar-64'),
('Whereware',	'wwInventory',	2,	'SKU starts with',	1,	'varchar-64'),
('Whereware', 'wwLocationInsertMissing',  1,  'Location code', 0,  'varchar-64'),
('Whereware', 'wwLocationInsertMissing',  2,  'Name', 0,  'varchar-64'),
('Whereware', 'wwLocationInsertMissing',  3,  'Notes', 1,  'varchar-4096'),
('Whereware',	'wwLocations',	1,	'Location code starts with',	0,	'varchar-64'),
('Whereware', 'wwMoveAssign', 1,  'Assigner',  0,  'varchar-64'),
('Whereware', 'wwMoveAssign', 2,  'Move ID',  0,  'int-11-positive'),
('Whereware', 'wwMoveAssign', 3,  'Project code', 1,  'varchar-64'),
('Whereware', 'wwMoveAssign', 4,  'Task ID', 1,  'int-11-positive'),
('Whereware', 'wwMoveAssign', 5,  'Team code', 1,  'varchar-64'),
('Whereware', 'wwMoveInsert', 1,  'Inserter',  0,  'varchar-64'),
('Whereware', 'wwMoveInsert', 2,  'Order reference',  1,  'varchar-64'),
('Whereware',	'wwMoveInsert',	3,	'Booking ID',	0,	'int-11-positive'),
('Whereware',	'wwMoveInsert',	4,	'Status',	0,	'varchar-4'),
('Whereware',	'wwMoveInsert',	5,	'Quantity',	0,	'int-11-positive'),
('Whereware',	'wwMoveInsert',	6,	'SKU',	0,	'varchar-64'),
('Whereware',	'wwMoveInsert',	7,	'From location',	1,	'varchar-64'),
('Whereware',	'wwMoveInsert',	8,	'From bin',	1,	'varchar-64'),
('Whereware',	'wwMoveInsert',	9,	'To location',	1,	'varchar-64'),
('Whereware',	'wwMoveInsert',	10,	'To bin',	1,	'varchar-64'), -- The anywhere bin is an empty string
('Whereware', 'wwOrder', 1,  'Order reference',  0,  'varchar-64'),
('Whereware',	'wwOrders',	1,	'SKU',	0,	'varchar-64'),
('Whereware',	'wwOrders',	2,	'Destination locations start with',	0,	'varchar-64'),
('Whereware',	'wwOrders',	3,	'Results limit',	0,	'int-11-positive'),
('Whereware',	'wwPick',	1,	'Composite SKU',	0,	'varchar-64'),
('Whereware', 'wwProjectInsert',  1,  'Project', 0,  'project-number'),
('Whereware', 'wwProjectInsert',  2,  'Name', 0,  'varchar-64'),
('Whereware', 'wwProjectInsert',  3,  'Notes', 1,  'varchar-4096'),
('Whereware', 'wwProjectSkuInsert',  1,  'Project code', 0,  'varchar-64'),
('Whereware', 'wwProjectSkuInsert',  2,  'SKU', 0,  'varchar-64'),
('Whereware', 'wwProjectSkuInsert',  3,  'Bin code', 1,  'varchar-64'),
('Whereware', 'wwProjectSkuInsert',  4,  'SKU description', 1,  'varchar-255'),
('Whereware', 'wwProjectSkuInsert',  5,  'Is composite', 0,  'db-boolean'),
('Whereware',	'wwProjects',	1,	'Project code (optional)',	1,	'varchar-64'),
('Whereware', 'wwSkuInsertIgnore',  1,  'Sku', 0,  'varchar-64'),
('Whereware', 'wwSkuInsertIgnore',  2,  'Bin', 1,  'varchar-64'),
('Whereware', 'wwSkuInsertIgnore',  3,  'Additional_ref', 1,  'varchar-64'),
('Whereware', 'wwSkuInsertIgnore',  4,  'Unit_price', 0,  'currency-pos'),
('Whereware', 'wwSkuInsertIgnore',  5,  'Name', 1,  'varchar-255'),
('Whereware', 'wwSkuInsertIgnore',  6,  'Notes', 1,  'varchar-4096'),
('Whereware', 'wwSkuUpdate',  1,  'Sku', 0,  'varchar-64'),
('Whereware', 'wwSkuUpdate',  2,  'Default bin', 1,  'varchar-64'),
('Whereware', 'wwSkuUpdate',  3,  'Additional_ref', 1,  'varchar-64'),
('Whereware', 'wwSkuUpdate',  4,  'Unit_price', 0,  'currency-pos'),
('Whereware', 'wwSkuUpdate',  5,  'Name', 1,  'varchar-255'),
('Whereware', 'wwSkuUpdate',  6,  'Notes', 1,  'varchar-4096'),
('Whereware',	'wwSkus',	1,	'SKU like',	0,	'varchar-64'),
('Whereware',	'wwSkus',	2,	'Include components',	0,	'db-boolean'),
('Whereware',	'wwSkus',	3,	'Include composites',	0,	'db-boolean'),
('Whereware',	'wwSkus',	4,	'Results limit',	0,	'int-11-positive'),
('Whereware', 'wwSkus', 5,  'Component inventory location (optional)',  1,  'varchar-64'),
('Whereware', 'wwSkus', 6,  'Composite inventory location (optional)',  1,  'varchar-64'),
('Whereware', 'wwTask',  1,  'Task ID', 0,  'int-11-positive'),
('Whereware', 'wwTaskInsert',  1,  'Project code', 0,  'varchar-64'),
('Whereware', 'wwTaskInsert',  2,  'Team code', 0,  'varchar-64'),
('Whereware', 'wwTaskInsert',  3,  'Location code', 0,  'varchar-64'),
('Whereware', 'wwTaskInsert',  4,  'Scheduled date', 0,  'yyyy-mm-dd'),
('Whereware', 'wwTaskInsert',  5,  'Location name', 1,  'varchar-64'),
('Whereware', 'wwTaskInsert',  6,  'Location postcode', 1,  'varchar-64'),
('Whereware', 'wwTaskInsert',  7,  'Location postcode', 1,  'int-11-positive'),
('Whereware',	'wwTasks',	1,	'Project code',	1,	'varchar-64'),
('Whereware', 'wwTeam',  1,  'Team code', 0,  'varchar-64'),
('Whereware',	'wwUsers',	1,	'Email',	1,	'email');


--         Expose DataModel.storedProcedureName to \NameSpace\ClassName::methodName ()

INSERT IGNORE INTO `hpapi_call` (`model`, `spr`, `vendor`, `package`, `class`, `method`) VALUES

('Whereware', 'wwBlueprint', 'whereware',  'whereware-server', '\\Whereware\\Blueprint', 'blueprint'),
('Whereware', 'wwBooking',  'whereware',  'whereware-server', '\\Whereware\\Whereware', 'projectUpdate'),
('Whereware', 'wwBooking', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'returns'),
('Whereware',	'wwBookingCancel',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'move'),
('Whereware', 'wwBookingInsert',  'whereware',  'whereware-server', '\\Whereware\\Whereware', 'book'),
('Whereware', 'wwBookingInsert',  'whereware',  'whereware-server', '\\Whereware\\Whereware', 'move'),
('Whereware',	'wwBookingInsert',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'projectUpdate'),
('Whereware', 'wwBookingInsert', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'returns'),
('Whereware',	'wwBins',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'config'),
('Whereware', 'wwInventory',  'whereware',  'whereware-server', '\\Whereware\\Blueprint', 'blueprint'),
('Whereware', 'wwInventory', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'binSelect'),
('Whereware', 'wwInventory',  'whereware',  'whereware-server', '\\Whereware\\Whereware', 'book'),
('Whereware',	'wwInventory',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'inventory'),
('Whereware',	'wwInventory',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'picklist'),
('Whereware', 'wwInventory', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'projectUpdate'),
('Whereware', 'wwLocationInsertMissing',  'whereware',  'whereware-server', '\\Whereware\\Whereware', 'book'),
('Whereware',	'wwLocations',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'config'),
('Whereware', 'wwLocations', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'projectUpdate'),
('Whereware', 'wwMoveAssign', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'projectUpdate'),
('Whereware', 'wwMoveAssign', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'returns'),
('Whereware', 'wwMoveInsert',  'whereware',  'whereware-server', '\\Whereware\\Whereware', 'book'),
('Whereware',	'wwMoveInsert',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'move'),
('Whereware', 'wwMoveInsert', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'projectUpdate'),
('Whereware', 'wwMoveInsert', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'returns'),
('Whereware', 'wwOrders', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'orders'),
('Whereware', 'wwProjectInsert', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'projectInsert'),
('Whereware', 'wwProjectSkuInsert', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'projectUpdate'),
('Whereware', 'wwProjects', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'projects'),
('Whereware', 'wwSkuInsertIgnore', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'book'),
('Whereware', 'wwSkuInsertIgnore', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'skus'),
('Whereware', 'wwSkuUpdate', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'skuUserUpdate'),
('Whereware', 'wwSkus', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'binSelect'),
('Whereware', 'wwSkus', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'book'),
('Whereware',	'wwSkus',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'components'),
('Whereware',	'wwSkus',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'composites'),
('Whereware',	'wwSkus',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'move'),
('Whereware', 'wwSkus', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'projectUpdate'),
('Whereware', 'wwSkus', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'skuUserUpdate'),
('Whereware',	'wwSkus',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'skus'),
('Whereware', 'wwStatuses', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'config'),
('Whereware', 'wwTask', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'returns'),
('Whereware', 'wwTaskInsert', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'projectUpdate'),
('Whereware', 'wwTaskInsert', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'returns'),
('Whereware', 'wwTasks', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'projectUpdate'),
('Whereware',	'wwTasks',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'tasks'),
('Whereware', 'wwTeam',  'whereware',  'whereware-server', '\\Whereware\\Whereware', 'team'),
('Whereware',	'wwTeams',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'teams'),
('Whereware',	'wwUsers',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'authenticate'),
('Whereware', 'wwUsers',  'whereware',  'whereware-server', '\\Whereware\\Whereware', 'book'),
('Whereware',	'wwUsers',	'whereware',	'whereware-server',	'\\Whereware\\Whereware',	'config'),
('Whereware', 'wwUsers', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'projectUpdate'),
('Whereware', 'wwUsers', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'returns'),
('Whereware', 'wwUsers', 'whereware',  'whereware-server', '\\Whereware\\Whereware', 'skuUserUpdate'),
('Whereware', 'wwUsers',  'whereware',  'whereware-server', '\\Whereware\\Whereware', 'skus');




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


